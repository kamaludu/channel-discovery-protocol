#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ======================================
# CDP/SOP v2.3 METROLOGY HARNESS
# File: core/env_telemetry.sh
# Component: Sonda Telemetrica Ambientale Termux
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

TARGET_ENDPOINT=""
OUTPUT_FILE=""
RTT_SAMPLES=5
QUIET_MODE=0

usage() {
  cat <<'EOF'
Uso: env_telemetry.sh [OPZIONI]

Opzioni:
  --endpoint <URL>     URL dell'endpoint SUT per la stima della baseline RTT.
  --out <FILE>         Percorso del file JSON di output (default: stdout).
  --samples <N>        Numero di campioni per la stima RTT (default: 5).
  --quiet              Sopprime i messaggi diagnostici su stderr.
  -h, --help           Mostra questa guida ed esce.
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --endpoint)
      [ $# -ge 2 ] || { printf 'env_telemetry: ERRORE: --endpoint richiede un URL\n' >&2; exit 2; }
      TARGET_ENDPOINT="$2"
      shift 2
      ;;
    --out)
      [ $# -ge 2 ] || { printf 'env_telemetry: ERRORE: --out richiede un percorso file\n' >&2; exit 2; }
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --samples)
      [ $# -ge 2 ] || { printf 'env_telemetry: ERRORE: --samples richiede un intero\n' >&2; exit 2; }
      RTT_SAMPLES="$2"
      shift 2
      ;;
    --quiet)
      QUIET_MODE=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      printf 'env_telemetry: ERRORE: Opzione sconosciuta: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

CPU_ARCH="$(uname -m 2>/dev/null || echo "unknown")"
KERNEL_RELEASE="$(uname -r 2>/dev/null || echo "unknown")"
OS_UNAME="$(uname -s 2>/dev/null || echo "Linux")"

ANDROID_VERSION="non-android"
DEVICE_MODEL="Generic POSIX Host"

if [ -n "${TERMUX_VERSION:-}" ] || [ -d "/data/data/com.termux" ] || [ -f "/system/build.prop" ]; then
  if command -v getprop >/dev/null 2>&1; then
    ANDROID_VERSION="$(getprop ro.build.version.release 2>/dev/null || echo "unknown")"
    DEV_MANUFACTURER="$(getprop ro.product.manufacturer 2>/dev/null || echo "")"
    DEV_MODEL_NAME="$(getprop ro.product.model 2>/dev/null || echo "")"
    if [ -n "$DEV_MANUFACTURER" ] || [ -n "$DEV_MODEL_NAME" ]; then
      DEVICE_MODEL="Android/Termux (${DEV_MANUFACTURER} ${DEV_MODEL_NAME}, arch: ${CPU_ARCH})"
    else
      DEVICE_MODEL="Android/Termux (arch: ${CPU_ARCH})"
    fi
  else
    ANDROID_VERSION="Android (getprop unavailable)"
    DEVICE_MODEL="Android/Termux (arch: ${CPU_ARCH})"
  fi
else
  DEVICE_MODEL="${OS_UNAME} (${CPU_ARCH})"
fi

BASH_VER="${BASH_VERSION:-unknown}"
CURL_VER="$(curl --version 2>/dev/null | head -n 1 | awk '{print $2}' || echo "unknown")"
OPENSSL_VER="$(openssl version 2>/dev/null | awk '{print $2}' || echo "unknown")"
JQ_VER="$(jq --version 2>/dev/null | sed 's/^jq-//' || echo "unknown")"

PYTHON_VER="not_found"
UNICODE_VER="not_found"
if command -v python3 >/dev/null 2>&1; then
  PYTHON_VER="$(python3 -c "import sys; print('.'.join(map(str, sys.version_info[:3])))" 2>/dev/null || echo "unknown")"
  UNICODE_VER="$(python3 -c "import unicodedata; print(unicodedata.unidata_version)" 2>/dev/null || echo "unknown")"
elif command -v python >/dev/null 2>&1; then
  PYTHON_VER="$(python -c "import sys; print('.'.join(map(str, sys.version_info[:3])))" 2>/dev/null || echo "unknown")"
  UNICODE_VER="$(python -c "import unicodedata; print(unicodedata.unidata_version)" 2>/dev/null || echo "unknown")"
fi

ACTIVE_LOCALE="${LC_ALL:-${LANG:-unknown}}"

RTT_MEDIAN_MS="null"

if [ -n "$TARGET_ENDPOINT" ] && [ "$TARGET_ENDPOINT" != "dry-run" ] && [ "$TARGET_ENDPOINT" != "local" ]; then
  [ "$QUIET_MODE" -eq 1 ] || printf 'env_telemetry: Misurazione baseline RTT verso %s (%d campioni)...\n' "$TARGET_ENDPOINT" "$RTT_SAMPLES" >&2

  BASE_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
  [ -d "$BASE_TMP" ] || BASE_TMP="/tmp"
  RTT_TMP_FILE="$(mktemp "${BASE_TMP%/}/rtt_XXXXXX" 2>/dev/null || mktemp "/tmp/rtt_XXXXXX")"
  : > "$RTT_TMP_FILE"

  for (( i=1; i<=RTT_SAMPLES; i++ )); do
    RTT_SEC=""
    if RTT_SEC="$(curl -s -S -o /dev/null -w "%{time_total}" --head --max-time 5 "$TARGET_ENDPOINT" 2>/dev/null)"; then
      if [ -n "$RTT_SEC" ] && [ "$(awk -v s="$RTT_SEC" 'BEGIN{print (s > 0.0001) ? 1 : 0}')" -eq 1 ]; then
        RTT_MS="$(awk -v sec="$RTT_SEC" 'BEGIN { printf "%.2f", sec * 1000 }')"
        printf '%s\n' "$RTT_MS" >> "$RTT_TMP_FILE"
      fi
    fi
    sleep 0.1 2>/dev/null || true
  done

  SAMPLE_COUNT="$(wc -l < "$RTT_TMP_FILE" 2>/dev/null | tr -d ' ' || echo 0)"
  if [ "${SAMPLE_COUNT:-0}" -gt 0 ]; then
    RTT_MEDIAN_MS="$(sort -n "$RTT_TMP_FILE" | awk '
      { arr[NR] = $1 }
      END {
        if (NR == 0) { print "null"; exit }
        if (NR % 2 == 1) {
          printf "%.2f", arr[(NR + 1) / 2]
        } else {
          printf "%.2f", (arr[NR / 2] + arr[(NR / 2) + 1]) / 2.0
        }
      }
    ')"
    [ "$QUIET_MODE" -eq 1 ] || printf 'env_telemetry: Baseline RTT calcolata: %s ms (su %d/%d validi)\n' "$RTT_MEDIAN_MS" "$SAMPLE_COUNT" "$RTT_SAMPLES" >&2
  else
    RTT_MEDIAN_MS="null"
    [ "$QUIET_MODE" -eq 1 ] || printf 'env_telemetry: AVVISO: Impossibile misurare RTT su %s. Impostato null.\n' "$TARGET_ENDPOINT" >&2
  fi
  rm -f "$RTT_TMP_FILE" 2>/dev/null || true
fi

TIMESTAMP_EPOCH="$(date +%s)"
TIMESTAMP_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

TELEMETRY_JSON="$(jq -c -n \
  --arg dev "$DEVICE_MODEL" \
  --arg and_ver "$ANDROID_VERSION" \
  --arg kern "$KERNEL_RELEASE" \
  --arg arch "$CPU_ARCH" \
  --arg bash_v "$BASH_VER" \
  --arg curl_v "$CURL_VER" \
  --arg ossl_v "$OPENSSL_VER" \
  --arg py_v "$PYTHON_VER" \
  --arg uax_v "$UNICODE_VER" \
  --arg jq_v "$JQ_VER" \
  --arg loc "$ACTIVE_LOCALE" \
  --argjson rtt "$RTT_MEDIAN_MS" \
  --argjson epoch "$TIMESTAMP_EPOCH" \
  --arg iso "$TIMESTAMP_ISO" \
  '{
    device_model: $dev,
    android_version: $and_ver,
    kernel_release: $kern,
    cpu_arch: $arch,
    bash_version: $bash_v,
    curl_version: $curl_v,
    openssl_version: $ossl_v,
    python_version: $py_v,
    unicodedata_version: $uax_v,
    jq_version: $jq_v,
    active_locale: $loc,
    rtt_baseline_ms: $rtt,
    timestamp_epoch_utc: $epoch,
    timestamp_iso_utc: $iso
  }')"

if [ -n "$OUTPUT_FILE" ]; then
  mkdir -p "$(dirname "$OUTPUT_FILE")" 2>/dev/null || true
  printf '%s\n' "$TELEMETRY_JSON" > "$OUTPUT_FILE"
  chmod 600 "$OUTPUT_FILE" 2>/dev/null || true
else
  printf '%s\n' "$TELEMETRY_JSON"
fi

exit 0
