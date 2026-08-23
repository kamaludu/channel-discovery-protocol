#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# CDP Decision Engine — Deterministic Decision DAG & Differential Claim Classifier
# File: metrology/claim_classifier.py
# Component: Epistemic Decision Engine (Ruling H1-H5)
# Standard: CDP v2.3 (Sez. 0, 2, 4, 6, 10) & SOP v2.3 (Sez. 2.2, 2.3, 4.1, 7)
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/channel-discovery-protocol/
# Contact: opensource@cevangel.anonaddy.me
# ==============================================================================
# Requirements: python (>=3.10), strictly standard library (zero-pip dependencies)
#
# ==============================================================================
# GUIDA ARCHITETTURALE PER SVILUPPATORI (SUT / Invocator Agnostic):
# ==============================================================================
# Questo modulo implementa il Decision DAG deterministico per la classificazione
# epistemica dei claim e la diagnosi differenziale delle ipotesi causali (H1-H5).
# 
# Riceve in input gli artefatti metrologici formalizzati generati dall'adapter
# (trial_metadata.json) e dal motore statistico (metrics_summary.json):
#   - Valuta i confini di osservabilita' raggiunti (O0..O3).
#   - Genera il Vettore Formale di Evidenza: E = < O_x, C_x, R_x, S_x >.
#   - Applica il principio epistemico "Strength(Claim) <= Strength(Evidence)"
#     e "Proxy != Meccanismo" (H2-H5 UNDERDETERMINED su black-box API).
#   - Integra determinismo statistico: il verdetto di sessione riflette
#     l'autorita' formale di metrics_summary.json (Clopper-Pearson / Paired TTFT).
# ==============================================================================

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional


class ClaimClassifier:
    """
    Motore deterministico di classificazione dei claim metrologici e diagnosi differenziale.
    """

    @staticmethod
    def format_evidence_vector(o_level: str, c_level: str, r_level: str, s_level: str) -> str:
        """Formatta la quadrupla canonica del vettore di evidenza E."""
        return f"E = < {o_level}, {c_level}, {r_level}, {s_level} >"

    @classmethod
    def evaluate_single_trial(
        cls,
        trial_metadata: Dict[str, Any],
        comparison_criterion: str = "M1-scalar",
        regime: str = "R1_PILOT"
    ) -> Dict[str, Any]:
        """
        Valuta un singolo trial sperimentale sulla base del DAG di provenienza e dei predicati V3.
        """
        eval_block = trial_metadata.get("evaluation", {})
        audit_block = trial_metadata.get("audit_trail", {})
        dag_block = trial_metadata.get("provenance_dag", {})

        trial_class = eval_block.get("trial_classification", "FAILED_TRIAL")
        output_provenance = eval_block.get("output_provenance", "UNKNOWN")
        v3_class = audit_block.get("v3_classification", "V3-0a (No-Capture)")

        u_sha = dag_block.get("stimulus_intended_sha256")
        req_u_sha = dag_block.get("c_req_unicode_sha256")
        out_sha = dag_block.get("output_parsed_sha256")

        r_scope = "R1" if "R1" in regime else ("R2" if "R2" in regime else "R0")

        # CASO 1: TRIAL INVALIDO O FALLITO
        if trial_class in ["INVALID_STIMULUS", "INVALID_ENVIRONMENT", "FAILED_TRIAL"]:
            return {
                "verdict_status": "INVALID",
                "evidence_status": "NOT SUPPORTED",
                "identification_status": "NOT IDENTIFIED",
                "observed_boundary": "O0",
                "evidence_vector": cls.format_evidence_vector("O0", "C0", r_scope, "S0"),
                "hypotheses_evaluation": {
                    "H1_client": "NOT DETERMINED",
                    "H2_server_pre_context": "NOT DETERMINED",
                    "H3_tokenizer": "NOT DETERMINED",
                    "H4_model_core": "NOT DETERMINED",
                    "H5_post_render": "NOT DETERMINED"
                },
                "epistemic_notes": "Trial non valido a causa di anomalie ambientali, di stimolo o fallimento SUT."
            }

        # CASO 2: MODALITÀ B (Black-Box Pura / V3 Non Catturato)
        if "V3-3" not in v3_class:
            if output_provenance in ["VERIFIED", "ATTRIBUTED"] and out_sha is not None:
                is_match = (u_sha == out_sha)
                ev_status = "SUPPORTED" if is_match else "SUPPORTED (Divergence Observed)"
                return {
                    "verdict_status": "VALID_BEHAVIORAL_ONLY",
                    "evidence_status": ev_status,
                    "identification_status": "NOT IDENTIFIED",
                    "observed_boundary": "O1 (U -> O)",
                    "evidence_vector": cls.format_evidence_vector("O1", "C0", r_scope, "S1"),
                    "hypotheses_evaluation": {
                        "H1_client": "UNDERDETERMINED (Not observed at transport boundary)",
                        "H2_server_pre_context": "NOT OBSERVED",
                        "H3_tokenizer": "NOT OBSERVED",
                        "H4_model_core": "NOT OBSERVED",
                        "H5_post_render": "NOT OBSERVED"
                    },
                    "epistemic_notes": (
                        "Relazione comportamentale U -> O osservata in Modalita B. "
                        "Nessuna asserzione di localizzazione o meccanismo interno e' formalmente ammessa."
                    )
                }
            else:
                return {
                    "verdict_status": "OUTPUT_OBSERVED_UNATTRIBUTED",
                    "evidence_status": "NOT SUPPORTED",
                    "identification_status": "NOT IDENTIFIED",
                    "observed_boundary": "O0",
                    "evidence_vector": cls.format_evidence_vector("O0", "C0", r_scope, "S0"),
                    "hypotheses_evaluation": {},
                    "epistemic_notes": "Output orfano o non associabile univocamente alla sessione di prova."
                }

        # CASO 3: MODALITÀ A (Layer V3-3 Verificato sul Confine Applicativo)
        effective_req_sha = req_u_sha if req_u_sha else dag_block.get("c_req_app_bytes_sha256")
        diff_u_req = (u_sha != effective_req_sha) if (u_sha and effective_req_sha) else False
        diff_req_out = (effective_req_sha != out_sha) if (effective_req_sha and out_sha) else True

        # Sottocaso 3A: Mutazione Pre-Trasporto (U != C_req_unicode)
        if diff_u_req:
            return {
                "verdict_status": "LOCAL_PRE_TRANSPORT_MUTATION",
                "evidence_status": "SUPPORTED",
                "identification_status": "IDENTIFIED_WITHIN_OBSERVED_BOUNDARY",
                "observed_boundary": "O3 (U -> C_req)",
                "evidence_vector": cls.format_evidence_vector("O3", "C1", r_scope, "S3"),
                "hypotheses_evaluation": {
                    "H1_client": "SUPPORTED (Mutation observed in path U -> C_req)",
                    "H2_server_pre_context": "NOT EVALUATED",
                    "H3_tokenizer": "NOT EVALUATED",
                    "H4_model_core": "NOT EVALUATED",
                    "H5_post_render": "NOT EVALUATED"
                },
                "epistemic_notes": "Mutazione localizzata nel software client prima della trasmissione in rete (H1a SUPPORTED)."
            }

        # Sottocaso 3B: Trasmissione Integra su C_req (U == C_req_unicode)
        if not diff_u_req:
            if not diff_req_out:
                return {
                    "verdict_status": "CONFORMANT_REPRODUCTION",
                    "evidence_status": "SUPPORTED",
                    "identification_status": "IDENTIFIED_WITHIN_OBSERVED_BOUNDARY",
                    "observed_boundary": "O3 (Full App Path Observed)",
                    "evidence_vector": cls.format_evidence_vector("O3", "C1", r_scope, "S1"),
                    "hypotheses_evaluation": {
                        "H1_client": "DISCONFIRMED (Payload C_req_unicode matches U_intended exactly)",
                        "H2_server_pre_context": "UNDERDETERMINED (Internal layer S inaccessibile)",
                        "H3_tokenizer": "UNDERDETERMINED (Token IDs inaccessibili)",
                        "H4_model_core": "UNDERDETERMINED (M_raw inaccessibile)",
                        "H5_post_render": "UNDERDETERMINED (Proxy != Meccanismo)"
                    },
                    "epistemic_notes": "Preservazione integrale sui confini osservati. Layer interni strutturalmente UNDERDETERMINED."
                }
            else:
                return {
                    "verdict_status": "POST_CLIENT_TRANSFORMATION",
                    "evidence_status": "SUPPORTED (Divergence Observed)",
                    "identification_status": "UNDERDETERMINED",
                    "observed_boundary": "O3 (C_req -> O)",
                    "evidence_vector": cls.format_evidence_vector("O3", "C1", r_scope, "S5"),
                    "hypotheses_evaluation": {
                        "H1_client": "DISCONFIRMED (Payload C_req_unicode matches U_intended exactly)",
                        "H2_server_pre_context": "UNDERDETERMINED",
                        "H3_tokenizer": "UNDERDETERMINED",
                        "H4_model_core": "UNDERDETERMINED",
                        "H5_post_render": "UNDERDETERMINED"
                    },
                    "epistemic_notes": "Trasformazione avvenuta a valle di C_req. Origine causale tra H2-H5 UNDERDETERMINED."
                }

        return {
            "verdict_status": "INDETERMINATE",
            "evidence_status": "NOT SUPPORTED",
            "identification_status": "NOT IDENTIFIED",
            "observed_boundary": "O0",
            "evidence_vector": cls.format_evidence_vector("O0", "C0", r_scope, "S0"),
            "hypotheses_evaluation": {},
            "epistemic_notes": "Stato non classificabile dai dati di telemetria."
        }

    @classmethod
    def evaluate_test_session(
        cls,
        test_id: str,
        trials_evaluations: List[Dict[str, Any]],
        stats_summary: Optional[Dict[str, Any]] = None,
        comparison_criterion: str = "M1-scalar",
        regime: str = "R1_PILOT"
    ) -> Dict[str, Any]:
        """
        Sintetizza l'intera sessione di test aggregando i singoli trial ed il sommario statistico.
        """
        n_total = len(trials_evaluations)
        r_scope = "R1" if "R1" in regime else ("R2" if "R2" in regime else "R0")

        if n_total == 0:
            return {
                "test_id": test_id,
                "session_regime": regime,
                "final_verdict": "NO_TRIALS_RECORDED",
                "final_evidence_status": "NOT SUPPORTED",
                "final_identification_status": "NOT IDENTIFIED",
                "final_evidence_vector": cls.format_evidence_vector("O0", "C0", r_scope, "S0"),
                "conclusion_summary": "Nessun trial registrato per la sessione."
            }

        n_valid = sum(1 for t in trials_evaluations if t.get("verdict_status") not in ["INVALID", "OUTPUT_OBSERVED_UNATTRIBUTED"])
        n_pre_client_mut = sum(1 for t in trials_evaluations if t.get("verdict_status") == "LOCAL_PRE_TRANSPORT_MUTATION")

        # T12: TEST APPAIATO TTFT (Grandezza Continua M4)
        if test_id == "T12" and stats_summary:
            mde_eval = stats_summary.get("mde_relevance_evaluation", {})
            is_relevant = mde_eval.get("is_practically_relevant", False)
            is_sig = mde_eval.get("is_statistically_significant", False)

            if is_relevant:
                final_ev_status = "SUPPORTED"
                final_id_status = "IDENTIFIED_WITHIN_OBSERVED_BOUNDARY"
                final_vector = cls.format_evidence_vector("O3", "C1", r_scope, "S1")
                conclusion_txt = "Differenza sistematica e ingegneristicamente rilevante nel TTFT osservato SUPPORTATA."
            elif is_sig:
                final_ev_status = "NOT SUPPORTED (Below MDE)"
                final_id_status = "NOT IDENTIFIED"
                final_vector = cls.format_evidence_vector("O3", "C1", r_scope, "S1")
                conclusion_txt = "Differenza statisticamente rilevabile ma inferiore alla Minima Differenza Rilevante (MDE)."
            else:
                final_ev_status = "NOT SUPPORTED"
                final_id_status = "NOT IDENTIFIED"
                final_vector = cls.format_evidence_vector("O3", "C1", r_scope, "S1")
                conclusion_txt = "Nessuna differenza sistematica riscontrata nel TTFT osservato tra le due condizioni."

            return {
                "test_id": test_id,
                "session_regime": regime,
                "comparison_criterion": "M4-Continuous-TTFT",
                "sample_size_valid": n_valid,
                "final_verdict": "DIAGNOSTIC_TTFT_EVALUATION_COMPLETE",
                "final_evidence_status": final_ev_status,
                "final_identification_status": final_id_status,
                "final_evidence_vector": final_vector,
                "hypotheses_ruling": {
                    "H1_client": "NOT APPLICABLE",
                    "H2_server_gateway": "COMPATIBLE",
                    "H3_tokenizer": "COMPATIBLE",
                    "H4_model_compute": "COMPATIBLE",
                    "H5_post_processing": "COMPATIBLE"
                },
                "conclusion_summary": conclusion_txt
            }

        if n_valid == 0:
            return {
                "test_id": test_id,
                "session_regime": regime,
                "final_verdict": "ALL_TRIALS_INVALID",
                "final_evidence_status": "NOT SUPPORTED",
                "final_identification_status": "NOT IDENTIFIED",
                "final_evidence_vector": cls.format_evidence_vector("O0", "C0", r_scope, "S0"),
                "conclusion_summary": "Tutti i trial della sessione sono risultati invalidi o non attribuibili."
            }

        # Determinazione del tasso di conformita ORR_b con priorita al sommario statistico formale
        orr_b: float = 0.0
        if stats_summary and "point_estimate_ORR_b" in stats_summary:
            orr_b = float(stats_summary["point_estimate_ORR_b"])
        else:
            n_conformant_raw = sum(1 for t in trials_evaluations if t.get("verdict_status") in ["CONFORMANT_REPRODUCTION", "VALID_BEHAVIORAL_ONLY"] and t.get("evidence_status") == "SUPPORTED")
            orr_b = round(n_conformant_raw / float(n_valid), 4)

        if n_pre_client_mut == n_valid:
            return {
                "test_id": test_id,
                "session_regime": regime,
                "comparison_criterion": comparison_criterion,
                "sample_size_valid": n_valid,
                "point_estimate_ORR_b": 0.0,
                "final_verdict": "CLIENT_SIDE_TRANSFORMATION_CONFIRMED",
                "final_evidence_status": "SUPPORTED",
                "final_identification_status": "IDENTIFIED_WITHIN_OBSERVED_BOUNDARY",
                "final_evidence_vector": cls.format_evidence_vector("O3", "C1", r_scope, "S3"),
                "hypotheses_ruling": {
                    "H1a_client_mutation": "SUPPORTED / IDENTIFIED_DIRECT",
                    "H2_to_H5_internal": "NOT APPLICABLE"
                },
                "conclusion_summary": "Trasformazione localizzata nel percorso U -> C_req (H1a SUPPORTED)."
            }

        if orr_b == 1.0 and n_pre_client_mut == 0:
            return {
                "test_id": test_id,
                "session_regime": regime,
                "comparison_criterion": comparison_criterion,
                "sample_size_valid": n_valid,
                "point_estimate_ORR_b": 1.0,
                "final_verdict": "PERFECT_CONFORMANCE_OBSERVED",
                "final_evidence_status": "SUPPORTED",
                "final_identification_status": "IDENTIFIED_WITHIN_OBSERVED_BOUNDARY",
                "final_evidence_vector": cls.format_evidence_vector("O3", "C1", r_scope, "S1"),
                "hypotheses_ruling": {
                    "H1a_client_mutation": "DISCONFIRMED (within observed boundary)",
                    "H2_to_H5_internal": "UNDERDETERMINED (Proxy != Meccanismo)"
                },
                "conclusion_summary": (
                    f"Conformita fenomenologica del 100% (ORR_b = 1.00) verificata sul confine V3-3 "
                    f"sotto criterio {comparison_criterion}. H1a disconfermata. Layer interni UNDERDETERMINED."
                )
            }

        if orr_b == 0.0 and n_pre_client_mut == 0:
            return {
                "test_id": test_id,
                "session_regime": regime,
                "comparison_criterion": comparison_criterion,
                "sample_size_valid": n_valid,
                "point_estimate_ORR_b": 0.0,
                "final_verdict": "POST_CLIENT_TRANSFORMATION_CONFIRMED",
                "final_evidence_status": "SUPPORTED (Divergence Observed)",
                "final_identification_status": "UNDERDETERMINED",
                "final_evidence_vector": cls.format_evidence_vector("O3", "C1", r_scope, "S5"),
                "hypotheses_ruling": {
                    "H1a_client_mutation": "DISCONFIRMED (C_req integro)",
                    "H2_to_H5_internal": "UNDERDETERMINED"
                },
                "conclusion_summary": "Trasformazione avvenuta a valle di C_req. Origine causale tra H2-H5 INDETERMINATA."
            }

        return {
            "test_id": test_id,
            "session_regime": regime,
            "comparison_criterion": comparison_criterion,
            "sample_size_valid": n_valid,
            "point_estimate_ORR_b": orr_b,
            "final_verdict": "CHANNEL_OR_GENERATIVE_VARIANCE_DETECTED",
            "final_evidence_status": "SUPPORTED (Non-Deterministic Behavior)",
            "final_identification_status": "UNDERDETERMINED",
            "final_evidence_vector": cls.format_evidence_vector("O3", "C1", r_scope, "S1"),
            "hypotheses_ruling": {
                "H1a_client_mutation": "DISCONFIRMED",
                "H2_to_H5_internal": "UNDERDETERMINED (Sampling T > 0 o routing distribuito)"
            },
            "conclusion_summary": f"Comportamento non deterministico o varianza riscontrata (ORR_b = {orr_b})."
        }


def main():
    parser = argparse.ArgumentParser(description="CDP/SOP v2.3 Deterministic Claim Classifier")
    parser.add_argument("--trial-json", default=None, help="File JSON di un singolo trial")
    parser.add_argument("--trials-dir", default=None, help="Directory contenente i trial_metadata.json della sessione")
    parser.add_argument("--stats-json", default=None, help="File metrics_summary.json prodotto da cdp_stats.py")
    parser.add_argument("--test-id", default=None, help="ID del test CDP/SOP (es. RUN0, T01..T14)")
    parser.add_argument("--criterion", default="M1-scalar", help="Criterio di confronto preregistrato (default: M1-scalar)")
    parser.add_argument("--regime", default="R1_PILOT", help="Regime metodologico (R1_PILOT, R2_CONSTRAINED)")
    parser.add_argument("--out", default=None, help="File JSON di output (default: stdout)")
    args = parser.parse_args()

    stats_data = None
    if args.stats_json and Path(args.stats_json).is_file():
        stats_data = json.loads(Path(args.stats_json).read_text(encoding="utf-8"))

    target_test_id = args.test_id or "UNRESOLVED"

    if args.trial_json:
        trial_data = json.loads(Path(args.trial_json).read_text(encoding="utf-8"))
        res = ClaimClassifier.evaluate_single_trial(trial_data, args.criterion, args.regime)
    elif args.trials_dir:
        trials_dir_path = Path(args.trials_dir)
        trial_files = sorted(trials_dir_path.glob("**/trial_metadata*.json"))

        trials_evals = []
        for tf in trial_files:
            try:
                t_data = json.loads(tf.read_text(encoding="utf-8"))
                t_eval = ClaimClassifier.evaluate_single_trial(t_data, args.criterion, args.regime)
                trials_evals.append(t_eval)
            except Exception as e:
                sys.stderr.write(f"claim_classifier: AVVISO: Impossibile leggere {tf}: {e}\n")

        res = ClaimClassifier.evaluate_test_session(
            target_test_id,
            trials_evals,
            stats_summary=stats_data,
            comparison_criterion=args.criterion,
            regime=args.regime
        )
    else:
        if not sys.stdin.isatty():
            stdin_data = json.loads(sys.stdin.read())
            if isinstance(stdin_data, list):
                trials_evals = [ClaimClassifier.evaluate_single_trial(t, args.criterion, args.regime) for t in stdin_data]
                res = ClaimClassifier.evaluate_test_session(target_test_id, trials_evals, stats_data, args.criterion, args.regime)
            else:
                res = ClaimClassifier.evaluate_single_trial(stdin_data, args.criterion, args.regime)
        else:
            parser.print_help(sys.stderr)
            sys.exit(2)

    output_str = json.dumps(res, indent=2, ensure_ascii=False)

    if args.out:
        out_p = Path(args.out)
        out_p.parent.mkdir(parents=True, exist_ok=True)
        out_p.write_text(output_str, encoding="utf-8")
        out_p.chmod(0o600)
    else:
        sys.stdout.write(output_str + "\n")


if __name__ == "__main__":
    main()
    
