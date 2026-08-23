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
#
# Nessun provider, modello o endpoint e' cablato: i parametri forniti dall'operatore
# vengono propagati intatti lungo l'intera catena di esecuzione.
# ==============================================================================

set -euo pipefail
umask 077

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

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
    if command -v less >/dev/null 2>&1 && [ -t 1 ]; then
      less -R "$HELP_FILE"
    else
      cat "$HELP_FILE"
    fi
  else
    cat <<'EOF'
+------------------------------------------------------------------------------+
|             CHANNEL DISCOVERY PROTOCOL (CDP/SOP v2.3) — MASTER CLI           |
+------------------------------------------------------------------------------+
USO RAPIDO:
  cdp run <TEST_ID> [OPZIONI]     Esegue un test (RUN0, T01..T14, ALL_FOUNDATIONAL, ALL).
  cdp summary [--out <FILE>]      Genera il Dossier di Campagna e Quadro Sinottico.
  cdp show [latest|RUN_ID]        Visualizza il referto SOTU dell'ultima sessione.
  cdp list [runs|tests]           Elenca le sessioni salvate o il catalogo test.
  cdp telemetry [--endpoint <URL>] Misura telemetria host e baseline RTT empirica.
  cdp stats binomial -k K -n N    Calcolo esatto Clopper-Pearson 95%.
  cdp stats paired-ttft --pairs-json <F>  Analisi differenze appaiate TTFT (T12).
  cdp stats power --mde M --pilot-sd S    Power analysis a priori per regime R2.
  cdp unicode "<STRINGA>"         Analisi UAX #15 e scomposizione codepoint.
  cdp status                      Verifica integrita e permessi del workspace (0700).
  cdp clean [tmp|all]             Pulizia sandbox temporanee o archivio sessioni.
  cdp -?, -h, --help, help        Mostra questa guida completa.
+------------------------------------------------------------------------------+
EOF
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
      printf 'cdp: ERRORE: Specificare il TEST_ID (es: cdp run RUN0, cdp run T01, cdp run ALL)\n' >&2
      printf 'Digita "cdp --help" per l'\''elenco completo dei comandi.\n' >&2
      exit 2
    fi
    TARGET_TEST="$1"
    shift
    bash "$WORKSPACE_DIR/cdp_run.sh" --test "$TARGET_TEST" "$@"
    ;;

  # ---------------------------------------------------------------------------
  # 2. GENERAZIONE DEL DOSSIER DI CAMPAGNA & QUADRO SINOTTICO COMPARATIVO
  # ---------------------------------------------------------------------------
  summary|dossier|synoptic)
    OUT_FILE="$WORKSPACE_DIR/DOSSIER_CAMPAGNA.md"
    while [ $# -gt 0 ]; do
      case "$1" in
        --out)
          [ $# -ge 2 ] || { printf 'cdp summary: ERRORE: --out richiede un percorso file\n' >&2; exit 2; }
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
    printf '\ncdp: Dossier di Campagna generato con successo in: %s\n' "$OUT_FILE"
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
        printf 'cdp: Nessuna sessione trovata in %s/runs/\n' "$WORKSPACE_DIR" >&2
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
        printf 'cdp: Sessione o file non trovato: %s\n' "$TARGET" >&2
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
      printf 'cdp: Referto SOTU non presente in: %s\n' "$(dirname "$REPORT_FILE")" >&2
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
        cat <<'EOF'
CATALOGO BATTERIA SPERIMENTALE CDP/SOP v2.3:
  RUN0 : Calibrazione Osservabilita V3 & Convalida Catena di Misura
  T01  : Transport Integrity & Canary Preservation (Ladder OFAT)
  T02  : Whitespace & Control Boundary Preservation
  T03  : Unicode Canonical & Compatibility Normalization (UAX #15)
  T04  : Invisible & Format Characters (ZWSP, ZWNJ, BOM)
  T05  : Cross-Turn State Recall Probe
  T06  : Cross-Session Persistence Phenotype
  T07  : Markup-Like User Data Interpretation
  T08  : Escape Sequences & Output Transformation
  T09  : Streaming Termination Protocol Characterization
  T10  : Cross-System Phenomenological Replication
  T11  : Token Accounting Discrepancy Probe
  T12  : Paired Latency & Observed TTFT Difference (Design Appaiato)
  T13  : Declared Prefix Caching Probe
  T14  : Long-Context Needle Retrieval (Matrice L x D)
EOF
        ;;
      runs)
        printf 'SESSIONI METROLOGICHE ARCHIVIATE IN %s/runs/:\n' "$WORKSPACE_DIR"
        if [ -d "$WORKSPACE_DIR/runs" ]; then
          COUNT=0
          while IFS= read -r r_dir; do
            [ -n "$r_dir" ] || continue
            COUNT=$((COUNT + 1))
            printf '  [%02d] %s\n' "$COUNT" "$r_dir"
          done < <(ls -1 "$WORKSPACE_DIR/runs" 2>/dev/null | grep '^RUN_' || true)
          [ "$COUNT" -eq 0 ] && printf '  (nessuna sessione presente)\n'
        else
          printf '  (directory runs/ non ancora creata)\n'
        fi
        ;;
      *)
        printf 'cdp list: Parametro non valido "%s". Valori ammessi: runs, tests\n' "$SUB" >&2
        exit 2
        ;;
    esac
    ;;

  # ---------------------------------------------------------------------------
  # 5. TELEMETRIA HOST & BASELINE RTT
  # ---------------------------------------------------------------------------
  telemetry)
    bash "$WORKSPACE_DIR/core/env_telemetry.sh" "$@"
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
      printf 'cdp unicode: Specificare la stringa da analizzare (es: cdp unicode "test")\n' >&2
      exit 2
    fi
    "$PYTHON_BIN" "$WORKSPACE_DIR/metrology/uax_engine.py" --text "$1"
    ;;

  # ---------------------------------------------------------------------------
  # 8. DIAGNOSTICA STATO DEL WORKSPACE & HARDENING PERMESSI (0700)
  # ---------------------------------------------------------------------------
  status)
    printf '+------------------------------------------------------------------------------+\n'
    printf '| CDP/SOP v2.3 — DIAGNOSTICA DI STATO DEL WORKSPACE                            |\n'
    printf '+------------------------------------------------------------------------------+\n'
    printf '  - Root Workspace : %s\n' "$WORKSPACE_DIR"
    printf '  - Python Runtime : %s (%s)\n' "$("$PYTHON_BIN" -V 2>&1)" "$(command -v "$PYTHON_BIN")"
    printf '  - SUT Wrapper    : '
    if [ -f "$WORKSPACE_DIR/bash4llm" ] || [ -f "$WORKSPACE_DIR/../bash4llm/bash4llm" ] || [ -f "$WORKSPACE_DIR/../bash4llm" ] || command -v bash4llm >/dev/null 2>&1; then
      printf 'RILEVATO (OK)\n'
    else
      printf 'NON TROVATO (Specificare con --bash4llm-bin <PATH>)\n'
    fi
    
    NUM_RUNS=0
    [ -d "$WORKSPACE_DIR/runs" ] && NUM_RUNS="$(ls -1d "$WORKSPACE_DIR/runs"/RUN_* 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
    printf '  - Sessioni Salve : %d run in runs/\n' "$NUM_RUNS"
    
    printf '  - Permessi File  : '
    chmod -R 700 "$WORKSPACE_DIR"/*.sh "$WORKSPACE_DIR"/core/*.sh "$WORKSPACE_DIR"/core/*.py "$WORKSPACE_DIR"/metrology/*.py "$WORKSPACE_DIR"/reporters/*.py 2>/dev/null || true
    printf 'VERIFICATI & APPLICATI (0700)\n'
    printf '+------------------------------------------------------------------------------+\n'
    ;;

  # ---------------------------------------------------------------------------
  # 9. MANUTENZIONE & PULIZIA
  # ---------------------------------------------------------------------------
  clean)
    TARGET_CLEAN="${1:-tmp}"
    case "$TARGET_CLEAN" in
      tmp)
        rm -rf "$WORKSPACE_DIR"/tmp/cdp_sut_* "${TMPDIR:-/tmp}"/cdp_sut_* 2>/dev/null || true
        printf 'cdp: Sandbox temporanee rimosse.\n'
        ;;
      all)
        printf 'cdp: ATTENZIONE: Questo eliminera TUTTE le sessioni in runs/. Confermare con "SI": '
        read -r CONFIRM
        if [ "$CONFIRM" = "SI" ]; then
          rm -rf "$WORKSPACE_DIR"/runs/RUN_* 2>/dev/null || true
          printf 'cdp: Tutte le sessioni in runs/ sono state eliminate.\n'
        else
          printf 'cdp: Operazione annullata.\n'
        fi
        ;;
      *)
        printf 'cdp clean: Parametro non valido "%s". Valori ammessi: tmp, all\n' "$TARGET_CLEAN" >&2
        exit 2
        ;;
    esac
    ;;

  *)
    printf 'cdp: ERRORE: Comando sconosciuto "%s".\n' "$CMD" >&2
    printf 'Digita "cdp --help" per visualizzare la guida completa.\n' >&2
    exit 2
    ;;
esac

exit 0
