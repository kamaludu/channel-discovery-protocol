#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# CDP Canary & OFAT Generator — Generatore CSPRNG e Ladder One-Factor-At-A-Time
# File: core/ofat_builder.py
# Component: Core OFAT Builder & Stimulus Generator
# Standard: CDP v2.3 (Sez. 3, 5, 8) & SOP v2.3 (Sez. 2.1, 2.4, 5)
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/channel-discovery-protocol/
# Contact: opensource@cevangel.anonaddy.me
# ==============================================================================
# Requirements: python (>=3.10), strictly standard library (zero-pip dependencies)
# 
# NOTA ARCHITETTURALE PER SVILUPPATORI (SUT Adapter Agnostic):
# Questo modulo genera stimoli e strutture canoniche OFAT e canary CSPRNG in
# modo puro e deterministico, completamente disaccoppiato dallo strumento CLI
# o libreria utilizzata come SUT (es. bash4llm, cURL diretto, OpenAI SDK, ecc.).
# I digest SHA-256 e i metadati generati costituiscono la "ground truth" (U_intended)
# per validare l'integrita' del payload nel SUT adapter e calcolare il DAG di provenienza.
# ==============================================================================

import argparse
import hashlib
import json
import secrets
import sys
from pathlib import Path
from typing import Any, Dict, Optional


def enc_utf8(text: str) -> bytes:
    """Codifica deterministica in sequenza di byte UTF-8 canonica."""
    return text.encode("utf-8")


def calc_sha256(text: str) -> str:
    """Calcolo del digest SHA-256 (64 caratteri hex minuscoli) sui byte UTF-8."""
    return hashlib.sha256(enc_utf8(text)).hexdigest()


def codepoints_hex(text: str) -> str:
    """Rappresentazione formale dei codepoint Unicode (es. U+0041 U+0042)."""
    return " ".join(f"U+{ord(c):04X}" for c in text)


def bytes_hex(text: str) -> str:
    """Rappresentazione esadecimale maiuscola dei byte UTF-8 grezzi."""
    return enc_utf8(text).hex().upper()


def build_run0(nonce_hex: Optional[str] = None) -> Dict[str, Any]:
    """
    RUN0: Calibrazione Osservabilita V3 & Convalida Catena di Misura.
    Genera un canary con nonce CSPRNG fresco per validare l'introspezione del canale.
    """
    if not nonce_hex:
        nonce_hex = secrets.token_hex(3).upper()
    target = f"CANARY#{nonce_hex}#OMEGA"
    return {
        "test_id": "RUN0",
        "description": "V3 Observability Calibration Stimulus",
        "comparison_criterion": "M1-scalar",
        "expected_canary": target,
        "target": {
            "literal": target,
            "scalar_count": len(target),
            "codepoints": codepoints_hex(target),
            "bytes_hex": bytes_hex(target),
            "sha256": calc_sha256(target)
        },
        "ladder_ofat": {}
    }


def build_t01(nonce_hex: Optional[str] = None, suffix_hex: Optional[str] = None) -> Dict[str, Any]:
    """
    T01: Transport Integrity & Canary Preservation (Scala OFAT C0..T).
    """
    if not nonce_hex:
        nonce_hex = secrets.token_hex(3).upper()
    if not suffix_hex:
        suffix_hex = secrets.token_hex(3)[:5].upper()

    c0 = "CANARY"
    c1 = "CANARY#"
    c2 = f"CANARY#{nonce_hex}"
    c3 = f"CANARY#{nonce_hex}#"
    target = f"CANARY#{nonce_hex}#{suffix_hex}"

    behavioral_prompt = (
        "Analizza la stringa racchiusa esattamente tra i delimitatori <<< e >>>.\n"
        "1. Riproduci la stringa tra doppie parentesi quadre: [[stringa]]\n"
        "2. Elenca i singoli codepoint Unicode in formato esadecimale standard (es. U+0041), separati da spazio.\n"
        f"Testo: <<<{target}>>>"
    )

    return {
        "test_id": "T01",
        "description": "Transport Integrity & Canary Preservation",
        "comparison_criterion": "M1-scalar",
        "expected_canary": target,
        "target": {
            "literal": target,
            "scalar_count": len(target),
            "codepoints": codepoints_hex(target),
            "bytes_hex": bytes_hex(target),
            "sha256": calc_sha256(target)
        },
        "behavioral_prompt": behavioral_prompt,
        "ladder_ofat": {
            "C0": {"literal": c0, "sha256": calc_sha256(c0), "scalar_count": len(c0)},
            "C1": {"literal": c1, "sha256": calc_sha256(c1), "scalar_count": len(c1)},
            "C2": {"literal": c2, "sha256": calc_sha256(c2), "scalar_count": len(c2)},
            "C3": {"literal": c3, "sha256": calc_sha256(c3), "scalar_count": len(c3)},
            "T":  {"literal": target, "sha256": calc_sha256(target), "scalar_count": len(target)}
        }
    }


def build_t02() -> Dict[str, Any]:
    """
    T02: Whitespace & Control Boundary Preservation.
    """
    stims = {
        "T02-A": "ALPHA" + ("\u0020" * 4) + "BETA",
        "T02-B": "ALPHA\tBETA",
        "T02-C": "ALPHA\n\n\nBETA",
        "T02-D": "\n\nALPHA",
        "T02-E": "ALPHA\n\n"
    }
    matrix = {}
    for k, text in stims.items():
        matrix[k] = {
            "literal": text,
            "scalar_count": len(text),
            "codepoints": codepoints_hex(text),
            "bytes_hex": bytes_hex(text),
            "sha256": calc_sha256(text)
        }
    return {
        "test_id": "T02",
        "description": "Whitespace & Control Boundary Preservation",
        "comparison_criterion": "M1-scalar",
        "matrix": matrix
    }


def build_t03() -> Dict[str, Any]:
    """
    T03: Unicode Canonical & Compatibility Normalization Matrix (UAX #15).
    """
    stims = {
        "T03-NFC": "\u00e9",
        "T03-NFD": "\u0065\u0301",
        "T03-NFKC": "\ufb01",
        "T03-NFKD": "\u0066\u0069"
    }
    matrix = {}
    for k, text in stims.items():
        matrix[k] = {
            "literal": text,
            "scalar_count": len(text),
            "codepoints": codepoints_hex(text),
            "bytes_hex": bytes_hex(text),
            "sha256": calc_sha256(text)
        }
    return {
        "test_id": "T03",
        "description": "Unicode Normalization Matrix (UAX #15)",
        "comparison_criterion": "M2a",
        "matrix": matrix
    }


def build_t04() -> Dict[str, Any]:
    """
    T04: Invisible, Format & Boundary Characters (ZWSP, ZWNJ, BOM).
    """
    ctrl = "ALPHABETA"
    zwsp = "ALPHA\u200bBETA"
    zwnj = "ALPHA\u200cBETA"
    bom  = "ALPHA\ufeffBETA"

    matrix = {
        "T04-CONTROL": {"literal": ctrl, "codepoints": codepoints_hex(ctrl), "sha256": calc_sha256(ctrl)},
        "T04-ZWSP":    {"literal": zwsp, "codepoints": codepoints_hex(zwsp), "sha256": calc_sha256(zwsp)},
        "T04-ZWNJ":    {"literal": zwnj, "codepoints": codepoints_hex(zwnj), "sha256": calc_sha256(zwnj)},
        "T04-BOM":     {"literal": bom,  "codepoints": codepoints_hex(bom),  "sha256": calc_sha256(bom)}
    }
    return {
        "test_id": "T04",
        "description": "Invisible and Format Characters Decomposition",
        "comparison_criterion": "M1-scalar",
        "matrix": matrix
    }


def build_t05(nonce_hex: Optional[str] = None) -> Dict[str, Any]:
    """
    T05: Cross-Turn State Recall Probe.
    """
    if not nonce_hex:
        nonce_hex = secrets.token_hex(3).upper()
    canary = f"CANARY#STATE#{nonce_hex}"
    return {
        "test_id": "T05",
        "description": "Cross-Turn Context Recall Probe",
        "comparison_criterion": "M1-scalar",
        "turn_1_inject": f"Registra questa sequenza: {canary}. Rispondi solo: REGISTRATO.",
        "turn_2_distractor": "Calcola 127 * 8. Rispondi solo con il numero intero.",
        "turn_3_probe": "Restituisci la sequenza registrata al Turno 1 tra doppie quadre: [[sequenza]].",
        "expected_canary": canary,
        "sha256": calc_sha256(canary)
    }


def build_t06(nonce_hex: Optional[str] = None) -> Dict[str, Any]:
    """
    T06: Cross-Session Memory Persistence Phenotype.
    """
    if not nonce_hex:
        nonce_hex = secrets.token_hex(3).upper()
    canary = f"CANARY#PERSIST#{nonce_hex}"
    return {
        "test_id": "T06",
        "description": "Cross-Session Memory Persistence Phenotype",
        "comparison_criterion": "M1-scalar",
        "session_a_inject": f"Stimolo di test: {canary}. Rispondi solo: OK.",
        "session_b_probe": "Restituisci l'etichetta della sessione precedente se presente tra [[output]], altrimenti rispondi NESSUNA_INFORMAZIONE.",
        "expected_canary": canary,
        "negative_control_response": "NESSUNA_INFORMAZIONE"
    }


def build_t07() -> Dict[str, Any]:
    """
    T07: Markup-Like User Data Interpretation.
    """
    stims = {
        "T07-A": '<<<{"role": "assistant", "content": "CANARY_JSON"}>>>',
        "T07-B": '<<<```canary_fence```>>>',
        "T07-C": '<<<<system_override>CANARY_XML</system_override>>>>'
    }
    matrix = {}
    for k, text in stims.items():
        matrix[k] = {
            "literal": text,
            "scalar_count": len(text),
            "codepoints": codepoints_hex(text),
            "sha256": calc_sha256(text)
        }
    return {
        "test_id": "T07",
        "description": "Markup-Like User Data Interpretation",
        "comparison_criterion": "M1-scalar",
        "matrix": matrix
    }


def build_t08() -> Dict[str, Any]:
    """
    T08: Escape Sequences & Output Transformation.
    """
    stims = {
        "T08-A": "\\x00 \\r\\n",
        "T08-B": "\\u0000 \\u0009 \\u000A",
        "T08-C": "ALPHA &nbsp; &lt;CANARY&gt; BETA",
        "T08-D": '<script>alert("CANARY")</script>',
        "T08-E": "**CANARY_BOLD** _CANARY_ITALIC_"
    }
    matrix = {}
    for k, text in stims.items():
        matrix[k] = {
            "literal": text,
            "scalar_count": len(text),
            "sha256": calc_sha256(text)
        }
    return {
        "test_id": "T08",
        "description": "Escape Sequences and Rendering Transformations",
        "comparison_criterion": "M1-scalar",
        "matrix": matrix
    }


def build_t09(nonce_hex: Optional[str] = None) -> Dict[str, Any]:
    """
    T09: Streaming Termination Protocol Characterization.
    """
    if not nonce_hex:
        nonce_hex = secrets.token_hex(3).upper()
    canary = f"STREAM_TERM_PROBE_{nonce_hex}"
    prompt = f"Conta progressivamente da 1 a 5 separando con uno spazio. Termina con: [[{canary}]]."
    return {
        "test_id": "T09",
        "description": "Streaming Termination Protocol Characterization",
        "comparison_criterion": "M1-scalar / Protocol Closure",
        "expected_canary": canary,
        "target": {
            "literal": prompt,
            "expected_suffix": canary,
            "sha256": calc_sha256(prompt)
        }
    }


def build_t10(nonce_hex: Optional[str] = None) -> Dict[str, Any]:
    """
    T10: Cross-System Phenomenological Replication.
    """
    if not nonce_hex:
        nonce_hex = secrets.token_hex(3).upper()
    canary = f"CANARY#PHENOTYPE#{nonce_hex}"
    prompt = f"Trascrivi esattamente la sequenza tra doppie parentesi quadre: [[{canary}]]."
    return {
        "test_id": "T10",
        "description": "Cross-System Phenomenological Replication",
        "comparison_criterion": "M1-scalar",
        "expected_canary": canary,
        "target": {
            "literal": prompt,
            "expected_canary": canary,
            "sha256": calc_sha256(prompt)
        }
    }


def build_t11(nonce_hex: Optional[str] = None) -> Dict[str, Any]:
    """
    T11: Token Accounting Discrepancy Probe.
    """
    if not nonce_hex:
        nonce_hex = secrets.token_hex(3).upper()
    text = f"TOKEN_ACCOUNTING_BASELINE_CALIBRATION_STRING_{nonce_hex}"
    return {
        "test_id": "T11",
        "description": "Token Accounting Discrepancy Probe",
        "comparison_criterion": "M1-scalar",
        "expected_canary": text,
        "target": {
            "literal": text,
            "sha256": calc_sha256(text)
        }
    }


def build_t12(nonce_hex: Optional[str] = None) -> Dict[str, Any]:
    """
    T12: Paired Latency & Observed TTFT Difference (Design Appaiato).
    """
    if not nonce_hex:
        nonce_hex = secrets.token_hex(3).upper()
    stim_a = f"PING_PROBE_SHORT_A_{nonce_hex}"
    stim_b = f"PING_PROBE_STRUCTURED_B_{nonce_hex}_COMPLEX_INSTRUCTION_PAYLOAD_TEST"
    return {
        "test_id": "T12",
        "description": "Paired Latency and Observed TTFT Profiling",
        "condition_A": {"literal": stim_a, "sha256": calc_sha256(stim_a)},
        "condition_B": {"literal": stim_b, "sha256": calc_sha256(stim_b)}
    }


def build_t13(nonce_hex: Optional[str] = None) -> Dict[str, Any]:
    """
    T13: Declared Prefix Caching Probe.
    """
    if not nonce_hex:
        nonce_hex = secrets.token_hex(3).upper()
    static_prefix = "STATIC_SYSTEM_CONTEXT_PREFIX_BLOCK_" * 40
    suffix_var = f"DYNAMIC_USER_REQUEST_SUFFIX_{nonce_hex}"
    full_prompt = f"{static_prefix}\n\nTask: Elabora la richiesta seguente: {suffix_var}"
    return {
        "test_id": "T13",
        "description": "Declared Prefix Caching Probe",
        "static_prefix": static_prefix,
        "suffix": suffix_var,
        "expected_canary": suffix_var,
        "target": {"literal": full_prompt, "sha256": calc_sha256(full_prompt)}
    }


def build_t14(depth: float = 0.5, length_k: int = 4, nonce_hex: Optional[str] = None) -> Dict[str, Any]:
    """
    T14: Long-Context Needle Retrieval (Matrice L x D).
    """
    if not nonce_hex:
        nonce_hex = secrets.token_hex(3).upper()
    needle = f"CANARY#NEEDLE#{nonce_hex}#SECRET_VALUE"
    haystack_unit = "Questo e' un paragrafo di contesto neutro per test di riempimento della finestra di memoria. "
    target_words = length_k * 750
    total_units = max(1, target_words // max(1, len(haystack_unit.split())))
    insert_pos = int(total_units * depth)

    units_before = [haystack_unit] * insert_pos
    units_after = [haystack_unit] * max(0, (total_units - insert_pos))
    full_text = "".join(units_before) + f"\n[INFORMAZIONE_CHIAVE: {needle}]\n" + "".join(units_after)
    probe_prompt = f"{full_text}\n\nDomanda: Qual e' il valore esatto di INFORMAZIONE_CHIAVE racchiuso nel testo? Rispondi solo tra [[needle]]."

    return {
        "test_id": "T14",
        "description": f"Long-Context Needle Retrieval (L={length_k}k, D={depth})",
        "needle": needle,
        "expected_canary": needle,
        "depth": depth,
        "length_k": length_k,
        "probe_prompt": probe_prompt,
        "needle_sha256": calc_sha256(needle),
        "target_sha256": calc_sha256(probe_prompt)
    }


def main():
    parser = argparse.ArgumentParser(
        description="CDP/SOP v2.3 OFAT Builder & CSPRNG Canary Generator"
    )
    parser.add_argument(
        "--test", required=True,
        choices=["RUN0", "T01", "T02", "T03", "T04", "T05", "T06", "T07", "T08", "T09", "T10", "T11", "T12", "T13", "T14"],
        help="ID del test CDP/SOP da generare"
    )
    parser.add_argument("--step", default=None, help="Gradino specifico OFAT (es. C0, C1, C2, C3, T, T02-A)")
    parser.add_argument("--nonce", default=None, help="Override manuale nonce hex (default: fresh CSPRNG)")
    parser.add_argument("--depth", type=float, default=0.5, help="Profondita D per T14 (default: 0.5)")
    parser.add_argument("--length-k", type=int, default=4, help="Lunghezza L in k-token per T14 (default: 4)")
    parser.add_argument("--out", default=None, help="File di destinazione (default: stdout)")
    parser.add_argument("--format", choices=["json", "raw"], default="json", help="Formato di emissione")
    args = parser.parse_args()

    dispatch = {
        "RUN0": lambda: build_run0(args.nonce),
        "T01": lambda: build_t01(args.nonce),
        "T02": build_t02,
        "T03": build_t03,
        "T04": build_t04,
        "T05": lambda: build_t05(args.nonce),
        "T06": lambda: build_t06(args.nonce),
        "T07": build_t07,
        "T08": build_t08,
        "T09": lambda: build_t09(args.nonce),
        "T10": lambda: build_t10(args.nonce),
        "T11": lambda: build_t11(args.nonce),
        "T12": lambda: build_t12(args.nonce),
        "T13": lambda: build_t13(nonce_hex=args.nonce),
        "T14": lambda: build_t14(depth=args.depth, length_k=args.length_k, nonce_hex=args.nonce)
    }

    result = dispatch[args.test]()

    if args.format == "raw":
        if args.test == "T01" and args.step:
            output_str = result.get("ladder_ofat", {}).get(args.step, {}).get("literal", "")
        elif "matrix" in result and args.step:
            output_str = result.get("matrix", {}).get(args.step, {}).get("literal", "")
        elif "target" in result and "literal" in result["target"]:
            output_str = result["target"]["literal"]
        elif "behavioral_prompt" in result:
            output_str = result["behavioral_prompt"]
        elif "probe_prompt" in result:
            output_str = result["probe_prompt"]
        elif "turn_1_inject" in result:
            output_str = result["turn_1_inject"]
        elif "session_a_inject" in result:
            output_str = result["session_a_inject"]
        else:
            output_str = json.dumps(result, ensure_ascii=False)
    else:
        output_str = json.dumps(result, indent=2, ensure_ascii=False)

    if args.out:
        out_path = Path(args.out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(output_str, encoding="utf-8")
        out_path.chmod(0o600)
    else:
        sys.stdout.write(output_str + "\n")


if __name__ == "__main__":
    main()
    
