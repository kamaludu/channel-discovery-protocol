#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# CDP/SOP v2.3 METROLOGY HARNESS — Campaign Dashboard & Decay Curve Generator
# File: reporters/campaign_dashboard.py
# Component: Multi-Session Campaign Dashboard & Synoptic Reporter
# Standard: CDP v2.3 (Sez. 4, 10) & SOP v2.3 (Sez. 5 T12, T14)
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/channel-discovery-protocol/
# Contact: opensource@cevangel.anonaddy.me
# ==============================================================================
# Requirements: python (>=3.10), strictly standard library (zero-pip dependencies)
#
# ==============================================================================
# GUIDA ARCHITETTURALE PER SVILUPPATORI (Campaign Reporting Abstraction):
# ==============================================================================
# Questo modulo scansiona l'archivio sessioni in 'runs/' e compila il Dossier
# Esecutivo e Quadro Sinottico di Campagna:
#   1. Aggrega i dati multi-sessione e multi-SUT (Provider, Model ID, Regime).
#   2. Costruisce la Tabella Comparativa Globale con metriche Clopper-Pearson/TTFT
#      e Vettori di Evidenza E.
#   3. Genera la Matrice 2D di Decadimento (L x D) e il grafico ASCII Heatmap
#      per il test T14 (Long-Context Needle Retrieval).
#
# Nessun provider o modello e' cablato: le sessioni con metadati non risolti
# vengono correttamente identificate come 'UNRESOLVED' o 'NOT_OBSERVED'.
# ==============================================================================

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Set


def render_ascii_bar(rate: float, width: int = 15) -> str:
    """Genera una barra visiva in puro ASCII per tassi da 0.0 a 1.0."""
    clamped_rate = max(0.0, min(1.0, rate))
    filled = int(round(clamped_rate * width))
    empty = width - filled
    pct = int(round(clamped_rate * 100))
    return f"[{'#' * filled}{'.' * empty}] {pct:>3d}%"


class CampaignDashboard:
    """
    Motore di scansione, aggregazione e compilazione del Dossier di Campagna CDP/SOP v2.3.
    """

    def __init__(self, runs_dir: Path):
        self.runs_dir = runs_dir
        self.sessions_data: List[Dict[str, Any]] = []
        self._load_all_runs()

    def _load_all_runs(self):
        """Scansiona la directory runs/ e carica tutti i manifest e referti disponibili."""
        if not self.runs_dir.exists():
            return

        run_folders = sorted(self.runs_dir.glob("RUN_*"))
        for rf in run_folders:
            if not rf.is_dir():
                continue

            manifest_file = rf / "run_manifest.json"
            class_file = rf / "claim_classification.json"
            metrics_file = rf / "metrics_summary.json"
            stimulus_file = rf / "stimulus_meta.json"

            if manifest_file.exists() and class_file.exists():
                try:
                    manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
                    classification = json.loads(class_file.read_text(encoding="utf-8"))
                    metrics = json.loads(metrics_file.read_text(encoding="utf-8")) if metrics_file.exists() else {}
                    stimulus = json.loads(stimulus_file.read_text(encoding="utf-8")) if stimulus_file.exists() else {}

                    self.sessions_data.append({
                        "run_id": rf.name,
                        "manifest": manifest,
                        "classification": classification,
                        "metrics": metrics,
                        "stimulus": stimulus,
                        "path": rf
                    })
                except Exception as e:
                    sys.stderr.write(f"campaign_dashboard: AVVISO: Impossibile leggere {rf.name}: {e}\n")

    def generate_comparative_summary_table(self) -> str:
        """Costruisce la tabella comparativa di sintesi per tutte le sessioni archiviate."""
        if not self.sessions_data:
            return "Nessuna sessione di test rilevata in runs/."

        lines = []
        lines.append("### TABELLA COMPARATIVA DI SINTESI DELLE SESSIONI SPERIMENTALI")
        lines.append("")
        lines.append("| Test ID | Provider | Model ID | Regime | ORR_b / Latency | CI 95% (Esatto) | Vettore di Evidenza | Verdetto Metrologico |")
        lines.append("| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |")

        for s in self.sessions_data:
            manifest = s.get("manifest", {})
            classification = s.get("classification", {})
            metrics = s.get("metrics", {})

            t_id = manifest.get("test_id", "UNRESOLVED")
            sut = manifest.get("sut_formal_tuple", {}) or {}
            prov = sut.get("provider") or "UNRESOLVED"
            model = sut.get("model_id") or "UNRESOLVED"
            regime = manifest.get("regime", "R1_PILOT")

            # Metriche statistiche
            if t_id == "T12":
                bar_d = metrics.get("point_estimate_bar_D_ms", "N/A")
                ci_str = metrics.get("primary_parametric_ci_95", {}).get("formatted", "N/A")
                orr_str = f"bar_D={bar_d}ms" if bar_d is not None else "N/A"
            else:
                orr_val = metrics.get("point_estimate_ORR_b", classification.get("point_estimate_ORR_b"))
                orr_str = f"{orr_val:.4f}" if isinstance(orr_val, (int, float)) else "N/A"
                ci_block = metrics.get("confidence_interval_95_clopper_pearson", {}) or {}
                lower = ci_block.get("lower")
                upper = ci_block.get("upper")
                if lower is not None and upper is not None:
                    ci_str = f"[{lower:.4f}, {upper:.4f}]"
                else:
                    ci_str = "N/A"

            vector = classification.get("final_evidence_vector", "NOT_OBSERVED")
            verdict = classification.get("final_verdict", "NOT_OBSERVED")

            # Troncamento per rendering Markdown compatto
            model_short = (model[:22] + "..") if len(model) > 24 else model
            verdict_short = verdict.replace("_", " ")

            lines.append(f"| **{t_id}** | `{prov}` | `{model_short}` | {regime} | **{orr_str}** | {ci_str} | `{vector}` | {verdict_short} |")

        lines.append("")
        return "\n".join(lines)

    def generate_t14_decay_matrix(self) -> str:
        """
        Costruisce la matrice di decadimento 2D (L x D) e il profilo grafico ASCII
        per le sessioni del test T14 (Long-Context Needle Retrieval).
        """
        t14_sessions = [s for s in self.sessions_data if s.get("manifest", {}).get("test_id") == "T14"]
        if not t14_sessions:
            return "Nessuna sessione T14 (Long-Context Retrieval) registrata nell'archivio runs/."

        lines = []
        lines.append("### CURVE E MATRICE DI DECADIMENTO LONG-CONTEXT (TEST T14)")
        lines.append("")
        lines.append("Il mensurando formale e' il tasso empirico di recupero del needle: `Retrieval_Rate(L, D)`.")
        lines.append("- `L`: Lunghezza totale del contesto in k-token (es. 4k, 8k, 16k, 32k, 64k, 128k).")
        lines.append("- `D`: Profondita' relativa di inserimento del needle nell'intervallo [0.0, 1.0] (0.0 = testa, 0.5 = centro, 1.0 = coda).")
        lines.append("")

        # Raggruppamento per SUT formale (Provider / Model)
        sut_groups: Dict[str, List[Dict[str, Any]]] = {}
        for s in t14_sessions:
            sut = s.get("manifest", {}).get("sut_formal_tuple", {}) or {}
            prov = sut.get("provider") or "UNRESOLVED"
            model = sut.get("model_id") or "UNRESOLVED"
            key = f"{prov} / {model}"
            sut_groups.setdefault(key, []).append(s)

        for sut_name, sessions in sut_groups.items():
            lines.append(f"#### Target SUT: `{sut_name}`")
            lines.append("")

            # Costruzione griglia dati (L, D) -> rate
            grid: Dict[int, Dict[float, float]] = {}
            all_lengths: Set[int] = set()
            all_depths: Set[float] = set()

            for s in sessions:
                stim = s.get("stimulus", {}) or {}
                metrics = s.get("metrics", {}) or {}
                l_val = int(stim.get("length_k", 4))
                d_val = float(stim.get("depth", 0.5))
                rate_val = metrics.get("point_estimate_ORR_b")
                rate = float(rate_val) if isinstance(rate_val, (int, float)) else 0.0

                all_lengths.add(l_val)
                all_depths.add(d_val)
                grid.setdefault(l_val, {})[d_val] = rate

            sorted_lengths = sorted(all_lengths)
            sorted_depths = sorted(all_depths)

            # 1. Matrice Tabellare 2D
            lines.append("**Matrice di Accuratezza Retrieval_Rate(L, D):**")
            lines.append("")
            header_depths = " | ".join(f"D = {d:.2f}" for d in sorted_depths)
            sep_depths = " | ".join(":---:" for _ in sorted_depths)
            lines.append(f"| Lunghezza Contesto (L) | {header_depths} |")
            lines.append(f"| :--- | {sep_depths} |")

            for l_len in sorted_lengths:
                row_cells = []
                for d_depth in sorted_depths:
                    val = grid.get(l_len, {}).get(d_depth, None)
                    if val is not None:
                        pct = int(round(val * 100))
                        row_cells.append(f"**{pct}%**")
                    else:
                        row_cells.append("-")
                lines.append(f"| **{l_len}k token** | {' | '.join(row_cells)} |")

            lines.append("")

            # 2. Visualizzazione Grafica in Puro ASCII (Heatmap a Blocchi)
            lines.append("**Profilo Visivo di Decadimento (ASCII Heatmap):**")
            lines.append("```text")
            lines.append("+------------------------------------------------------------------------------+")
            lines.append(f"| PROFILO DI RETRIEVAL NEEDLE (L x D) — SUT: {sut_name:<33} |")
            lines.append("+------------------------------------------------------------------------------+")
            for l_len in sorted_lengths:
                lines.append(f"  Lunghezza L = {l_len:>3d}k token:")
                for d_depth in sorted_depths:
                    val = grid.get(l_len, {}).get(d_depth, 0.0)
                    bar = render_ascii_bar(val, width=15)
                    lines.append(f"    Profondita D = {d_depth:.2f} ({(d_depth*100):>3.0f}%):  {bar}")
                lines.append("  " + "-" * 76)
            lines.append("```")
            lines.append("")

        return "\n".join(lines)

    def render_full_dashboard(self) -> str:
        """Compila il documento Markdown completo del Dossier esecutivo."""
        now_utc = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
        doc = []
        doc.append("# CDP/SOP v2.3 — DOSSIER ESECUTIVO E SINTESI METROLOGICA")
        doc.append(f"**Data e Ora Aggiornamento:** `{now_utc}` | **Ambiente:** `Android/Termux (Zero-PIP)`")
        doc.append("")
        doc.append("---")
        doc.append("")
        doc.append(self.generate_comparative_summary_table())
        doc.append("---")
        doc.append("")
        doc.append(self.generate_t14_decay_matrix())
        doc.append("---")
        doc.append("")
        doc.append("### REGOLE METROLOGICHE DI INTERPRETAZIONE")
        doc.append("1. **`ORR_b == 1.00`:** Conformita' fenomenologica perfetta sui confini strumentati.")
        doc.append("2. **`Proxy != Meccanismo`:** Il tasso di successo attesta la preservazione dell'informazione, non la struttura dei pesi interni.")
        doc.append("3. **Decadimento su T14:** Tassi inferiori a 1.00 indicano degradazione comportamentale del contesto (UNDERDETERMINED tra saturazione posizionale e bias attentivo).")
        doc.append("")
        return "\n".join(doc)


def main():
    parser = argparse.ArgumentParser(
        description="CDP/SOP v2.3 Campaign Dashboard & Decay Curve Generator"
    )
    parser.add_argument("--runs-dir", default="./runs", help="Directory dei run (default: ./runs)")
    parser.add_argument("--out", default=None, help="File Markdown di output (default: stdout)")
    args = parser.parse_args()

    runs_path = Path(args.runs_dir)
    dashboard = CampaignDashboard(runs_path)
    report_md = dashboard.render_full_dashboard()

    if args.out:
        out_p = Path(args.out)
        out_p.parent.mkdir(parents=True, exist_ok=True)
        out_p.write_text(report_md, encoding="utf-8")
        out_p.chmod(0o600)
        sys.stderr.write(f"campaign_dashboard: Dossier salvato con successo in: {out_p}\n")
    else:
        sys.stdout.write(report_md + "\n")


if __name__ == "__main__":
    main()
