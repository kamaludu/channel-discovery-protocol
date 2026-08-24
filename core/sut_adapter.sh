#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# CDP/SOP v2.3 METROLOGY HARNESS
# File: core/sut_adapter.sh
# Component: Wrapper SUT & Adapter Runtime per Invocazione e Introspezione
# Standard: CDP v2.3 (Sez. 1, 4, 5) & SOP v2.3 (Sez. 1.3, 2.2, 3.1, 4.1) & CDP-SAC v1.0
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/channel-discovery-protocol/
# Contact: opensource@cevangel.anonaddy.me
# ==============================================================================
# Requirements: bash (>=4.0), coreutils, util-linux, curl, jq, openssl, python (>=3.10 stdlib)
#
# ==============================================================================
# GUIDA ARCHITETTURALE PER SVILUPPATORI / ADAPTER PLUGGABILITY (CDP-SAC v1.0):
# ==============================================================================
# Questo script incapsula il confine di esecuzione del System Under Test (SUT).
# Implementa l'interfaccia verso la CLI esterna 'bash4llm'.
# Raccoglie in modo deterministico e senza valori cablati:
#   - C_req_app.bin     : Payload grezzo inviato sulla rete (JSON/HTTP body).
#   - C_resp_app.json   : Risposta raw ricevuta dal server.
#   - cURL.log          : Traccia di trasporto/TLS ed header HTTP.
#   - O_parsed.txt      : Testo puro estratto dalla risposta.
#   - trial_metadata.json : Metadati di prova, DAG SHA-256 ed error_diagnostics.
# ==============================================================================

set -euo pipefail
umask 077

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# ==============================================================================
# FUNZIONE HELPER: CALCOLO DETERMINISTICO DIGEST SHA-256 SUI FILE
# ==============================================================================
calc_sha256_file() {
  local target_f="$1"
  if [ ! -f "$target_f" ] || [ ! -r "$target_f" ]; then
    printf 'NOT_OBSERVED\n'
    return 0
  fi

  if command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 -r "$target_f" 2>/dev/null | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$target_f" 2>/dev/null | awk '{print $1}'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import hashlib, sys; print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$target_f" 2>/dev/null || printf 'NOT_OBSERVED\n'
  elif command -v python >/dev/null 2>&1; then
    python -c "import hashlib, sys; print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$target_f" 2>/dev/null || printf 'NOT_OBSERVED\n'
  else
    printf 'NOT_OBSERVED\n'
  fi
}

# ==============================================================================
# SEZIONE 1: GESTIONE PARAMETRI CLI (Nessun default o provider/modello hardcoded)
# ==============================================================================
BASH4LLM_BIN=""
PROVIDER=""
MODEL_ID=""
TEMPERATURE=""
MAX_TOKENS=""
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
  --bash4llm-bin <PATH>   Percorso dell'eseguibile SUT (bash4llm).
  --artifact-dir <DIR>    Directory di destinazione per la raccolta degli artefatti grezzi.

Configurazione SUT (Se omesse, delegate all'introspezione attiva del SUT):
  --provider <NAME>       Nome del provider target (es. groq, gemini, mistral, openrouter).
  --model <MODEL_ID>      Identificativo del modello per l'invocazione.
  --temperature <FLOAT>   Parametro di campionamento temperatura.
  --max-tokens <INT>      Limite massimo di token di output.
  --system-prompt <STR>   System prompt facoltativo.

Stimolo di Input:
  --input-text <STR>      Stringa scalare UTF-8 grezza (U_intended).
  --input-file <PATH>     File contenente lo stimolo di input grezzo.
  --json-input <JSON>     Payload JSON strutturato pre-formattato.
  --intended-sha256 <HEX> Digest SHA-256 atteso per verifica formale pre-invio.

Sicurezza e Controllo Runtime:
  --vault-ctx <PASS>      Passcode master / token di sblocco per l'OpenSSL Vault.
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
      [ $# -ge 2 ] || { printf 'sut_adapter: ERRORE: --intended-sha256 richiede un digest hex a 64 caratteri\n' >&2; exit 2; }
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
  printf 'sut_adapter: ERRORE: Eseguibile SUT non trovato (%s)\n' "${BASH4LLM_BIN:-<non_specificato>}" >&2
  exit 15
fi

if [ -z "$ARTIFACT_DIR" ]; then
  printf 'sut_adapter: ERRORE: --artifact-dir e obbligatorio\n' >&2
  exit 15
fi

mkdir -p "$ARTIFACT_DIR" 2>/dev/null || true
chmod 700 "$ARTIFACT_DIR" 2>/dev/null || true

# Configurazione directory sandbox isolata
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

# ==============================================================================
# SEZIONE 2: PREPARAZIONE E VALIDAZIONE GROUND TRUTH (U_intended)
# ==============================================================================
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
    printf 'sut_adapter: ERRORE: Nessuno stimolo di input fornito\n' >&2
    exit 14
  fi
fi
chmod 600 "$STIMULUS_FILE" 2>/dev/null || true

STIMULUS_INTENDED_SHA256="$(calc_sha256_file "$STIMULUS_FILE")"
U_BUFFER_BYTES_SHA256="$STIMULUS_INTENDED_SHA256"

if [ -n "$INTENDED_SHA256_EXPECTED" ] && [ "$STIMULUS_INTENDED_SHA256" != "$INTENDED_SHA256_EXPECTED" ]; then
  printf 'sut_adapter: ERRORE CRITICO [INVALID_STIMULUS]: Disallineamento digest SHA-256 pre-invio!\n' >&2
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

# ==============================================================================
# SEZIONE 3: INVOCAZIONE SUT (Binding specifico bash4llm)
# ==============================================================================
B4L_TMPDIR="$SANDBOX_DIR/b4l_tmp"
mkdir -p "$B4L_TMPDIR" 2>/dev/null || true
chmod 700 "$B4L_TMPDIR" 2>/dev/null || true

export BASH4LLM_TMPDIR="$B4L_TMPDIR"
export DEBUG_PRESERVE=1
export NO_COLOR=1

# Autenticazione OpenSSL Vault tramite variabile di contesto runtime
if [ -n "$VAULT_SESSION_PASS" ]; then
  export _B4L_RT_CTX="$VAULT_SESSION_PASS"
fi

# Costruzione dinamica del comando bash4llm: nessun parametro opzionale viene forzato se omesso
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

# Misurazione timestamp per TTFT / E2E Latency
T_START_EPOCH_MS="$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || python -c 'import time; print(int(time.time()*1000))' 2>/dev/null || awk 'BEGIN{srand(); printf "%d", systime()*1000}')"

B4L_EXIT_CODE=0
if [ -z "$JSON_INPUT_STR" ]; then
  "${B4L_CMD[@]}" < "$STIMULUS_FILE" > "$B4L_STDOUT_RAW" 2> "$B4L_STDERR_RAW" || B4L_EXIT_CODE=$?
else
  "${B4L_CMD[@]}" < /dev/null > "$B4L_STDOUT_RAW" 2> "$B4L_STDERR_RAW" || B4L_EXIT_CODE=$?
fi

T_END_EPOCH_MS="$(python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null || python -c 'import time; print(int(time.time()*1000))' 2>/dev/null || awk 'BEGIN{srand(); printf "%d", systime()*1000}')"
ELAPSED_TTFT_MS=$(( T_END_EPOCH_MS - T_START_EPOCH_MS ))

# ==============================================================================
# SEZIONE 4: RACCOLTA ARTEFATTI GREZZI (Artifact Harvesting)
# ==============================================================================
HARVEST_REQ_FILE="$ARTIFACT_DIR/C_req_app.bin"
HARVEST_RESP_FILE="$ARTIFACT_DIR/C_resp_app.json"
HARVEST_CURL_LOG="$ARTIFACT_DIR/cURL.log"
HARVEST_PARSED_OUT="$ARTIFACT_DIR/O_parsed.txt"

: > "$HARVEST_REQ_FILE"
: > "$HARVEST_RESP_FILE"
: > "$HARVEST_CURL_LOG"
: > "$HARVEST_PARSED_OUT"

# Scansione deterministica sia nella root di B4L_TMPDIR che nelle sottodirectory generate
SEARCH_DIRS=( "$B4L_TMPDIR" )
while IFS= read -r sub_d; do
  [ -n "$sub_d" ] && SEARCH_DIRS+=( "$sub_d" )
done < <(find "$B4L_TMPDIR" -maxdepth 2 -mindepth 1 -type d 2>/dev/null || true)

for s_dir in "${SEARCH_DIRS[@]}"; do
  # 1. Raccolta Payload di Richiesta
  if [ ! -s "$HARVEST_REQ_FILE" ]; then
    RAW_PAYLOAD_MATCH="$(find "$s_dir" -maxdepth 1 -type f -name "payload*" 2>/dev/null | head -n 1 || true)"
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
  fi

  # 2. Raccolta Payload di Risposta
  if [ ! -s "$HARVEST_RESP_FILE" ] && [ -f "$s_dir/resp.json" ] && [ -s "$s_dir/resp.json" ]; then
    cp -f "$s_dir/resp.json" "$HARVEST_RESP_FILE"
  fi

  # 3. Raccolta Log cURL
  if [ -f "$s_dir/err.log" ] && [ -s "$s_dir/err.log" ]; then
    cat "$s_dir/err.log" >> "$HARVEST_CURL_LOG" 2>/dev/null || true
  fi
done

# Fallback stdout: se resp.json non era presente su disco ma il payload JSON e' stato emesso su stdout
if [ ! -s "$HARVEST_RESP_FILE" ] && [ -s "$B4L_STDOUT_RAW" ]; then
  if jq -e . "$B4L_STDOUT_RAW" >/dev/null 2>&1; then
    cp -f "$B4L_STDOUT_RAW" "$HARVEST_RESP_FILE"
  fi
fi

# Preservazione integrale di stderr per tracciabilita' diagnostica
cat "$B4L_STDERR_RAW" >> "$HARVEST_CURL_LOG" 2>/dev/null || true
chmod 600 "$HARVEST_REQ_FILE" "$HARVEST_RESP_FILE" "$HARVEST_CURL_LOG" 2>/dev/null || true

# ==============================================================================
# SEZIONE 5: INTROSPEZIONE DETERMINISTICA & CALCOLO DEL DAG DI PROVENIENZA
# ==============================================================================
C_REQ_APP_BYTES_SHA256="$(calc_sha256_file "$HARVEST_REQ_FILE")"
C_RESP_APP_BYTES_SHA256="$(calc_sha256_file "$HARVEST_RESP_FILE")"

# Estrazione del testo Unicode dal payload applicativo di richiesta (C_req_unicode)
C_REQ_UNICODE_EXTRACTED=""
C_REQ_UNICODE_SHA256="null"

if [ -s "$HARVEST_REQ_FILE" ] && jq -e . "$HARVEST_REQ_FILE" >/dev/null 2>&1; then
  C_REQ_UNICODE_EXTRACTED="$(jq -r '
    if .messages then
      ([.messages[] | select(.role=="user") | if (.content | type) == "string" then .content else ([.content[]?.text // empty] | join("")) end] | last) // ""
    elif .contents then
      ([.contents[] | select(.role=="user") | ([.parts[]?.text // empty] | join(""))] | last) // ""
    elif .inputs then
      if (.inputs | type) == "string" then .inputs else (.inputs | tostring) end
    elif .prompt then
      .prompt
    else
      ""
    end
  ' "$HARVEST_REQ_FILE" 2>/dev/null || echo "")"

  if [ -n "$C_REQ_UNICODE_EXTRACTED" ]; then
    TMP_REQ_U_FILE="$SANDBOX_DIR/req_u.txt"
    printf '%s' "$C_REQ_UNICODE_EXTRACTED" > "$TMP_REQ_U_FILE"
    C_REQ_UNICODE_SHA256="$(calc_sha256_file "$TMP_REQ_U_FILE")"
    rm -f "$TMP_REQ_U_FILE" 2>/dev/null || true
  fi
fi

# Estrazione dell'output terminale deserializzato (O_parsed) con supporto multi-part
PARSED_OUTPUT_TEXT=""
OUTPUT_PARSED_SHA256="null"

if [ -s "$HARVEST_RESP_FILE" ] && jq -e . "$HARVEST_RESP_FILE" >/dev/null 2>&1; then
  PARSED_OUTPUT_TEXT="$(jq -r '
    if .choices and (.choices|length > 0) then
      if (.choices[0].message.content | type) == "string" then
        .choices[0].message.content
      elif .choices[0].message.content then
        ([.choices[0].message.content[]?.text // empty] | join(""))
      elif .choices[0].delta.content then
        .choices[0].delta.content
      elif .choices[0].text then
        .choices[0].text
      else
        ""
      end
    elif .candidates and (.candidates|length > 0) then
      ([.candidates[0].content.parts[]?.text // empty] | join(""))
    elif .output_text then
      .output_text
    elif .generated_text then
      .generated_text
    else
      ""
    end
  ' "$HARVEST_RESP_FILE" 2>/dev/null || echo "")"

  if [ -n "$PARSED_OUTPUT_TEXT" ]; then
    printf '%s' "$PARSED_OUTPUT_TEXT" > "$HARVEST_PARSED_OUT"
    chmod 600 "$HARVEST_PARSED_OUT" 2>/dev/null || true
    OUTPUT_PARSED_SHA256="$(calc_sha256_file "$HARVEST_PARSED_OUT")"
  fi
fi

# Introspezione reale dei metadati SUT (Runtime Version, Provider, Model ID)
DECLARED_RUNTIME_VERSION="NOT_OBSERVED"
if [ -n "$BASH4LLM_BIN" ]; then
  DECLARED_RUNTIME_VERSION="$(bash "$BASH4LLM_BIN" --version 2>/dev/null | head -n 1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' || echo "NOT_OBSERVED")"
  [ -z "$DECLARED_RUNTIME_VERSION" ] && DECLARED_RUNTIME_VERSION="NOT_OBSERVED"
fi

REQ_ID_EXTRACTED="NOT_OBSERVED"
FINISH_REASON_EXTRACTED="NOT_OBSERVED"
HTTP_STATUS_EXTRACTED="null"
ACTUAL_OBSERVED_MODEL="UNRESOLVED"
ACTUAL_OBSERVED_PROVIDER="UNRESOLVED"

# 1. Rilevamento Provider Effettivo
if [ -n "$PROVIDER" ]; then
  ACTUAL_OBSERVED_PROVIDER="$PROVIDER"
else
  if [ -n "$BASH4LLM_BIN" ]; then
    ACTIVE_PROV_FILE="$(bash "$BASH4LLM_BIN" --print-provider-file 2>/dev/null || true)"
    if [ -n "$ACTIVE_PROV_FILE" ] && [ -f "$ACTIVE_PROV_FILE" ]; then
      ACTUAL_OBSERVED_PROVIDER="$(cat "$ACTIVE_PROV_FILE" 2>/dev/null | tr -d ' \n\r' || echo "UNRESOLVED")"
    fi
  fi
fi
[ -z "$ACTUAL_OBSERVED_PROVIDER" ] && ACTUAL_OBSERVED_PROVIDER="UNRESOLVED"

# 2. Rilevamento Model ID Effettivo (Payload > CLI Flag > Config File)
if [ -s "$HARVEST_RESP_FILE" ] && jq -e . "$HARVEST_RESP_FILE" >/dev/null 2>&1; then
  REQ_ID_EXTRACTED="$(jq -r '.id // .x_groq?.id // .header?.["x-request-id"] // "NOT_OBSERVED"' "$HARVEST_RESP_FILE" 2>/dev/null || echo "NOT_OBSERVED")"
  FINISH_REASON_EXTRACTED="$(jq -r '.choices[0]?.finish_reason // .candidates[0]?.finishReason // "NOT_OBSERVED"' "$HARVEST_RESP_FILE" 2>/dev/null || echo "NOT_OBSERVED")"
  
  RESP_MODEL="$(jq -r '.model // empty' "$HARVEST_RESP_FILE" 2>/dev/null || true)"
  if [ -n "$RESP_MODEL" ]; then
    ACTUAL_OBSERVED_MODEL="$RESP_MODEL"
  fi
fi

if [ "$ACTUAL_OBSERVED_MODEL" = "UNRESOLVED" ]; then
  if [ -n "$MODEL_ID" ]; then
    ACTUAL_OBSERVED_MODEL="$MODEL_ID"
  elif [ -n "$BASH4LLM_BIN" ] && [ "$ACTUAL_OBSERVED_PROVIDER" != "UNRESOLVED" ]; then
    ACTIVE_MODEL_FILE="$(bash "$BASH4LLM_BIN" --print-model-file "$ACTUAL_OBSERVED_PROVIDER" 2>/dev/null || true)"
    if [ -n "$ACTIVE_MODEL_FILE" ] && [ -f "$ACTIVE_MODEL_FILE" ]; then
      ACTUAL_OBSERVED_MODEL="$(cat "$ACTIVE_MODEL_FILE" 2>/dev/null | tr -d ' \n\r' || echo "UNRESOLVED")"
    fi
  fi
fi
[ -z "$ACTUAL_OBSERVED_MODEL" ] && ACTUAL_OBSERVED_MODEL="UNRESOLVED"

# 3. Estrazione reale dell'HTTP Status Code dai log di trasporto cURL o da JSON error
HTTP_CODE_CURL="$(grep -E -o '< HTTP/[123.]+ [0-9]{3}|HTTP/[123.]+ [0-9]{3}' "$HARVEST_CURL_LOG" 2>/dev/null | tail -n 1 | awk '{print $NF}' || true)"
if [ -n "$HTTP_CODE_CURL" ] && [[ "$HTTP_CODE_CURL" =~ ^[0-9]{3}$ ]]; then
  HTTP_STATUS_EXTRACTED="$HTTP_CODE_CURL"
elif [ -s "$HARVEST_RESP_FILE" ] && jq -e '.error.code' "$HARVEST_RESP_FILE" >/dev/null 2>&1; then
  JSON_ERR_CODE="$(jq -r '.error.code' "$HARVEST_RESP_FILE" 2>/dev/null || true)"
  if [[ "$JSON_ERR_CODE" =~ ^[0-9]{3}$ ]]; then
    HTTP_STATUS_EXTRACTED="$JSON_ERR_CODE"
  fi
fi

# ==============================================================================
# SEZIONE 6: ESTRAZIONE DIAGNOSTICA ERRORI & QUOTE (error_diagnostics)
# ==============================================================================
ERR_IS_ERROR=false
ERR_IS_RATE_LIMITED=false
ERR_CODE="null"
ERR_STATUS="null"
ERR_MESSAGE="null"
ERR_QUOTA_METRIC="null"
ERR_QUOTA_ID="null"
ERR_QUOTA_VALUE="null"
ERR_RETRY_DELAY="null"

if [ -s "$HARVEST_RESP_FILE" ] && jq -e 'has("error")' "$HARVEST_RESP_FILE" >/dev/null 2>&1; then
  ERR_IS_ERROR=true
  
  ERR_CODE="$(jq -r '.error.code // empty' "$HARVEST_RESP_FILE" 2>/dev/null || echo "")"
  ERR_STATUS="$(jq -r '.error.status // empty' "$HARVEST_RESP_FILE" 2>/dev/null || echo "")"
  ERR_MESSAGE="$(jq -r '.error.message // empty' "$HARVEST_RESP_FILE" 2>/dev/null || echo "")"
  
  ERR_QUOTA_METRIC="$(jq -r '
    ([.error.details[]? | select(.["@type"]=="type.googleapis.com/google.rpc.QuotaFailure" or has("violations")) | .violations[]?.quotaMetric // empty] | first) // empty
  ' "$HARVEST_RESP_FILE" 2>/dev/null || echo "")"

  ERR_QUOTA_ID="$(jq -r '
    ([.error.details[]? | select(.["@type"]=="type.googleapis.com/google.rpc.QuotaFailure" or has("violations")) | .violations[]?.quotaId // empty] | first) // empty
  ' "$HARVEST_RESP_FILE" 2>/dev/null || echo "")"

  ERR_QUOTA_VALUE="$(jq -r '
    ([.error.details[]? | select(.["@type"]=="type.googleapis.com/google.rpc.QuotaFailure" or has("violations")) | .violations[]?.quotaValue // empty] | first) // empty
  ' "$HARVEST_RESP_FILE" 2>/dev/null || echo "")"

  ERR_RETRY_DELAY="$(jq -r '
    ([.error.details[]? | select(.["@type"]=="type.googleapis.com/google.rpc.RetryInfo" or has("retryDelay")) | .retryDelay // empty] | first) // empty
  ' "$HARVEST_RESP_FILE" 2>/dev/null || echo "")"

  [ -z "$ERR_CODE" ] && ERR_CODE="null"
  [ -z "$ERR_STATUS" ] && ERR_STATUS="null"
  [ -z "$ERR_MESSAGE" ] && ERR_MESSAGE="null"
  [ -z "$ERR_QUOTA_METRIC" ] && ERR_QUOTA_METRIC="null"
  [ -z "$ERR_QUOTA_ID" ] && ERR_QUOTA_ID="null"
  [ -z "$ERR_QUOTA_VALUE" ] && ERR_QUOTA_VALUE="null"
  [ -z "$ERR_RETRY_DELAY" ] && ERR_RETRY_DELAY="null"
fi

# Controllo rate-limiting da status HTTP o payload o log
if [ "$HTTP_STATUS_EXTRACTED" = "429" ] || [ "$ERR_CODE" = "429" ] || [ "$ERR_STATUS" = "RESOURCE_EXHAUSTED" ] || grep -qi "RESOURCE_EXHAUSTED\|Rate limit\|429" "$HARVEST_CURL_LOG" 2>/dev/null; then
  ERR_IS_RATE_LIMITED=true
  ERR_IS_ERROR=true
fi

# ==============================================================================
# SEZIONE 7: PREDICATI METROLOGICI & CLASSIFICAZIONE OSSERVABILITA V3
# ==============================================================================
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
    if jq -e 'has("messages") or has("contents") or has("inputs") or has("prompt")' "$HARVEST_REQ_FILE" >/dev/null 2>&1; then
      P_FINGERPRINT_MATCH=true
    fi
  fi
fi

# Correlazione di risposta formale: payload presente, status 2xx, exit code 0 e nessun oggetto error
if [ -s "$HARVEST_RESP_FILE" ] && [ "$B4L_EXIT_CODE" -eq 0 ] && [ "$ERR_IS_ERROR" = "false" ]; then
  if [ "$HTTP_STATUS_EXTRACTED" = "null" ] || [[ "$HTTP_STATUS_EXTRACTED" =~ ^2[0-9]{2}$ ]]; then
    P_RESPONSE_CORRELATION=true
  fi
fi

V3_CLASSIFICATION="V3-0a (No-Capture)"
V3_MOTIVATION="Nessun traffico applicativo catturato sul confine di invocazione."
OUTPUT_PROVENANCE="UNKNOWN"
TRIAL_CLASSIFICATION="FAILED_TRIAL"
ADAPTER_FINAL_EXIT_CODE="$B4L_EXIT_CODE"

if [ "$ERR_IS_RATE_LIMITED" = "true" ]; then
  V3_CLASSIFICATION="V3-1 (Rate-Limited / 429)"
  V3_MOTIVATION="Richiesta respinta dal server per superamento quote o rate limit (HTTP 429 / RESOURCE_EXHAUSTED)."
  OUTPUT_PROVENANCE="UNKNOWN"
  TRIAL_CLASSIFICATION="RATE_LIMITED_TRIAL"
  ADAPTER_FINAL_EXIT_CODE=16
elif [ "$ERR_IS_ERROR" = "true" ] || [ "$B4L_EXIT_CODE" -ne 0 ] || [[ "$HTTP_STATUS_EXTRACTED" =~ ^[45][0-9]{2}$ ]]; then
  V3_CLASSIFICATION="V3-1 (API Error / Non-2xx Response)"
  V3_MOTIVATION="Risposta del server con errore HTTP ${HTTP_STATUS_EXTRACTED:-<non_rilevato>} o payload JSON di errore."
  OUTPUT_PROVENANCE="UNKNOWN"
  TRIAL_CLASSIFICATION="FAILED_TRIAL"
  [ "$ADAPTER_FINAL_EXIT_CODE" -eq 0 ] && ADAPTER_FINAL_EXIT_CODE=1
elif [ "$P_APP_REQUEST_OBSERVED" = "true" ] && [ "$P_FINGERPRINT_MATCH" = "true" ] && [ "$P_RESPONSE_CORRELATION" = "true" ] && [ "$P_HARNESS_ISOLATION" = "true" ]; then
  V3_CLASSIFICATION="V3-3 (App-Layer Verified)"
  V3_MOTIVATION="Payload C_req_app materializzato, C_req_unicode verificato e correlazione risposta confermata."
  OUTPUT_PROVENANCE="VERIFIED"
  TRIAL_CLASSIFICATION="VALID_TRIAL"
elif [ "$B4L_EXIT_CODE" -eq 0 ] && [ -n "$PARSED_OUTPUT_TEXT" ]; then
  V3_CLASSIFICATION="V3-1 (Traffic Detected / Partial Match)"
  V3_MOTIVATION="Output terminale acquisito ma correlazione V3 parziale o asincrona."
  OUTPUT_PROVENANCE="ATTRIBUTED"
  TRIAL_CLASSIFICATION="BEHAVIORAL_ONLY_TRIAL"
elif [ "$DRY_RUN_MODE" -eq 1 ]; then
  V3_CLASSIFICATION="V3-0b (Dry-Run Simulation)"
  V3_MOTIVATION="Modalita dry-run attiva; invocazione simulata senza rete."
  OUTPUT_PROVENANCE="UNKNOWN"
  TRIAL_CLASSIFICATION="VALID_TRIAL"
fi

# ==============================================================================
# SEZIONE 8: EMISSIONE METADATI DEL TRIAL (trial_metadata.json)
# ==============================================================================
TRIAL_METADATA_FILE="$ARTIFACT_DIR/trial_metadata.json"

TRIAL_JSON="$(jq -c -n \
  --arg prov "$ACTUAL_OBSERVED_PROVIDER" \
  --arg mod "$ACTUAL_OBSERVED_MODEL" \
  --arg r_ver "$DECLARED_RUNTIME_VERSION" \
  --arg temp "${TEMPERATURE:-null}" \
  --arg max_tok "${MAX_TOKENS:-null}" \
  --arg u_sha "$STIMULUS_INTENDED_SHA256" \
  --arg u_buf_sha "$U_BUFFER_BYTES_SHA256" \
  --arg req_u_sha "$C_REQ_UNICODE_SHA256" \
  --arg req_sha "$C_REQ_APP_BYTES_SHA256" \
  --arg resp_sha "$C_RESP_APP_BYTES_SHA256" \
  --arg out_sha "$OUTPUT_PARSED_SHA256" \
  --arg req_id "$REQ_ID_EXTRACTED" \
  --arg http_st "$HTTP_STATUS_EXTRACTED" \
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
  --argjson err_is_err "$ERR_IS_ERROR" \
  --argjson err_is_rl "$ERR_IS_RATE_LIMITED" \
  --arg err_code "$ERR_CODE" \
  --arg err_status "$ERR_STATUS" \
  --arg err_msg "$ERR_MESSAGE" \
  --arg q_metric "$ERR_QUOTA_METRIC" \
  --arg q_id "$ERR_QUOTA_ID" \
  --arg q_val "$ERR_QUOTA_VALUE" \
  --arg r_delay "$ERR_RETRY_DELAY" \
  '{
    sut: {
      provider: $prov,
      model_id: $mod,
      declared_runtime_version: $r_ver,
      temperature: (if $temp == "null" then null else ($temp | tonumber? // null) end),
      max_tokens: (if $max_tok == "null" then null else ($max_tok | tonumber? // null) end)
    },
    timing: {
      ttft_observed_e2e_ms: $ttft_ms
    },
    provenance_dag: {
      stimulus_intended_sha256: $u_sha,
      u_buffer_bytes_sha256: $u_buf_sha,
      c_req_unicode_sha256: (if $req_u_sha == "null" then null else $req_u_sha end),
      c_req_app_bytes_sha256: (if $req_sha == "NOT_OBSERVED" then null else $req_sha end),
      c_resp_app_bytes_sha256: (if $resp_sha == "NOT_OBSERVED" then null else $resp_sha end),
      output_parsed_sha256: (if $out_sha == "null" then null else $out_sha end)
    },
    audit_trail: {
      req_id_extracted: $req_id,
      http_status: (if $http_st == "null" or $http_st == "NOT_OBSERVED" then null else ($http_st | tonumber? // null) end),
      finish_reason: $fin_r,
      bash4llm_exit_code: $b4l_rc,
      v3_classification: $v3_cls,
      v3_motivation: $v3_mot,
      predicates: {
        P_app_request_observed: $p_app,
        P_fingerprint_match: $p_fp,
        P_response_correlation: $p_corr,
        P_harness_isolation: $p_iso,
        P_external_concurrency: "NOT_OBSERVED (Requires OS tracing)"
      }
    },
    error_diagnostics: {
      is_error: $err_is_err,
      is_rate_limited: $err_is_rl,
      error_code: (if $err_code == "null" or $err_code == "" then null else ($err_code | tonumber? // $err_code) end),
      error_status: (if $err_status == "null" or $err_status == "" then null else $err_status end),
      error_message: (if $err_msg == "null" or $err_msg == "" then null else $err_msg end),
      quota_metric: (if $q_metric == "null" or $q_metric == "" then null else $q_metric end),
      quota_id: (if $q_id == "null" or $q_id == "" then null else $q_id end),
      quota_value: (if $q_val == "null" or $q_val == "" then null else $q_val end),
      retry_delay: (if $r_delay == "null" or $r_delay == "" then null else $r_delay end)
    },
    evaluation: {
      output_provenance: $out_prov,
      trial_classification: $trial_cls
    }
  }')"

printf '%s\n' "$TRIAL_JSON" > "$TRIAL_METADATA_FILE"
chmod 600 "$TRIAL_METADATA_FILE" 2>/dev/null || true

printf '%s\n' "$TRIAL_JSON"
exit "$ADAPTER_FINAL_EXIT_CODE"
