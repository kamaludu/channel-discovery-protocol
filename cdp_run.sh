#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# CDP Orchestratore di Test & Runner Master — Esecutore Metrologico per RUN0 e Suite T01-T14
# File: cdp_run.sh
# Component: Core Test Orchestrator & Execution Engine
# Standard: CDP v2.3 (Sez. 4, 5, 8, 9) & SOP v2.3 (Sez. 1, 2, 3, 4, 5)
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/channel-discovery-protocol/
# Contact: opensource@cevangel.anonaddy.me
# ==============================================================================
# Requirements: bash (>=4.0), coreutils, util-linux, curl, jq, openssl, python (>=3.10 stdlib)
#
# ==============================================================================
# GUIDA ARCHITETTURALE PER SVILUPPATORI (SUT Orchestration & Workflow):
# ==============================================================================
# Questo script coordina il ciclo di vita metrologico completo di ciascun test:
#   [1/6] Acquisizione telemetria host (core/env_telemetry.sh).
#   [2/6] Generazione stimoli OFAT e ground truth SHA-256 (core/ofat_builder.py).
#   [3/6] Esecuzione trial sul SUT adapter (core/sut_adapter.sh -> SUT / bash4llm).
#   [4/6] Calcolo statistico (metrology/cdp_stats.py: Clopper-Pearson o Paired TTFT).
#   [5/6] Decision DAG & classificazione epistemica (metrology/claim_classifier.py).
#   [6/6] Compilazione Scheda Master SOTU v2.3 (reporters/sotu_master.py).
#
# Integra una palette cromatica semantica ANSI sicura (TTY-safe & NO_COLOR compliant).
# Non sono presenti provider, modelli, endpoint o digest SHA-256 cablati:
# ogni parametro viene propagato dinamicamente o rilevato a runtime dal SUT.
# ==============================================================================

set -euo pipefail
umask 077

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# Pre-parsing per intercettare flag --no-color
if [ "$#" -gt 0 ]; then
  for _arg in "$@"; do
    if [ "$_arg" = "--no-color" ]; then
      export NO_COLOR=1
    fi
  done
  unset _arg
fi

# ==============================================================================
# SOTTOSISTEMA COLORI ANSI SEMANTICO & SICURO (NO_COLOR & TTY-Safe)
# ==============================================================================
if [ -t 1 ] && [ "${TERM:-}" != "dumb" ] && [ -z "${NO_COLOR:-}" ]; then
  C_RST=$'\e[0m'
  C_BOLD=$'\e[1m'
  C_DIM=$'\e[2m'
  C_UNDERLINE=$'\e[4m'
  C_INVERT=$'\e[7m'

  # Colori Standard (Normali)
  C_BLACK=$'\e[0;30m'
  C_RED=$'\e[0;31m'
  C_GREEN=$'\e[0;32m'
  C_YELLOW=$'\e[0;33m'
  C_BLUE=$'\e[0;34m'
  C_MAGENTA=$'\e[0;35m'
  C_CYAN=$'\e[0;36m'
  C_WHITE=$'\e[0;37m'

  # Colori Bold / High-Intensity
  C_BBLACK=$'\e[1;30m'  # Dark Gray
  C_BRED=$'\e[1;31m'
  C_BGREEN=$'\e[1;32m'
  C_BYELLOW=$'\e[1;33m'
  C_BBLUE=$'\e[1;34m'
  C_BMAGENTA=$'\e[1;35m'
  C_BCYAN=$'\e[1;36m'
  C_BWHITE=$'\e[1;37m'
else
  C_RST="" C_BOLD="" C_DIM="" C_UNDERLINE="" C_INVERT=""
  C_BLACK="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_MAGENTA="" C_CYAN="" C_WHITE=""
  C_BBLACK="" C_BRED="" C_BGREEN="" C_BYELLOW="" C_BBLUE="" C_BMAGENTA="" C_BCYAN="" C_BWHITE=""
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
WORKSPACE_DIR="$SCRIPT_DIR"

CORE_DIR="$WORKSPACE_DIR/core"
METROLOGY_DIR="$WORKSPACE_DIR/metrology"
REPORTERS_DIR="$WORKSPACE_DIR/reporters"
RUNS_BASE_DIR="$WORKSPACE_DIR/runs"

# Rilevamento binario SUT (bash4llm)
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

# Rilevamento runtime Python stdlib
PYTHON_BIN="python3"
if ! command -v python3 >/dev/null 2>&1 && command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
fi

# Inizializzazione parametri (Nessun default statico forzato)
TEST_ID="RUN0"
REGIME="R1_PILOT"
PROVIDER=""
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

Target e Regime:
  --test <ID>          RUN0, T01..T14, ALL_FOUNDATIONAL, ALL (default: RUN0).
  --regime <REGIME>    pilot (N=5) | confirmatory (N=20). Default: pilot.

Configurazione SUT (Se omesse, delegate alla configurazione attiva di bash4llm):
  --provider <NAME>    Nome del provider target (es. groq, gemini, mistral, openrouter).
  --model <MODEL_ID>   Model ID esplicito per l'esecuzione.
  --endpoint <URL>     Endpoint URL per stima telemetrica baseline RTT.
  --mde <FLOAT>        Minima Differenza Rilevante in ms per T12 (default: 100.0).
  --bash4llm-bin <PATH> Percorso dell'eseguibile SUT (bash4llm).
  --vault-ctx <PASS>   Master passcode per sblocco OpenSSL Vault in bash4llm.

Controlli di Esecuzione:
  --dry-run            Simulazione locale senza traffico HTTP.
  --debug              Preserva le sandbox temporanee per analisi forense.
  --no-color           Disabilita l'emissione dei codici colore ANSI.
  -h, --help           Mostra questa guida ed esce.
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --test)
      [ $# -ge 2 ] || { printf '%scdp_run: ERRORE: --test richiede un ID%s\n' "${C_BRED}" "${C_RST}" >&2; exit 2; }
      TEST_ID="$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')"
      shift 2
      ;;
    --regime)
      [ $# -ge 2 ] || { printf '%scdp_run: ERRORE: --regime richiede un valore%s\n' "${C_BRED}" "${C_RST}" >&2; exit 2; }
      case "$2" in
        pilot|R1|R1_PILOT) REGIME="R1_PILOT"; N_TRIALS=5 ;;
        confirmatory|R2|R2_CONSTRAINED) REGIME="R2_CONSTRAINED"; N_TRIALS=20 ;;
        *) REGIME="R1_PILOT"; N_TRIALS=5 ;;
      esac
      shift 2
      ;;
    --provider)
      [ $# -ge 2 ] || { printf '%scdp_run: ERRORE: --provider richiede un nome%s\n' "${C_BRED}" "${C_RST}" >&2; exit 2; }
      PROVIDER="$2"
      shift 2
      ;;
    --model)
      [ $# -ge 2 ] || { printf '%scdp_run: ERRORE: --model richiede un identificativo%s\n' "${C_BRED}" "${C_RST}" >&2; exit 2; }
      MODEL_ID="$2"
      shift 2
      ;;
    --endpoint)
      [ $# -ge 2 ] || { printf '%scdp_run: ERRORE: --endpoint richiede un URL%s\n' "${C_BRED}" "${C_RST}" >&2; exit 2; }
      ENDPOINT_URL="$2"
      shift 2
      ;;
    --mde)
      [ $# -ge 2 ] || { printf '%scdp_run: ERRORE: --mde richiede un valore numerico%s\n' "${C_BRED}" "${C_RST}" >&2; exit 2; }
      MDE_MS="$2"
      shift 2
      ;;
    --bash4llm-bin)
      [ $# -ge 2 ] || { printf '%scdp_run: ERRORE: --bash4llm-bin richiede un percorso%s\n' "${C_BRED}" "${C_RST}" >&2; exit 2; }
      BASH4LLM_BIN="$2"
      shift 2
      ;;
    --vault-ctx)
      [ $# -ge 2 ] || { printf '%scdp_run: ERRORE: --vault-ctx richiede un passcode%s\n' "${C_BRED}" "${C_RST}" >&2; exit 2; }
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
    --no-color)
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      printf '%scdp_run: ERRORE: Opzione sconosciuta: %s%s\n' "${C_BRED}" "$1" "${C_RST}" >&2
      exit 2
      ;;
  esac
done

# Validazione esistenza eseguibile SUT
if [ -z "$BASH4LLM_BIN" ] || [ ! -f "$BASH4LLM_BIN" ]; then
  printf '%scdp_run: ERRORE CRITICO: Eseguibile SUT non trovato. Specificare --bash4llm-bin <PATH>%s\n' "${C_BRED}" "${C_RST}" >&2
  exit 15
fi

run_single_test_unit() {
  local target_test="$1"
  local ts_now nonce_hex run_id run_dir artifacts_dir
  ts_now="$(date +%Y%m%d_%H%M%S)"
  
  # Generazione CSPRNG deterministica del nonce senza dipendenze binarie esterne
  nonce_hex="$("$PYTHON_BIN" -c 'import secrets; print(secrets.token_hex(3).upper())' 2>/dev/null || printf '%06X' "$RANDOM")"

  run_id="RUN_${ts_now}_${target_test}_${nonce_hex}"
  run_dir="$RUNS_BASE_DIR/$run_id"
  artifacts_dir="$run_dir/raw_artifacts"

  mkdir -p "$artifacts_dir" 2>/dev/null || true
  chmod 700 "$run_dir" "$artifacts_dir" 2>/dev/null || true

  printf '\n%b' "${C_BMAGENTA}========================================${C_RST}
${C_BOLD}TEST UNIT: ${C_BGREEN}${target_test}${C_RST} (${C_CYAN}${REGIME}${C_RST})
${C_BBLACK}Storage  : ${run_id}${C_RST}
${C_BBLACK}----------------------------------------${C_RST}
"

  # ---------------------------------------------------------------------------
  # [1/6] TELEMETRIA HOST & BASELINE RTT
  # ---------------------------------------------------------------------------
  printf 'cdp_run: %s[1/6]%s Acquisizione telemetria host e baseline RTT...\n' "${C_BBLUE}" "${C_RST}"
  local telem_json_file="$run_dir/host_telemetry.json"
  local telem_opts=( --out "$telem_json_file" --quiet )
  [ -n "$ENDPOINT_URL" ] && telem_opts+=( --endpoint "$ENDPOINT_URL" )
  bash "$CORE_DIR/env_telemetry.sh" "${telem_opts[@]}"

  # ---------------------------------------------------------------------------
  # [2/6] GENERAZIONE STIMOLI OFAT & GROUND TRUTH METROLOGICA
  # ---------------------------------------------------------------------------
  printf 'cdp_run: %s[2/6]%s Generazione stimoli canonici via ofat_builder.py...\n' "${C_BMAGENTA}" "${C_RST}"
  local stimulus_meta_file="$run_dir/stimulus_meta.json"
  "$PYTHON_BIN" "$CORE_DIR/ofat_builder.py" --test "$target_test" --out "$stimulus_meta_file"

  # ---------------------------------------------------------------------------
  # [3/6] ESECUZIONE TRIAL SPERIMENTALI SUL SUT ADAPTER
  # ---------------------------------------------------------------------------
  printf 'cdp_run: %s[3/6]%s Esecuzione trial SUT...\n' "${C_BCYAN}" "${C_RST}"
  local -a trial_meta_files=()
  local ttft_pairs_file="$run_dir/ttft_pairs.json"
  local -a latency_pairs_arr=()

  if [ "$target_test" = "RUN0" ]; then
    local trial_art_dir="$artifacts_dir/trial_01"
    mkdir -p "$trial_art_dir"
    local raw_stim run0_expected_sha
    raw_stim="$(jq -r '.target.literal // .expected_canary' "$stimulus_meta_file")"
    run0_expected_sha="$(jq -r '.target.sha256' "$stimulus_meta_file")"

    local adapter_opts=(
      --bash4llm-bin "$BASH4LLM_BIN"
      --artifact-dir "$trial_art_dir"
      --input-text "$raw_stim"
      --intended-sha256 "$run0_expected_sha"
    )
    [ -n "$PROVIDER" ] && adapter_opts+=( --provider "$PROVIDER" )
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

      local t_opts_a=( --bash4llm-bin "$BASH4LLM_BIN" --artifact-dir "$sub_a" --input-text "$stim_a" )
      local t_opts_b=( --bash4llm-bin "$BASH4LLM_BIN" --artifact-dir "$sub_b" --input-text "$stim_b" )
      [ -n "$PROVIDER" ] && { t_opts_a+=( --provider "$PROVIDER" ); t_opts_b+=( --provider "$PROVIDER" ); }
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
            --artifact-dir "$sub_matrix_dir"
            --input-text "$target_prompt"
            --intended-sha256 "$expected_sha"
          )
          [ -n "$PROVIDER" ] && m_opts+=( --provider "$PROVIDER" )
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
          --artifact-dir "$trial_base_dir"
          --input-text "$target_prompt"
        )
        [ -n "$PROVIDER" ] && t_adapter_opts+=( --provider "$PROVIDER" )
        [ -n "$MODEL_ID" ] && t_adapter_opts+=( --model "$MODEL_ID" )
        [ -n "$expected_sha" ] && t_adapter_opts+=( --intended-sha256 "$expected_sha" )
        [ -n "$VAULT_PASS" ] && t_adapter_opts+=( --vault-ctx "$VAULT_PASS" )
        [ "$DRY_RUN_FLAG" -eq 1 ] && t_adapter_opts+=( --dry-run )
        [ "$DEBUG_FLAG" -eq 1 ] && t_adapter_opts+=( --debug )

        printf '  - Trial %s%02d%s/%s%02d%s in corso...\r' "${C_BCYAN}" "$trial_idx" "${C_RST}" "${C_BWHITE}" "$N_TRIALS" "${C_RST}"
        bash "$CORE_DIR/sut_adapter.sh" "${t_adapter_opts[@]}" >/dev/null 2>&1 || true
        trial_meta_files+=( "$trial_base_dir/trial_metadata.json" )
        sleep 0.2 2>/dev/null || true
      fi
    done
    printf '  - Esecuzione completata per %s%d%s cicli di prova.          \n' "${C_BGREEN}" "$N_TRIALS" "${C_RST}"
  fi

  # ---------------------------------------------------------------------------
  # [4/6] CALCOLO STATISTICO (cdp_stats.py)
  # ---------------------------------------------------------------------------
  printf 'cdp_run: %s[4/6]%s Calcolo metriche statistiche (cdp_stats.py)...\n' "${C_BYELLOW}" "${C_RST}"
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
          exp_canary="$(jq -r '.expected_canary // .needle // .target.expected_canary // .target.expected_suffix // empty' "$trial_art_dir_t/stimulus.json" 2>/dev/null || jq -r '.expected_canary // .needle // .target.expected_canary // .target.expected_suffix // empty' "$stimulus_meta_file" 2>/dev/null || true)"

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

  # ---------------------------------------------------------------------------
  # [5/6] DECISION DAG & CLASSIFICAZIONE EPISTEMICA DEI CLAIM
  # ---------------------------------------------------------------------------
  printf 'cdp_run: %s[5/6]%s Esecuzione Decision DAG deterministico...\n' "${C_BMAGENTA}" "${C_RST}"
  local claim_class_file="$run_dir/claim_classification.json"
  "$PYTHON_BIN" "$METROLOGY_DIR/claim_classifier.py" \
    --trials-dir "$artifacts_dir" \
    --stats-json "$metrics_summary_file" \
    --test-id "$target_test" \
    --regime "$REGIME" \
    --out "$claim_class_file"

  # ---------------------------------------------------------------------------
  # [6/6] COMPILAZIONE SCHEDA MASTER SOTU v2.3
  # ---------------------------------------------------------------------------
  printf 'cdp_run: %s[6/6]%s Compilazione Scheda Master SOTU v2.3...\n' "${C_BGREEN}" "${C_RST}"
  local run_manifest_file="$run_dir/run_manifest.json"
  local sotu_report_file="$run_dir/SOTU_MASTER_REPORT.md"

  local sample_dag_file="$run_dir/dag_sample_fallback.json"
  if [ "${#trial_meta_files[@]}" -gt 0 ] && [ -f "${trial_meta_files[0]}" ]; then
    sample_dag_file="${trial_meta_files[0]}"
  else
    printf '{"sut":{"provider":"UNRESOLVED","model_id":"UNRESOLVED"}, "provenance_dag":{}, "audit_trail":{}}\n' > "$sample_dag_file"
  fi

  # Estrazione reale dei metadati SUT osservati dal trial
  local obs_provider obs_model
  obs_provider="$(jq -r '.sut.provider // "UNRESOLVED"' "$sample_dag_file" 2>/dev/null || echo "UNRESOLVED")"
  obs_model="$(jq -r '.sut.model_id // "UNRESOLVED"' "$sample_dag_file" 2>/dev/null || echo "UNRESOLVED")"

  [ "$obs_provider" = "UNRESOLVED" ] && [ -n "$PROVIDER" ] && obs_provider="$PROVIDER"
  [ "$obs_model" = "UNRESOLVED" ] && [ -n "$MODEL_ID" ] && obs_model="$MODEL_ID"

  jq -c -n \
    --arg proto "CDP-v2.3 / SOP-v2.3" \
    --arg ses_id "$run_id" \
    --arg t_id "$target_test" \
    --arg reg "$REGIME" \
    --arg prov "$obs_provider" \
    --arg ep "${ENDPOINT_URL:-NOT_OBSERVED}" \
    --arg mod "$obs_model" \
    --slurpfile telem "$telem_json_file" \
    --slurpfile dag_sample "$sample_dag_file" \
    '{
      protocol_version: $proto,
      session_id: $ses_id,
      test_id: $t_id,
      regime: $reg,
      sut_formal_tuple: {
        provider: $prov,
        endpoint_url: (if $ep == "NOT_OBSERVED" then null else $ep end),
        model_id: $mod,
        declared_runtime: "external-cli-wrapper",
        sampling: {
          temperature: ($dag_sample[0].sut.temperature // null),
          max_tokens: ($dag_sample[0].sut.max_tokens // null),
          stream_mode: false
        }
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

  local final_ev_vector final_ev_status final_id_status final_verdict verdict_color
  final_ev_vector="$(jq -r '.final_evidence_vector // "NOT_OBSERVED"' "$claim_class_file")"
  final_ev_status="$(jq -r '.final_evidence_status // "NOT_OBSERVED"' "$claim_class_file")"
  final_id_status="$(jq -r '.final_identification_status // "NOT_OBSERVED"' "$claim_class_file")"
  final_verdict="$(jq -r '.final_verdict // "NOT_OBSERVED"' "$claim_class_file")"

  case "$final_verdict" in
    *PERFECT*|*CONFORMANT*) verdict_color="${C_BGREEN}" ;;
    *VARIANCE*|*DIVERGENCE*) verdict_color="${C_BYELLOW}" ;;
    *FAILED*|*INVALID*) verdict_color="${C_BRED}" ;;
    *) verdict_color="${C_BCYAN}" ;;
  esac

  printf '\n%b' "${C_BMAGENTA}========================================${C_RST}
${C_BOLD}REFERTO ESECUTIVO SOTU v2.3: ${C_BGREEN}${target_test}${C_RST}
${C_BMAGENTA}========================================${C_RST}
  - Esito Validazione : ${verdict_color}${final_verdict}${C_RST}
  - Evidence Status   : ${C_BOLD}${C_BWHITE}${final_ev_status}${C_RST}
  - Identification    : ${C_BOLD}${C_BWHITE}${final_id_status}${C_RST}
  - Vettore Evidenza  : ${C_BYELLOW}${final_ev_vector}${C_RST}
  - Report Salvato in : ${C_BCYAN}${sotu_report_file}${C_RST}
${C_BMAGENTA}========================================${C_RST}\n\n"
}

printf '%b' "${C_BMAGENTA}========================================${C_RST}
${C_BOLD}CDP/SOP v2.3 METROLOGY HARNESS${C_RST}
SUT Invocator : ${C_BGREEN}$(basename "$BASH4LLM_BIN")${C_RST}
Execution Mode: ${C_BOLD}$([ "$DRY_RUN_FLAG" -eq 1 ] && echo "${C_BYELLOW}DRY-RUN (Simulato)" || echo "${C_BGREEN}LIVE NETWORK")${C_RST}
${C_BMAGENTA}========================================${C_RST}\n"

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
