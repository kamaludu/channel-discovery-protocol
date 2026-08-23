#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ======================================
# CDP/SOP v2.3 METROLOGY HARNESS
# File: core/sut_adapter.sh
# Component: Wrapper SUT per bash4llm (v2.8.5.3)
# Standard: CDP v2.3 (Sez. 1, 4, 5) & SOP v2.3 (Sez. 1.3, 2.2, 3.1, 4.1)
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/channel-discovery-protocol/
# Contact: opensource@cevangel.anonaddy.me
# ======================================

set -euo pipefail
umask 077

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

BASH4LLM_BIN=""
PROVIDER="groq"
MODEL_ID=""
TEMPERATURE="1.0"
MAX_TOKENS="4096"
SYSTEM_PROMPT=""
RAW_INPUT_TEXT=""
RAW_INPUT_FILE=""
JSON_INPUT_STR=""
INTENDED_SHA256_EXPECTED=""
ARTIFACT_DIR=""
VAULT_SESSION_PASS=""
DRY_RUN_MODE=0
DEBUG_MODE=0

usage() {
  cat <<'EOF'
Uso: sut_adapter.sh [OPZIONI]

Opzioni Obbligatorie:
  --bash4llm-bin <PATH>   Percorso dell'eseguibile bash4llm.
  --artifact-dir <DIR>    Directory di destinazione per la raccolta degli artefatti grezzi.

Configurazione SUT:
  --provider <NAME>       Provider target (groq, gemini, mistral, huggingface, openrouter).
  --model <MODEL_ID>      Identificativo univoco del modello.
  --temperature <FLOAT>   Parametro di temperatura (default: 1.0).
  --max-tokens <INT>      Limite massimo di token emessi (default: 4096).
  --system-prompt <STR>   System prompt facoltativo.

Stimolo di Input:
  --input-text <STR>      Stringa scalare UTF-8 grezza (U_intended).
  --input-file <PATH>     File contenente lo stimolo di input grezzo.
  --json-input <JSON>     Payload JSON strutturato per chiamate avanzate.
  --intended-sha256 <HEX> Digest SHA-256 precalcolato per verifica di integrita'.

Sicurezza e Ambiente:
  --vault-ctx <PASS>      Passcode master o token runtime per l'OpenSSL Vault.
  --dry-run               Simula l'invocazione senza eseguire traffico HTTP reale.
  --debug                 Preserva la sandbox temporanea per analisi forense.
  -h, --help              Mostra questa guida ed esce.
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --bash4llm-bin)
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --bash4llm-bin richiede un percorso\n' >&2; exit 2; }
      BASH4LLM_BIN="$2"
      shift 2
      ;;
    --artifact-dir)
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --artifact-dir richiede una directory\n' >&2; exit 2; }
      ARTIFACT_DIR="$2"
      shift 2
      ;;
    --provider)
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --provider richiede un identificativo\n' >&2; exit 2; }
      PROVIDER="$2"
      shift 2
      ;;
    --model)
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --model richiede un Model ID\n' >&2; exit 2; }
      MODEL_ID="$2"
      shift 2
      ;;
    --temperature)
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --temperature richiede un valore numerico\n' >&2; exit 2; }
      TEMPERATURE="$2"
      shift 2
      ;;
    --max-tokens)
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --max-tokens richiede un intero\n' >&2; exit 2; }
      MAX_TOKENS="$2"
      shift 2
      ;;
    --system-prompt)
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --system-prompt richiede una stringa\n' >&2; exit 2; }
      SYSTEM_PROMPT="$2"
      shift 2
      ;;
    --input-text)
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --input-text richiede una stringa\n' >&2; exit 2; }
      RAW_INPUT_TEXT="$2"
      shift 2
      ;;
    --input-file)
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --input-file richiede un percorso\n' >&2; exit 2; }
      RAW_INPUT_FILE="$2"
      shift 2
      ;;
    --json-input)
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --json-input richiede una stringa JSON\n' >&2; exit 2; }
      JSON_INPUT_STR="$2"
      shift 2
      ;;
    --intended-sha256)
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --intended-sha256 richiede un hash hex a 64 caratteri\n' >&2; exit 2; }
      INTENDED_SHA256_EXPECTED="$2"
      shift 2
      ;;
    --vault-ctx)
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --vault-ctx richiede un passcode\n' >&2; exit 2; }
      VAULT_SESSION_PASS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN_MODE=1
      shift
      ;;
    --debug)
      DEBUG_MODE=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      printf 'sut_adapter: ERRORE: Opzione sconosciuta: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

if [ -z "$BASH4LLM_BIN" ] || [ ! -f "$BASH4LLM_BIN" ]; then
  printf 'sut_adapter: ERRORE: Eseguibile bash4llm non trovato (%s)\n' "${BASH4LLM_BIN:-<vuoto>}" >&2
  exit 15
fi

if [ -z "$ARTIFACT_DIR" ]; then
  printf 'sut_adapter: ERRORE: --artifact-dir e obbligatorio\n' >&2
  exit 15
fi

mkdir -p "$ARTIFACT_DIR" 2>/dev/null || true
chmod 700 "$ARTIFACT_DIR" 2>/dev/null || true

BASE_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
[ -d "$BASE_TMP" ] || BASE_TMP="/tmp"

SANDBOX_DIR="$(mktemp -d "${BASE_TMP%/}/cdp_sut_XXXXXX" 2>/dev/null || mktemp -d "/tmp/cdp_sut_XXXXXX")"
chmod 700 "$SANDBOX_DIR" 2>/dev/null || true

cleanup_sandbox() {
  local rc_exit=$?
  if [ "$DEBUG_MODE" -eq 1 ]; then
    printf 'sut_adapter: [DEBUG] Sandbox preservata: %s\n' "$SANDBOX_DIR" >&2
  else
    rm -rf -- "$SANDBOX_DIR" 2>/dev/null || true
  fi
  exit "$rc_exit"
}
trap cleanup_sandbox EXIT INT TERM

STIMULUS_FILE="$SANDBOX_DIR/u_intended.bin"

if [ -n "$RAW_INPUT_FILE" ] && [ -f "$RAW_INPUT_FILE" ]; then
  cp -f "$RAW_INPUT_FILE" "$STIMULUS_FILE"
elif [ -n "$RAW_INPUT_TEXT" ]; then
  printf '%s' "$RAW_INPUT_TEXT" > "$STIMULUS_FILE"
elif [ -n "$JSON_INPUT_STR" ]; then
  printf '%s' "$JSON_INPUT_STR" > "$STIMULUS_FILE"
else
  if [ ! -t 0 ]; then
    cat - > "$STIMULUS_FILE"
  else
    printf 'sut_adapter: ERRORE: Nessuno stimolo fornito\n' >&2
    exit 14
  fi
fi
chmod 600 "$STIMULUS_FILE" 2>/dev/null || true

STIMULUS_INTENDED_SHA256="$(openssl dgst -sha256 -r "$STIMULUS_FILE" 2>/dev/null | awk '{print $1}' || sha256sum "$STIMULUS_FILE" | awk '{print $1}')"
U_BUFFER_BYTES_SHA256="$STIMULUS_INTENDED_SHA256"

if [ -n "$INTENDED_SHA256_EXPECTED" ] && [ "$STIMULUS_INTENDED_SHA256" != "$INTENDED_SHA256_EXPECTED" ]; then
  printf 'sut_adapter: ERRORE CRITICO [INVALID-STIMULUS]: Disallineamento hash pre-invio!\n' >&2
  INVALID_JSON="$(jq -c -n \
    --arg expected "$INTENDED_SHA256_EXPECTED" \
    --arg actual "$STIMULUS_INTENDED_SHA256" \
    '{
      trial_classification: "INVALID_STIMULUS",
      error: "Stimulus hash mismatch pre-submit",
      expected_sha256: $expected,
      actual_sha256: $actual,
      evaluation: {
        output_provenance: "UNKNOWN",
        trial_classification: "INVALID_STIMULUS"
      }
    }')"
  printf '%s\n' "$INVALID_JSON" > "$ARTIFACT_DIR/trial_metadata.json"
  exit 15
fi

B4L_TMPDIR="$SANDBOX_DIR/b4l_tmp"
mkdir -p "$B4L_TMPDIR" 2>/dev/null || true
chmod 700 "$B4L_TMPDIR" 2>/dev/null || true

export BASH4LLM_TMPDIR="$B4L_TMPDIR"
export DEBUG_PRESERVE=1
export NO_COLOR=1

if [ -n "$VAULT_SESSION_PASS" ]; then
  export _B4L_RT_CTX="$VAULT_SESSION_PASS"
fi

B4L_CMD=( bash "$BASH4LLM_BIN" --no-stream --json --nosave )
[ -n "$PROVIDER" ] && B4L_CMD+=( --provider "$PROVIDER" )
[ -n "$MODEL_ID" ] && B4L_CMD+=( --model "$MODEL_ID" )
[ -n "$TEMPERATURE" ] && B4L_CMD+=( --temperature "$TEMPERATURE" )
[ -n "$MAX_TOKENS" ] && B4L_CMD+=( --max "$MAX_TOKENS" )
[ -n "$SYSTEM_PROMPT" ] && B4L_CMD+=( --system "$SYSTEM_PROMPT" )
[ "$DRY_RUN_MODE" -eq 1 ] && B4L_CMD+=( --dry-run )
[ -n "$JSON_INPUT_STR" ] && B4L_CMD+=( --json-input "$JSON_INPUT_STR" )

B4L_STDOUT_RAW="$SANDBOX_DIR/b4l_stdout.log"
B4L_STDERR_RAW="$SANDBOX_DIR/b4l_stderr.log"

T_START_EPOCH_MS="$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || python -c 'import time; print(int(time.time()*1000))' 2>/dev/null || awk 'BEGIN{srand(); printf "%d", systime()*1000}')"

B4L_EXIT_CODE=0
if [ -z "$JSON_INPUT_STR" ]; then
  "${B4L_CMD[@]}" < "$STIMULUS_FILE" > "$B4L_STDOUT_RAW" 2> "$B4L_STDERR_RAW" || B4L_EXIT_CODE=$?
else
  "${B4L_CMD[@]}" < /dev/null > "$B4L_STDOUT_RAW" 2> "$B4L_STDERR_RAW" || B4L_EXIT_CODE=$?
fi

T_END_EPOCH_MS="$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || python -c 'import time; print(int(time.time()*1000))' 2>/dev/null || awk 'BEGIN{srand(); printf "%d", systime()*1000}')"
ELAPSED_TTFT_MS=$(( T_END_EPOCH_MS - T_START_EPOCH_MS ))

HARVEST_REQ_FILE="$ARTIFACT_DIR/C_req_app.bin"
HARVEST_RESP_FILE="$ARTIFACT_DIR/C_resp_app.json"
HARVEST_CURL_LOG="$ARTIFACT_DIR/cURL.log"

: > "$HARVEST_REQ_FILE"
: > "$HARVEST_RESP_FILE"
: > "$HARVEST_CURL_LOG"

FOUND_RUN_DIR="$(find "$B4L_TMPDIR" -maxdepth 2 -type d \( -name "run.*" -o -name "groq.*" -o -name "se.*" \) 2>/dev/null | head -n 1 || true)"

if [ -n "$FOUND_RUN_DIR" ] && [ -d "$FOUND_RUN_DIR" ]; then
  RAW_PAYLOAD_MATCH="$(find "$FOUND_RUN_DIR" -maxdepth 1 -type f -name "payload*" 2>/dev/null | head -n 1 || true)"
  if [ -n "$RAW_PAYLOAD_MATCH" ] && [ -s "$RAW_PAYLOAD_MATCH" ]; then
    if [[ "$RAW_PAYLOAD_MATCH" == *.b64 ]]; then
      if command -v openssl >/dev/null 2>&1; then
        openssl enc -base64 -d < "$RAW_PAYLOAD_MATCH" > "$HARVEST_REQ_FILE" 2>/dev/null || true
      else
        base64 -d < "$RAW_PAYLOAD_MATCH" > "$HARVEST_REQ_FILE" 2>/dev/null || true
      fi
    else
      cp -f "$RAW_PAYLOAD_MATCH" "$HARVEST_REQ_FILE"
    fi
  fi

  if [ -f "$FOUND_RUN_DIR/resp.json" ] && [ -s "$FOUND_RUN_DIR/resp.json" ]; then
    cp -f "$FOUND_RUN_DIR/resp.json" "$HARVEST_RESP_FILE"
  fi

  if [ -f "$FOUND_RUN_DIR/err.log" ]; then
    cp -f "$FOUND_RUN_DIR/err.log" "$HARVEST_CURL_LOG"
  fi
fi

if [ ! -s "$HARVEST_RESP_FILE" ] && [ -s "$B4L_STDOUT_RAW" ]; then
  if jq -e . "$B4L_STDOUT_RAW" >/dev/null 2>&1; then
    cp -f "$B4L_STDOUT_RAW" "$HARVEST_RESP_FILE"
  fi
fi

cat "$B4L_STDERR_RAW" >> "$HARVEST_CURL_LOG" 2>/dev/null || true
chmod 600 "$HARVEST_REQ_FILE" "$HARVEST_RESP_FILE" "$HARVEST_CURL_LOG" 2>/dev/null || true

C_REQ_APP_BYTES_SHA256="$(openssl dgst -sha256 -r "$HARVEST_REQ_FILE" 2>/dev/null | awk '{print $1}' || sha256sum "$HARVEST_REQ_FILE" | awk '{print $1}')"
C_RESP_APP_BYTES_SHA256="$(openssl dgst -sha256 -r "$HARVEST_RESP_FILE" 2>/dev/null | awk '{print $1}' || sha256sum "$HARVEST_RESP_FILE" | awk '{print $1}')"

C_REQ_UNICODE_EXTRACTED=""
C_REQ_UNICODE_SHA256="null"

if [ -s "$HARVEST_REQ_FILE" ] && jq -e . "$HARVEST_REQ_FILE" >/dev/null 2>&1; then
  C_REQ_UNICODE_EXTRACTED="$(jq -r '
    if .messages then
      ([.messages[] | select(.role=="user") | if (.content | type) == "string" then .content else (.content[0].text // "") end] | last) // ""
    elif .contents then
      ([.contents[] | select(.role=="user") | .parts[0].text] | last) // ""
    elif .inputs then
      .inputs
    else
      ""
    end
  ' "$HARVEST_REQ_FILE" 2>/dev/null || echo "")"

  if [ -n "$C_REQ_UNICODE_EXTRACTED" ]; then
    TMP_REQ_U_FILE="$SANDBOX_DIR/req_u.txt"
    printf '%s' "$C_REQ_UNICODE_EXTRACTED" > "$TMP_REQ_U_FILE"
    C_REQ_UNICODE_SHA256="$(openssl dgst -sha256 -r "$TMP_REQ_U_FILE" 2>/dev/null | awk '{print $1}' || sha256sum "$TMP_REQ_U_FILE" | awk '{print $1}')"
    rm -f "$TMP_REQ_U_FILE" 2>/dev/null || true
  fi
fi

PARSED_OUTPUT_TEXT=""
OUTPUT_PARSED_SHA256="null"

if [ -s "$HARVEST_RESP_FILE" ] && jq -e . "$HARVEST_RESP_FILE" >/dev/null 2>&1; then
  PARSED_OUTPUT_TEXT="$(jq -r '
    if .choices and (.choices|length > 0) then
      (.choices[0].message.content // .choices[0].delta.content // .choices[0].text // "")
    elif .candidates and (.candidates|length > 0) then
      (.candidates[0].content.parts[0].text // "")
    elif .output_text then
      .output_text
    else
      ""
    end
  ' "$HARVEST_RESP_FILE" 2>/dev/null || echo "")"

  if [ -n "$PARSED_OUTPUT_TEXT" ]; then
    TMP_PARSED_FILE="$SANDBOX_DIR/parsed_out.txt"
    printf '%s' "$PARSED_OUTPUT_TEXT" > "$TMP_PARSED_FILE"
    OUTPUT_PARSED_SHA256="$(openssl dgst -sha256 -r "$TMP_PARSED_FILE" 2>/dev/null | awk '{print $1}' || sha256sum "$TMP_PARSED_FILE" | awk '{print $1}')"
    rm -f "$TMP_PARSED_FILE" 2>/dev/null || true
  fi
fi

REQ_ID_EXTRACTED="none"
HTTP_STATUS_EXTRACTED=0
FINISH_REASON_EXTRACTED="unknown"

if [ -s "$HARVEST_RESP_FILE" ] && jq -e . "$HARVEST_RESP_FILE" >/dev/null 2>&1; then
  REQ_ID_EXTRACTED="$(jq -r '.id // .x_groq?.id // "synthetic"' "$HARVEST_RESP_FILE" 2>/dev/null || echo "none")"
  FINISH_REASON_EXTRACTED="$(jq -r '.choices[0]?.finish_reason // .candidates[0]?.finishReason // "unknown"' "$HARVEST_RESP_FILE" 2>/dev/null || echo "unknown")"
  [ "$B4L_EXIT_CODE" -eq 0 ] && HTTP_STATUS_EXTRACTED=200 || HTTP_STATUS_EXTRACTED=400
fi

P_APP_REQUEST_OBSERVED=false
P_FINGERPRINT_MATCH=false
P_RESPONSE_CORRELATION=false
P_HARNESS_ISOLATION=true

[ -s "$HARVEST_REQ_FILE" ] && P_APP_REQUEST_OBSERVED=true

if [ "$P_APP_REQUEST_OBSERVED" = "true" ]; then
  if [ -n "$RAW_INPUT_TEXT" ]; then
    if [ "$C_REQ_UNICODE_SHA256" = "$STIMULUS_INTENDED_SHA256" ] || grep -F -q "$RAW_INPUT_TEXT" "$HARVEST_REQ_FILE" 2>/dev/null; then
      P_FINGERPRINT_MATCH=true
    fi
  else
    if jq -e 'has("messages") or has("contents") or has("inputs")' "$HARVEST_REQ_FILE" >/dev/null 2>&1; then
      P_FINGERPRINT_MATCH=true
    fi
  fi
fi

if [ -s "$HARVEST_RESP_FILE" ] && [ "$B4L_EXIT_CODE" -eq 0 ]; then
  P_RESPONSE_CORRELATION=true
fi

V3_CLASSIFICATION="V3-0a (No-Capture)"
V3_MOTIVATION="Nessun traffico applicativo catturato sul confine di invocazione."

if [ "$P_APP_REQUEST_OBSERVED" = "true" ] && [ "$P_FINGERPRINT_MATCH" = "true" ] && [ "$P_RESPONSE_CORRELATION" = "true" ] && [ "$P_HARNESS_ISOLATION" = "true" ]; then
  V3_CLASSIFICATION="V3-3 (App-Layer Verified)"
  V3_MOTIVATION="Payload C_req_app materializzato, C_req_unicode verificato e correlazione ID risposta confermata."
elif [ "$P_APP_REQUEST_OBSERVED" = "true" ]; then
  V3_CLASSIFICATION="V3-1 (Traffic Detected / Partial Match)"
  V3_MOTIVATION="Payload di richiesta presente ma correlazione di risposta parziale."
elif [ "$DRY_RUN_MODE" -eq 1 ]; then
  V3_CLASSIFICATION="V3-0b (Dry-Run Simulation)"
  V3_MOTIVATION="Modalita dry-run attiva; chiamate di rete simulate."
fi

OUTPUT_PROVENANCE="UNKNOWN"
TRIAL_CLASSIFICATION="FAILED_TRIAL"

if [ "$V3_CLASSIFICATION" = "V3-3 (App-Layer Verified)" ] && [ -n "$PARSED_OUTPUT_TEXT" ]; then
  OUTPUT_PROVENANCE="VERIFIED"
  TRIAL_CLASSIFICATION="VALID_TRIAL"
elif [ "$B4L_EXIT_CODE" -eq 0 ] && [ -n "$PARSED_OUTPUT_TEXT" ]; then
  OUTPUT_PROVENANCE="ATTRIBUTED"
  TRIAL_CLASSIFICATION="BEHAVIORAL_ONLY_TRIAL"
elif [ "$B4L_EXIT_CODE" -ne 0 ]; then
  TRIAL_CLASSIFICATION="FAILED_TRIAL"
  OUTPUT_PROVENANCE="UNKNOWN"
fi

TRIAL_METADATA_FILE="$ARTIFACT_DIR/trial_metadata.json"

TRIAL_JSON="$(jq -c -n \
  --arg prov "$PROVIDER" \
  --arg mod "$MODEL_ID" \
  --argjson temp "$TEMPERATURE" \
  --argjson max_tok "$MAX_TOKENS" \
  --arg u_sha "$STIMULUS_INTENDED_SHA256" \
  --arg u_buf_sha "$U_BUFFER_BYTES_SHA256" \
  --arg req_u_sha "$C_REQ_UNICODE_SHA256" \
  --arg req_sha "$C_REQ_APP_BYTES_SHA256" \
  --arg resp_sha "$C_RESP_APP_BYTES_SHA256" \
  --arg out_sha "$OUTPUT_PARSED_SHA256" \
  --arg req_id "$REQ_ID_EXTRACTED" \
  --argjson http_st "$HTTP_STATUS_EXTRACTED" \
  --arg fin_r "$FINISH_REASON_EXTRACTED" \
  --argjson b4l_rc "$B4L_EXIT_CODE" \
  --argjson ttft_ms "$ELAPSED_TTFT_MS" \
  --arg v3_cls "$V3_CLASSIFICATION" \
  --arg v3_mot "$V3_MOTIVATION" \
  --arg out_prov "$OUTPUT_PROVENANCE" \
  --arg trial_cls "$TRIAL_CLASSIFICATION" \
  --argjson p_app "$P_APP_REQUEST_OBSERVED" \
  --argjson p_fp "$P_FINGERPRINT_MATCH" \
  --argjson p_corr "$P_RESPONSE_CORRELATION" \
  --argjson p_iso "$P_HARNESS_ISOLATION" \
  '{
    sut: {
      provider: $prov,
      model_id: $mod,
      temperature: $temp,
      max_tokens: $max_tok
    },
    timing: {
      ttft_observed_e2e_ms: $ttft_ms
    },
    provenance_dag: {
      stimulus_intended_sha256: $u_sha,
      u_buffer_bytes_sha256: $u_buf_sha,
      c_req_unicode_sha256: (if $req_u_sha == "null" then null else $req_u_sha end),
      c_req_app_bytes_sha256: $req_sha,
      c_resp_app_bytes_sha256: $resp_sha,
      output_parsed_sha256: (if $out_sha == "null" then null else $out_sha end)
    },
    audit_trail: {
      req_id_extracted: $req_id,
      http_status: $http_st,
      finish_reason: $fin_r,
      bash4llm_exit_code: $b4l_rc,
      v3_classification: $v3_cls,
      v3_motivation: $v3_mot,
      predicates: {
        P_app_request_observed: $p_app,
        P_fingerprint_match: $p_fp,
        P_response_correlation: $p_corr,
        P_harness_isolation: $p_iso,
        P_external_concurrency: "UNKNOWN (Non-observable without OS-wide tracing)"
      }
    },
    evaluation: {
      output_provenance: $out_prov,
      trial_classification: $trial_cls
    }
  }')"

printf '%s\n' "$TRIAL_JSON" > "$TRIAL_METADATA_FILE"
chmod 600 "$TRIAL_METADATA_FILE" 2>/dev/null || true

printf '%s\n' "$TRIAL_JSON"
exit "$B4L_EXIT_CODE"
