#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# CDP Master CLI Gateway — Entrypoint Centralizzato per la Suite Metrologica
# File: cdp.sh
# Component: Core Orchestrator Gateway
# Standard: CDP v2.3 & SOP v2.3
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/channel-discovery-protocol/
# Contact: opensource@cevangel.anonaddy.me
# ==============================================================================
# Requirements: bash (>=4.0), coreutils, util-linux, curl, jq, openssl, python (>=3.10 stdlib)
#
# ==============================================================================
# GUIDA ARCHITETTURALE PER SVILUPPATORI (Gateway CLI & SUT Abstraction):
# ==============================================================================
# Questo script funge da interfaccia unificata di comando per l'intera suite:
#   - Instrada l'esecuzione dei test verso 'cdp_run.sh' (che a sua volta gestisce
#     l'invocazione del SUT tramite 'core/sut_adapter.sh' e 'bash4llm').
#   - Fornisce accesso diretto ai calcolatori metrologici (UAX #15, Clopper-Pearson).
#   - Compila e visualizza referti SOTU e il Dossier di Campagna comparativo.
#   - Esegue la diagnostica di integrita' e l'hardening dei permessi (0700).
#   - Integra una palette semantica ANSI sicura, conforme a NO_COLOR e con
#     decadimento trasparente a stringhe vuote se l'output e' reindirizzato.
#
# Nessun provider, modello o endpoint e' cablato: i parametri forniti dall'operatore
# vengono propagati intatti lungo l'intera catena di esecuzione.
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

# Risoluzione deterministica della root del workspace
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PYTHON_BIN="python3"
if ! command -v python3 >/dev/null 2>&1 && command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
fi

# Risoluzione percorso help.txt (docs/help.txt o root)
HELP_FILE=""
if [ -f "$WORKSPACE_DIR/docs/help.txt" ]; then
  HELP_FILE="$WORKSPACE_DIR/docs/help.txt"
elif [ -f "$WORKSPACE_DIR/help.txt" ]; then
  HELP_FILE="$WORKSPACE_DIR/help.txt"
fi

show_help() {
  if [ -n "$HELP_FILE" ] && [ -f "$HELP_FILE" ]; then
    if [ -n "${C_BCYAN:-}" ]; then
      sed \
        -e "s/^\([A-Za-z0-9][A-Za-z0-9[:blank:]&]*:\)/${C_BCYAN}\1${C_RST}/" \
        -e "s/\(--[a-zA-Z0-9-][a-zA-Z0-9-]*\)/${C_BGREEN}\1${C_RST}/g" \
        -e "s/\(<[a-zA-Z0-9_]\{1,\}>\)/${C_YELLOW}\1${C_RST}/g" \
        -e "s/\(\$[[:blank:]]*cdp[[:blank:]][^$]*\)/${C_BOLD}${C_GREEN}\1${C_RST}/g" \
        -e "s/\(RUN0\)/${C_BMAGENTA}\1${C_RST}/g" \
        -e "s/\(T[0-9][0-9]\)/${C_BCYAN}\1${C_RST}/g" \
        -e "s/\(========================================\)/${C_BMAGENTA}\1${C_RST}/g" \
        -e "s/\(----------------------------------------\)/${C_BBLACK}\1${C_RST}/g" \
        "$HELP_FILE"
    else
      cat "$HELP_FILE"
    fi
  else
    printf '%b' "${C_BMAGENTA}========================================${C_RST}
${C_BOLD}CHANNEL DISCOVERY PROTOCOL (CDP/SOP v2.3)${C_RST}
${C_BYELLOW}GUIDA RAPIDA DI EMERGENZA${C_RST}
${C_BMAGENTA}========================================${C_RST}
USO:
  ${C_BGREEN}cdp run <TEST_ID> [OPZIONI]${C_RST}
    Opzioni principali:
      --pacing <SEC>       Intervallo di sicurezza in secondi per rate limits (default: 4).
      --regime <REGIME>    pilot (N=5) | confirmatory (N=20).
      --provider <NAME>    Provider target (es. gemini, groq, mistral).
      --model <MODEL_ID>   Model ID esplicito.
      --dry-run            Simulazione locale senza traffico di rete.

  ${C_BGREEN}cdp summary [--out <FILE>]${C_RST}      Genera Dossier di Campagna comparativo.
  ${C_BGREEN}cdp show [latest|RUN_ID]${C_RST}        Visualizza Referto Master SOTU v2.3.
  ${C_BGREEN}cdp list [runs|tests]${C_RST}           Elenca sessioni archiviate o catalogo test.
  ${C_BGREEN}cdp telemetry [--endpoint <URL>]${C_RST} Sonda telemetrica host e stima baseline RTT.
  ${C_BGREEN}cdp stats <binomial|paired-ttft|power>${C_RST} Calcolatore statistico metrologico.
  ${C_BGREEN}cdp unicode \"<STRINGA>\"${C_RST}          Analisi Unicode UAX #15 e forme normalizzate.
  ${C_BGREEN}cdp status${C_RST}                      Diagnostica workspace e permessi.
  ${C_BGREEN}cdp clean [tmp|all]${C_RST}             Pulizia sandbox temporanee o archivio runs.
${C_BMAGENTA}========================================${C_RST}
"
  fi
  exit 0
}

# Gestione immediata dei flag di help globali
if [ $# -eq 0 ]; then
  show_help
fi

case "$1" in
  -\?|-h|--help|help)
    show_help
    ;;
esac

CMD="$1"
shift

case "$CMD" in
  # ---------------------------------------------------------------------------
  # 1. ESECUZIONE DEI TEST METROLOGICI (Orchestrazione via cdp_run.sh)
  # ---------------------------------------------------------------------------
  run|test)
    if [ $# -eq 0 ]; then
      printf '%scdp: ERRORE: Specificare il TEST_ID (es: cdp run RUN0, cdp run T01, cdp run ALL)%s\n' "${C_BRED}" "${C_RST}" >&2
      printf 'Digita "%scdp --help%s" per l'\''elenco completo dei comandi.\n' "${C_BGREEN}" "${C_RST}" >&2
      exit 2
    fi

    # Parsing flessibile degli argomenti per estrarre il target test indipendentemente dalla posizione
    TARGET_TEST=""
    FORWARD_ARGS=()

    while [ $# -gt 0 ]; do
      case "$1" in
        --test)
          [ $# -ge 2 ] || { printf '%scdp run: ERRORE: --test richiede un ID%s\n' "${C_BRED}" "${C_RST}" >&2; exit 2; }
          TARGET_TEST="$2"
          shift 2
          ;;
        --pacing|--regime|--provider|--model|--endpoint|--mde|--bash4llm-bin|--vault-ctx)
          [ $# -ge 2 ] || { printf '%scdp run: ERRORE: %s richiede un argomento%s\n' "${C_BRED}" "$1" "${C_RST}" >&2; exit 2; }
          FORWARD_ARGS+=( "$1" "$2" )
          shift 2
          ;;
        --dry-run|--debug|--no-color)
          FORWARD_ARGS+=( "$1" )
          shift
          ;;
        -h|--help)
          show_help
          ;;
        -*)
          FORWARD_ARGS+=( "$1" )
          shift
          ;;
        *)
          if [ -z "$TARGET_TEST" ]; then
            TARGET_TEST="$1"
          else
            FORWARD_ARGS+=( "$1" )
          fi
          shift
          ;;
      esac
    done

    if [ -z "$TARGET_TEST" ]; then
      TARGET_TEST="RUN0"
    fi

    bash "$WORKSPACE_DIR/cdp_run.sh" --test "$TARGET_TEST" "${FORWARD_ARGS[@]}"
    ;;

  # ---------------------------------------------------------------------------
  # 2. GENERAZIONE DEL DOSSIER DI CAMPAGNA & QUADRO SINOTTICO COMPARATIVO
  # ---------------------------------------------------------------------------
  summary|dossier|synoptic)
    OUT_FILE="$WORKSPACE_DIR/DOSSIER_CAMPAGNA.md"
    while [ $# -gt 0 ]; do
      case "$1" in
        --out)
          [ $# -ge 2 ] || { printf '%scdp summary: ERRORE: --out richiede un percorso file%s\n' "${C_BRED}" "${C_RST}" >&2; exit 2; }
          OUT_FILE="$2"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    "$PYTHON_BIN" "$WORKSPACE_DIR/reporters/campaign_dashboard.py" \
      --runs-dir "$WORKSPACE_DIR/runs" \
      --out "$OUT_FILE"
    printf '\n%scdp: Dossier di Campagna generato con successo in: %s%s%s\n' "${C_BGREEN}" "${C_BOLD}${C_BWHITE}" "$OUT_FILE" "${C_RST}"
    ;;

  # ---------------------------------------------------------------------------
  # 3. VISUALIZZAZIONE REFERTI SOTU MASTER
  # ---------------------------------------------------------------------------
  show|view)
    TARGET="${1:-latest}"
    REPORT_FILE=""
    if [ "$TARGET" = "latest" ]; then
      LATEST_DIR="$(ls -td "$WORKSPACE_DIR/runs"/RUN_* 2>/dev/null | head -n 1 || true)"
      if [ -z "$LATEST_DIR" ] || [ ! -d "$LATEST_DIR" ]; then
        printf '%scdp: Nessuna sessione trovata in %s/runs/%s\n' "${C_BYELLOW}" "$WORKSPACE_DIR" "${C_RST}" >&2
        exit 1
      fi
      REPORT_FILE="$LATEST_DIR/SOTU_MASTER_REPORT.md"
    else
      if [ -d "$WORKSPACE_DIR/runs/$TARGET" ]; then
        REPORT_FILE="$WORKSPACE_DIR/runs/$TARGET/SOTU_MASTER_REPORT.md"
      elif [ -f "$TARGET" ]; then
        REPORT_FILE="$TARGET"
      elif [ -f "$WORKSPACE_DIR/$TARGET" ]; then
        REPORT_FILE="$WORKSPACE_DIR/$TARGET"
      else
        printf '%scdp: Sessione o file non trovato: %s%s\n' "${C_BRED}" "$TARGET" "${C_RST}" >&2
        exit 1
      fi
    fi

    if [ -f "$REPORT_FILE" ]; then
      if command -v less >/dev/null 2>&1 && [ -t 1 ]; then
        less -R "$REPORT_FILE"
      else
        cat "$REPORT_FILE"
      fi
    else
      printf '%scdp: Referto SOTU non presente in: %s%s\n' "${C_BRED}" "$(dirname "$REPORT_FILE")" "${C_RST}" >&2
      exit 1
    fi
    ;;

  # ---------------------------------------------------------------------------
  # 4. ELENCO SESSIONI E CATALOGO TEST DISPONIBILI
  # ---------------------------------------------------------------------------
  list)
    SUB="${1:-runs}"
    case "$SUB" in
      tests)
        printf '%b' "${C_BMAGENTA}========================================${C_RST}
${C_BOLD}CATALOGO BATTERIA SPERIMENTALE CDP/SOP v2.3${C_RST}
${C_BMAGENTA}========================================${C_RST}
  ${C_BMAGENTA}RUN0${C_RST} : Calibrazione Osservabilita V3 (Obbligatoria)
  ${C_BGREEN}T01${C_RST}  : Transport Integrity & Canary Preservation
  ${C_BGREEN}T02${C_RST}  : Whitespace & Control Boundary Preservation
  ${C_BGREEN}T03${C_RST}  : Unicode Canonical & Compatibility Normalization
  ${C_BGREEN}T04${C_RST}  : Invisible & Format Characters (ZWSP, BOM)
  ${C_BBLUE}T05${C_RST}  : Cross-Turn State Recall Probe
  ${C_BBLUE}T06${C_RST}  : Cross-Session Persistence Phenotype
  ${C_BBLUE}T07${C_RST}  : Markup-Like User Data Interpretation
  ${C_BBLUE}T08${C_RST}  : Escape Sequences & Output Transformation
  ${C_BBLUE}T09${C_RST}  : Streaming Termination Protocol
  ${C_BBLUE}T10${C_RST}  : Cross-System Phenomenological Replication
  ${C_BYELLOW}T11${C_RST}  : Token Accounting Discrepancy Probe
  ${C_BYELLOW}T12${C_RST}  : Paired Latency & Observed TTFT Difference
  ${C_BYELLOW}T13${C_RST}  : Declared Prefix Caching Probe
  ${C_BYELLOW}T14${C_RST}  : Long-Context Needle Retrieval (L x D)
${C_BBLACK}----------------------------------------${C_RST}
  ${C_BCYAN}ALL_FOUNDATIONAL${C_RST} : Sequenza RUN0..T04
  ${C_BCYAN}ALL${C_RST}              : Batteria completa RUN0..T14
${C_BMAGENTA}========================================${C_RST}
"
        ;;
      runs)
        printf '%b' "${C_BMAGENTA}========================================${C_RST}
${C_BOLD}SESSIONI ARCHIVIATE IN runs/:${C_RST}
${C_BMAGENTA}========================================${C_RST}
"
        if [ -d "$WORKSPACE_DIR/runs" ]; then
          COUNT=0
          while IFS= read -r r_dir; do
            [ -n "$r_dir" ] || continue
            COUNT=$((COUNT + 1))
            printf '  [%s%02d%s] %s%s%s\n' "${C_BBLACK}" "$COUNT" "${C_RST}" "${C_BCYAN}" "$r_dir" "${C_RST}"
          done < <(ls -1 "$WORKSPACE_DIR/runs" 2>/dev/null | grep '^RUN_' || true)
          [ "$COUNT" -eq 0 ] && printf '  %s(nessuna sessione presente)%s\n' "${C_DIM}${C_YELLOW}" "${C_RST}"
        else
          printf '  %s(directory runs/ non ancora creata)%s\n' "${C_DIM}${C_YELLOW}" "${C_RST}"
        fi
        printf '%b' "${C_BMAGENTA}========================================${C_RST}\n"
        ;;
      *)
        printf '%scdp list: Parametro non valido "%s". Valori ammessi: runs, tests%s\n' "${C_BRED}" "$SUB" "${C_RST}" >&2
        exit 2
        ;;
    esac
    ;;

  # ---------------------------------------------------------------------------
  # 5. TELEMETRIA HOST & BASELINE RTT
  # ---------------------------------------------------------------------------
  telemetry)
    if [ $# -gt 0 ] && [[ "$1" != --* ]]; then
      bash "$WORKSPACE_DIR/core/env_telemetry.sh" --endpoint "$1" "${@:2}"
    else
      bash "$WORKSPACE_DIR/core/env_telemetry.sh" "$@"
    fi
    ;;

  # ---------------------------------------------------------------------------
  # 6. CALCOLATORE STATISTICO STANDALONE (cdp_stats.py)
  # ---------------------------------------------------------------------------
  stats)
    "$PYTHON_BIN" "$WORKSPACE_DIR/metrology/cdp_stats.py" "$@"
    ;;

  # ---------------------------------------------------------------------------
  # 7. ISPEZIONE UNICODE DIRETTA (uax_engine.py)
  # ---------------------------------------------------------------------------
  unicode)
    if [ $# -eq 0 ]; then
      printf '%scdp unicode: Specificare la stringa da analizzare (es: cdp unicode "test")%s\n' "${C_BRED}" "${C_RST}" >&2
      exit 2
    fi
    "$PYTHON_BIN" "$WORKSPACE_DIR/metrology/uax_engine.py" "$@"
    ;;

  # ---------------------------------------------------------------------------
  # 8. DIAGNOSTICA STATO DEL WORKSPACE & HARDENING PERMESSI (0700)
  # ---------------------------------------------------------------------------
  status)
    printf '%b' "${C_BMAGENTA}========================================${C_RST}
${C_BOLD}CDP/SOP v2.3 — DIAGNOSTICA DI STATO${C_RST}
${C_BMAGENTA}========================================${C_RST}
"
    printf '  - Root Workspace : %s%s%s\n' "${C_BCYAN}" "$WORKSPACE_DIR" "${C_RST}"
    printf '  - Python Runtime : %s (%s)\n' "$("$PYTHON_BIN" -V 2>&1)" "$(command -v "$PYTHON_BIN")"
    printf '  - SUT Wrapper    : '
    if [ -f "$WORKSPACE_DIR/bash4llm" ] || [ -f "$WORKSPACE_DIR/../bash4llm/bash4llm" ] || [ -f "$WORKSPACE_DIR/../bash4llm" ] || command -v bash4llm >/dev/null 2>&1; then
      printf '%sRILEVATO (OK)%s\n' "${C_BGREEN}" "${C_RST}"
    else
      printf '%sNON TROVATO (Specificare con --bash4llm-bin <PATH>)%s\n' "${C_BYELLOW}" "${C_RST}"
    fi
    
    NUM_RUNS=0
    [ -d "$WORKSPACE_DIR/runs" ] && NUM_RUNS="$(ls -1d "$WORKSPACE_DIR/runs"/RUN_* 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
    printf '  - Sessioni Salve : %s%d run%s in runs/\n' "${C_BOLD}${C_BWHITE}" "$NUM_RUNS" "${C_RST}"
    
    printf '  - Permessi File  : '
    chmod -R 700 "$WORKSPACE_DIR"/*.sh "$WORKSPACE_DIR"/core/*.sh "$WORKSPACE_DIR"/core/*.py "$WORKSPACE_DIR"/metrology/*.py "$WORKSPACE_DIR"/reporters/*.py 2>/dev/null || true
    printf '%sVERIFICATI & APPLICATI (0700)%s\n' "${C_BGREEN}" "${C_RST}"
    printf '%b' "${C_BMAGENTA}========================================${C_RST}\n"
    ;;

  # ---------------------------------------------------------------------------
  # 9. MANUTENZIONE & PULIZIA
  # ---------------------------------------------------------------------------
  clean)
    TARGET_CLEAN="${1:-tmp}"
    case "$TARGET_CLEAN" in
      tmp)
        rm -rf "$WORKSPACE_DIR"/tmp/cdp_sut_* "${TMPDIR:-/tmp}"/cdp_sut_* 2>/dev/null || true
        printf '%scdp: Sandbox temporanee rimosse.%s\n' "${C_BGREEN}" "${C_RST}"
        ;;
      all)
        printf '%s%scdp: ATTENZIONE: Questo eliminera TUTTE le sessioni in runs/. Confermare con "SI": %s' "${C_BOLD}" "${C_BRED}" "${C_RST}"
        read -r CONFIRM
        if [ "$CONFIRM" = "SI" ]; then
          rm -rf "$WORKSPACE_DIR"/runs/RUN_* 2>/dev/null || true
          printf '%scdp: Tutte le sessioni in runs/ sono state eliminate.%s\n' "${C_BGREEN}" "${C_RST}"
        else
          printf '%scdp: Operazione annullata.%s\n' "${C_BYELLOW}" "${C_RST}"
        fi
        ;;
      *)
        printf '%scdp clean: Parametro non valido "%s". Valori ammessi: tmp, all%s\n' "${C_BRED}" "$TARGET_CLEAN" "${C_RST}" >&2
        exit 2
        ;;
    esac
    ;;

  *)
    printf '%scdp: ERRORE: Comando sconosciuto "%s".%s\n' "${C_BRED}" "$CMD" "${C_RST}" >&2
    printf 'Digita "%scdp --help%s" per visualizzare la guida completa.\n' "${C_BGREEN}" "${C_RST}" >&2
    exit 2
    ;;
esac

exit 0
