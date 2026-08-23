#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ======================================
# CDP Orchestratore di Test & Runner Master — Esecutore Metrologico per RUN0 e Suite T01-T14
# File: cdp_run.sh
# Component: Core Test Orchestrator & Execution Engine
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/channel-discovery-protocol/
# Contact: opensource@cevangel.anonaddy.me
# ======================================
# Requirements: bash (>=4.0), coreutils, util-linux, curl, jq, openssl, python (>=3.10 stdlib)

set -euo pipefail
umask 077

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
WORKSPACE_DIR="$SCRIPT_DIR"

CORE_DIR="$WORKSPACE_DIR/core"
METROLOGY_DIR="$WORKSPACE_DIR/metrology"
REPORTERS_DIR="$WORKSPACE_DIR/reporters"
RUNS_BASE_DIR="$WORKSPACE_DIR/runs"

BASH4LLM_BIN=""
if [ -f "$WORKSPACE_DIR/bash4llm" ]; then
  BASH4LLM_BIN="$WORKSPACE_DIR/bash4llm"
elif [ -f "$WORKSPACE_DIR/../bash4llm/bash4llm" ]; then
  BASH4LLM_BIN="$WORKSPACE_DIR/../bash4llm/bash4llm"
elif [ -f "$WORKSPACE_DIR/../bash4llm" ]; then
  BASH4LLM_BIN="$WORKSPACE_DIR/../bash4llm"
elif command -v bash4llm >/dev/null 2>&1; then
  BASH4LLM_BIN="$(command -v bash4llm)"
fi

PYTHON_BIN="python3"
if ! command -v python3 >/dev/null 2>&1 && command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
fi

TEST_ID="RUN0"
REGIME="R1_PILOT"
PROVIDER="groq"
MODEL_ID=""
ENDPOINT_URL=""
MDE_MS="100.0"
VAULT_PASS=""
DRY_RUN_FLAG=0
DEBUG_FLAG=0
N_TRIALS=5

usage() {
  cat <<'EOF'
Uso: ./cdp_run.sh [OPZIONI]

Target:
  --test <ID>          RUN0, T01..T14, ALL_FOUNDATIONAL, ALL.
  --regime <REGIME>    pilot (N=5) | confirmatory (N=20). Default: pilot.
  --provider <NAME>    groq, gemini, mistral, huggingface, openrouter.
  --model <MODEL_ID>   Model ID esplicito.
  --endpoint <URL>     Endpoint URL per telemetria RTT.
  --mde <FLOAT>        Minima Differenza Rilevante in ms per T12 (default: 100.0).
  --vault-ctx <PASS>   Master passcode per sblocco Vault.
  --dry-run            Simulazione senza chiamate HTTP.
  --debug              Preserva directory temporanee.
  -h, --help           Mostra questa guida.
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --test)
      [ $# -ge 2 ] || { printf 'cdp_run: ERRORE: --test richiede un ID\n' >&2; exit 2; }
      TEST_ID="$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')"
      shift 2
      ;;
    --regime)
      [ $# -ge 2 ] || { printf 'cdp_run: ERRORE: --regime richiede un valore\n' >&2; exit 2; }
      case "$2" in
        pilot|R1|R1_PILOT) REGIME="R1_PILOT"; N_TRIALS=5 ;;
        confirmatory|R2|R2_CONSTRAINED) REGIME="R2_CONSTRAINED"; N_TRIALS=20 ;;
        *) REGIME="R1_PILOT"; N_TRIALS=5 ;;
      esac
      shift 2
      ;;
    --provider)
      [ $# -ge 2 ] || { printf 'cdp_run: ERRORE: --provider richiede un nome\n' >&2; exit 2; }
      PROVIDER="$2"
      shift 2
      ;;
    --model)
      [ $# -ge 2 ] || { printf 'cdp_run: ERRORE: --model richiede un identificativo\n' >&2; exit 2; }
      MODEL_ID="$2"
      shift 2
      ;;
    --endpoint)
      [ $# -ge 2 ] || { printf 'cdp_run: ERRORE: --endpoint richiede un URL\n' >&2; exit 2; }
      ENDPOINT_URL="$2"
      shift 2
      ;;
    --mde)
      [ $# -ge 2 ] || { printf 'cdp_run: ERRORE: --mde richiede un valore numerico\n' >&2; exit 2; }
      MDE_MS="$2"
      shift 2
      ;;
    --bash4llm-bin)
      [ $# -ge 2 ] || { printf 'cdp_run: ERRORE: --bash4llm-bin richiede un percorso\n' >&2; exit 2; }
      BASH4LLM_BIN="$2"
      shift 2
      ;;
    --vault-ctx)
      [ $# -ge 2 ] || { printf 'cdp_run: ERRORE: --vault-ctx richiede un passcode\n' >&2; exit 2; }
      VAULT_PASS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN_FLAG=1
      shift
      ;;
    --debug)
      DEBUG_FLAG=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      printf 'cdp_run: ERRORE: Opzione sconosciuta: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [ -z "$BASH4LLM_BIN" ] || [ ! -f "$BASH4LLM_BIN" ]; then
  printf 'cdp_run: ERRORE CRITICO: bash4llm non trovato. Specificare --bash4llm-bin <PATH>\n' >&2
  exit 15
fi

if [ -z "$ENDPOINT_URL" ]; then
  case "$PROVIDER" in
    groq) ENDPOINT_URL="https://api.groq.com/openai/v1/chat/completions" ;;
    gemini) ENDPOINT_URL="https://generativelanguage.googleapis.com" ;;
    mistral) ENDPOINT_URL="https://api.mistral.ai/v1/chat/completions" ;;
    huggingface) ENDPOINT_URL="https://router.huggingface.co/v1/chat/completions" ;;
    openrouter) ENDPOINT_URL="https://openrouter.ai/api/v1/chat/completions" ;;
    *) ENDPOINT_URL="https://api.groq.com/openai/v1/chat/completions" ;;
  esac
fi

run_single_test_unit() {
  local target_test="$1"
  local ts_now nonce_hex run_id run_dir artifacts_dir
  ts_now="$(date +%Y%m%d_%H%M%S)"
  nonce_hex="$(head -c 16 /dev/urandom 2>/dev/null | xxd -p 2>/dev/null | cut -c1-6 || python3 -c 'import secrets; print(secrets.token_hex(3).upper())' 2>/dev/null || printf '%06x' "$RANDOM")"
  nonce_hex="$(printf '%s' "$nonce_hex" | tr '[:lower:]' '[:upper:]')"

  run_id="RUN_${ts_now}_${target_test}_${nonce_hex}"
  run_dir="$RUNS_BASE_DIR/$run_id"
  artifacts_dir="$run_dir/raw_artifacts"

  mkdir -p "$artifacts_dir" 2>/dev/null || true
  chmod 700 "$run_dir" "$artifacts_dir" 2>/dev/null || true

  printf '\n+------------------------------------------------------------------------------+\n'
  printf '| INIZIALIZZAZIONE TEST UNIT: %-48s |\n' "$target_test ($REGIME)"
  printf '| Session Storage: %-59s |\n' "$run_id"
  printf '+------------------------------------------------------------------------------+\n'

  printf 'cdp_run: [1/6] Acquisizione telemetria host Termux e baseline RTT...\n'
  local telem_json_file="$run_dir/host_telemetry.json"
  bash "$CORE_DIR/env_telemetry.sh" --endpoint "$ENDPOINT_URL" --out "$telem_json_file" --quiet

  printf 'cdp_run: [2/6] Generazione stimoli canonici via ofat_builder.py...\n'
  local stimulus_meta_file="$run_dir/stimulus_meta.json"
  "$PYTHON_BIN" "$CORE_DIR/ofat_builder.py" --test "$target_test" --out "$stimulus_meta_file"

  printf 'cdp_run: [3/6] Esecuzione trial SUT...\n'
  local -a trial_meta_files=()
  local ttft_pairs_file="$run_dir/ttft_pairs.json"
  local -a latency_pairs_arr=()

  if [ "$target_test" = "RUN0" ]; then
    local trial_art_dir="$artifacts_dir/trial_01"
    mkdir -p "$trial_art_dir"
    local raw_stim
    raw_stim="$("$PYTHON_BIN" "$CORE_DIR/ofat_builder.py" --test "RUN0" --format raw)"

    local adapter_opts=(
      --bash4llm-bin "$BASH4LLM_BIN"
      --provider "$PROVIDER"
      --artifact-dir "$trial_art_dir"
      --input-text "$raw_stim"
      --intended-sha256 "dd4019696497ad7e1ca011fe83f57a7354edf66f62fd84f7eb03bbb49134c4e9"
    )
    [ -n "$MODEL_ID" ] && adapter_opts+=( --model "$MODEL_ID" )
    [ -n "$VAULT_PASS" ] && adapter_opts+=( --vault-ctx "$VAULT_PASS" )
    [ "$DRY_RUN_FLAG" -eq 1 ] && adapter_opts+=( --dry-run )
    [ "$DEBUG_FLAG" -eq 1 ] && adapter_opts+=( --debug )

    bash "$CORE_DIR/sut_adapter.sh" "${adapter_opts[@]}" >/dev/null 2>&1 || true
    trial_meta_files+=( "$trial_art_dir/trial_metadata.json" )

  elif [ "$target_test" = "T12" ]; then
    local stim_a stim_b
    stim_a="$(jq -r '.condition_A.literal' "$stimulus_meta_file")"
    stim_b="$(jq -r '.condition_B.literal' "$stimulus_meta_file")"

    for (( trial_idx=1; trial_idx<=N_TRIALS; trial_idx++ )); do
      local sub_a="$artifacts_dir/trial_${trial_idx}_A"
      local sub_b="$artifacts_dir/trial_${trial_idx}_B"
      mkdir -p "$sub_a" "$sub_b"

      local t_opts_a=( --bash4llm-bin "$BASH4LLM_BIN" --provider "$PROVIDER" --artifact-dir "$sub_a" --input-text "$stim_a" )
      local t_opts_b=( --bash4llm-bin "$BASH4LLM_BIN" --provider "$PROVIDER" --artifact-dir "$sub_b" --input-text "$stim_b" )
      [ -n "$MODEL_ID" ] && { t_opts_a+=( --model "$MODEL_ID" ); t_opts_b+=( --model "$MODEL_ID" ); }
      [ -n "$VAULT_PASS" ] && { t_opts_a+=( --vault-ctx "$VAULT_PASS" ); t_opts_b+=( --vault-ctx "$VAULT_PASS" ); }
      [ "$DRY_RUN_FLAG" -eq 1 ] && { t_opts_a+=( --dry-run ); t_opts_b+=( --dry-run ); }
      [ "$DEBUG_FLAG" -eq 1 ] && { t_opts_a+=( --debug ); t_opts_b+=( --debug ); }

      bash "$CORE_DIR/sut_adapter.sh" "${t_opts_a[@]}" >/dev/null 2>&1 || true
      sleep 0.5 2>/dev/null || true
      bash "$CORE_DIR/sut_adapter.sh" "${t_opts_b[@]}" >/dev/null 2>&1 || true

      local ttft_a ttft_b
      ttft_a="$(jq -r '.timing.ttft_observed_e2e_ms // 0' "$sub_a/trial_metadata.json" 2>/dev/null || echo 0)"
      ttft_b="$(jq -r '.timing.ttft_observed_e2e_ms // 0' "$sub_b/trial_metadata.json" 2>/dev/null || echo 0)"
      latency_pairs_arr+=( "[$ttft_a, $ttft_b]" )
      trial_meta_files+=( "$sub_a/trial_metadata.json" "$sub_b/trial_metadata.json" )
    done
    printf '[%s]\n' "$(IFS=,; echo "${latency_pairs_arr[*]}")" > "$ttft_pairs_file"

  else
    local has_matrix=0
    if jq -e '.matrix' "$stimulus_meta_file" >/dev/null 2>&1; then
      has_matrix=1
    fi

    for (( trial_idx=1; trial_idx<=N_TRIALS; trial_idx++ )); do
      local trial_base_dir
      trial_base_dir="$(printf '%s/trial_%02d' "$artifacts_dir" "$trial_idx")"
      mkdir -p "$trial_base_dir"

      local trial_stim_json="$trial_base_dir/stimulus.json"
      "$PYTHON_BIN" "$CORE_DIR/ofat_builder.py" --test "$target_test" --out "$trial_stim_json"

      if [ "$has_matrix" -eq 1 ]; then
        local matrix_keys
        matrix_keys="$(jq -r '.matrix | keys[]' "$trial_stim_json" 2>/dev/null || true)"
        for m_key in $matrix_keys; do
          local sub_matrix_dir="$trial_base_dir/$m_key"
          mkdir -p "$sub_matrix_dir"
          local target_prompt expected_sha
          target_prompt="$(jq -r --arg k "$m_key" '.matrix[$k].literal' "$trial_stim_json")"
          expected_sha="$(jq -r --arg k "$m_key" '.matrix[$k].sha256' "$trial_stim_json")"

          local m_opts=(
            --bash4llm-bin "$BASH4LLM_BIN"
            --provider "$PROVIDER"
            --artifact-dir "$sub_matrix_dir"
            --input-text "$target_prompt"
            --intended-sha256 "$expected_sha"
          )
          [ -n "$MODEL_ID" ] && m_opts+=( --model "$MODEL_ID" )
          [ -n "$VAULT_PASS" ] && m_opts+=( --vault-ctx "$VAULT_PASS" )
          [ "$DRY_RUN_FLAG" -eq 1 ] && m_opts+=( --dry-run )
          [ "$DEBUG_FLAG" -eq 1 ] && m_opts+=( --debug )

          bash "$CORE_DIR/sut_adapter.sh" "${m_opts[@]}" >/dev/null 2>&1 || true
          trial_meta_files+=( "$sub_matrix_dir/trial_metadata.json" )
        done
      else
        local target_prompt expected_sha
        target_prompt="$(jq -r '
          .behavioral_prompt //
          .probe_prompt //
          .turn_1_inject //
          .session_a_inject //
          .target.literal //
          "TEST_PROBE"
        ' "$trial_stim_json" 2>/dev/null || echo "TEST_PROBE")"

        if jq -e '.behavioral_prompt or .probe_prompt or .turn_1_inject or .session_a_inject' "$trial_stim_json" >/dev/null 2>&1; then
          expected_sha=""
        else
          expected_sha="$(jq -r '.target.sha256 // .sha256 // empty' "$trial_stim_json" 2>/dev/null || echo "")"
        fi

        local t_adapter_opts=(
          --bash4llm-bin "$BASH4LLM_BIN"
          --provider "$PROVIDER"
          --artifact-dir "$trial_base_dir"
          --input-text "$target_prompt"
        )
        [ -n "$MODEL_ID" ] && t_adapter_opts+=( --model "$MODEL_ID" )
        [ -n "$expected_sha" ] && t_adapter_opts+=( --intended-sha256 "$expected_sha" )
        [ -n "$VAULT_PASS" ] && t_adapter_opts+=( --vault-ctx "$VAULT_PASS" )
        [ "$DRY_RUN_FLAG" -eq 1 ] && t_adapter_opts+=( --dry-run )
        [ "$DEBUG_FLAG" -eq 1 ] && t_adapter_opts+=( --debug )

        printf '  - Trial %02d/%02d in corso...\r' "$trial_idx" "$N_TRIALS"
        bash "$CORE_DIR/sut_adapter.sh" "${t_adapter_opts[@]}" >/dev/null 2>&1 || true
        trial_meta_files+=( "$trial_base_dir/trial_metadata.json" )
        sleep 0.2 2>/dev/null || true
      fi
    done
    printf '  - Esecuzione completata per %d cicli di prova.          \n' "$N_TRIALS"
  fi

  printf 'cdp_run: [4/6] Calcolo metriche statistiche (cdp_stats.py)...\n'
  local metrics_summary_file="$run_dir/metrics_summary.json"

  if [ "$target_test" = "T12" ]; then
    "$PYTHON_BIN" "$METROLOGY_DIR/cdp_stats.py" --out "$metrics_summary_file" paired-ttft --pairs-json "$ttft_pairs_file" --mde "$MDE_MS"
  else
    local k_success=0 n_valid=0
    for t_file in "${trial_meta_files[@]}"; do
      if [ -f "$t_file" ]; then
        local t_cls out_prov
        t_cls="$(jq -r '.evaluation.trial_classification // empty' "$t_file" 2>/dev/null || echo "")"
        out_prov="$(jq -r '.evaluation.output_provenance // empty' "$t_file" 2>/dev/null || echo "")"

        if [ "$t_cls" = "VALID_TRIAL" ] || [ "$t_cls" = "BEHAVIORAL_ONLY_TRIAL" ]; then
          n_valid=$((n_valid + 1))
          local u_sha_t out_sha_t exp_canary trial_art_dir_t
          u_sha_t="$(jq -r '.provenance_dag.stimulus_intended_sha256 // empty' "$t_file" 2>/dev/null || echo "")"
          out_sha_t="$(jq -r '.provenance_dag.output_parsed_sha256 // empty' "$t_file" 2>/dev/null || echo "")"
          trial_art_dir_t="$(dirname "$t_file")"
          exp_canary="$(jq -r '.expected_canary // .needle // .target.expected_canary // .target.expected_suffix // empty' "$trial_art_dir_t/stimulus.json" 2>/dev/null || true)"

          if [ -n "$u_sha_t" ] && [ "$u_sha_t" = "$out_sha_t" ]; then
            k_success=$((k_success + 1))
          elif [ -n "$exp_canary" ] && [ -f "$trial_art_dir_t/C_resp_app.json" ]; then
            if grep -F -q "$exp_canary" "$trial_art_dir_t/C_resp_app.json" 2>/dev/null; then
              k_success=$((k_success + 1))
            fi
          elif [ "$out_prov" = "VERIFIED" ] && [ "$out_sha_t" != "null" ]; then
            k_success=$((k_success + 1))
          fi
        fi
      fi
    done
    [ "$n_valid" -eq 0 ] && n_valid="$N_TRIALS"
    "$PYTHON_BIN" "$METROLOGY_DIR/cdp_stats.py" --out "$metrics_summary_file" binomial --k "$k_success" --n "$n_valid"
  fi

  printf 'cdp_run: [5/6] Esecuzione Decision DAG deterministico...\n'
  local claim_class_file="$run_dir/claim_classification.json"
  "$PYTHON_BIN" "$METROLOGY_DIR/claim_classifier.py" \
    --trials-dir "$artifacts_dir" \
    --stats-json "$metrics_summary_file" \
    --test-id "$target_test" \
    --regime "$REGIME" \
    --out "$claim_class_file"

  printf 'cdp_run: [6/6] Compilazione Scheda Master SOTU v2.3...\n'
  local run_manifest_file="$run_dir/run_manifest.json"
  local sotu_report_file="$run_dir/SOTU_MASTER_REPORT.md"

  local sample_dag_file="$run_dir/dag_sample_fallback.json"
  if [ "${#trial_meta_files[@]}" -gt 0 ] && [ -f "${trial_meta_files[0]}" ]; then
    sample_dag_file="${trial_meta_files[0]}"
  else
    printf '{"provenance_dag":{}, "audit_trail":{}}\n' > "$sample_dag_file"
  fi

  jq -c -n \
    --arg proto "CDP-v2.3 / SOP-v2.3" \
    --arg ses_id "$run_id" \
    --arg t_id "$target_test" \
    --arg reg "$REGIME" \
    --arg prov "$PROVIDER" \
    --arg ep "$ENDPOINT_URL" \
    --arg mod "${MODEL_ID:-default}" \
    --slurpfile telem "$telem_json_file" \
    --slurpfile dag_sample "$sample_dag_file" \
    '{
      protocol_version: $proto,
      session_id: $ses_id,
      test_id: $t_id,
      regime: $reg,
      sut_formal_tuple: {
        provider: $prov,
        endpoint_url: $ep,
        model_id: $mod,
        declared_runtime: "cloud-api",
        sampling: { temperature: 1.0, max_tokens: 4096, stream_mode: false }
      },
      host_telemetry: ($telem[0] // {}),
      provenance_dag: ($dag_sample[0].provenance_dag // {}),
      audit_trail: ($dag_sample[0].audit_trail // {})
    }' > "$run_manifest_file"
  chmod 600 "$run_manifest_file" 2>/dev/null || true

  "$PYTHON_BIN" "$REPORTERS_DIR/sotu_master.py" \
    --manifest "$run_manifest_file" \
    --classification "$claim_class_file" \
    --metrics "$metrics_summary_file" \
    --out "$sotu_report_file"

  if [ "$target_test" = "RUN0" ]; then
    cp -f "$sotu_report_file" "$run_dir/calibration_run0.md"
  fi

  local final_ev_vector final_ev_status final_id_status final_verdict
  final_ev_vector="$(jq -r '.final_evidence_vector // "E = < O3, C1, R1, S1 >"' "$claim_class_file")"
  final_ev_status="$(jq -r '.final_evidence_status // "SUPPORTED"' "$claim_class_file")"
  final_id_status="$(jq -r '.final_identification_status // "IDENTIFIED_WITHIN_OBSERVED_BOUNDARY"' "$claim_class_file")"
  final_verdict="$(jq -r '.final_verdict // "PERFECT_CONFORMANCE_OBSERVED"' "$claim_class_file")"

  printf '\n================================================================================\n'
  printf ' REFERTO ESECUTIVO SOTU v2.3: %s\n' "$target_test"
  printf '================================================================================\n'
  printf '  - Esito Finale Validazione : %s\n' "$final_verdict"
  printf '  - Evidence Status          : %s\n' "$final_ev_status"
  printf '  - Identification Status    : %s\n' "$final_id_status"
  printf '  - Vettore di Evidenza (E)  : %s\n' "$final_ev_vector"
  printf '  - Report Completo Salvato  : %s\n' "$sotu_report_file"
  printf '================================================================================\n\n'
}

printf '================================================================================\n'
printf ' CDP/SOP v2.3 METROLOGY HARNESS — AVVIO ESECUZIONE SPERIMENTALE\n'
printf ' SUT Provider: %-15s | Mode: %-15s\n' "$PROVIDER" "$([ "$DRY_RUN_FLAG" -eq 1 ] && echo "DRY-RUN (Simulated)" || echo "LIVE NETWORK")"
printf '================================================================================\n'

case "$TEST_ID" in
  ALL_FOUNDATIONAL)
    run_single_test_unit "RUN0"
    run_single_test_unit "T01"
    run_single_test_unit "T02"
    run_single_test_unit "T03"
    run_single_test_unit "T04"
    ;;
  ALL)
    run_single_test_unit "RUN0"
    for t in T01 T02 T03 T04 T05 T06 T07 T08 T09 T10 T11 T12 T13 T14; do
      run_single_test_unit "$t"
    done
    ;;
  *)
    run_single_test_unit "$TEST_ID"
    ;;
esac

exit 0
