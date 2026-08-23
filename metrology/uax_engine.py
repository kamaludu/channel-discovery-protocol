#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# CDP Unicode Normalizer — Gestore Forme Normalizzate UAX #15 e Policy UAX #29
# File: metrology/uax_engine.py
# Component: Unicode Metrology Engine (Criteri M2a / M2b)
# Standard: CDP v2.3 (Sez. 3.1, 5.1) & SOP v2.3 (Sez. 2.4, T03)
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/channel-discovery-protocol/
# Contact: opensource@cevangel.anonaddy.me
# ==============================================================================
# Requirements: python (>=3.10), strictly standard library (zero-pip dependencies)
#
# ==============================================================================
# GUIDA ARCHITETTURALE PER SVILUPPATORI (SUT / Tool Independent):
# ==============================================================================
# Questo modulo implementa il motore di analisi metrologica per le trasformazioni
# Unicode secondo lo standard Unicode UAX #15. È completamente agnostico rispetto
# allo strumento di invocazione (bash4llm, cURL o altri):
#   - Calcola i profili di decomposizione canonica e compatibile (NFC, NFD, NFKC, NFKD).
#   - Valuta l'equivalenza formale M2a tra stimolo inviato (U_intended) e output (O).
#   - Esamina i singoli codepoint e le categorie generali Unicode (Cc, Cf, ecc.).
#   - Dichiara formalmente la politica M2b per ambienti Zero-PIP (stdlib pura).
# ==============================================================================

import argparse
import hashlib
import json
import sys
import unicodedata
from pathlib import Path
from typing import Any, Dict, List


M2B_STATUS_POLICY = "UNAVAILABLE_IN_STDLIB_MODE"
M2B_POLICY_EXPLANATION = (
    "L'algoritmo Extended Grapheme Cluster Segmentation (Unicode UAX #29) richiede "
    "tabelle di proprieta' derivate (Grapheme_Cluster_Break) non esposte dalla standard "
    "library Python. In conformita' al principio di Conservativita' Epistemica, il criterio "
    "M2b e' formalmente rubricato come UNAVAILABLE_IN_STDLIB_MODE."
)


def get_unicode_telemetry() -> Dict[str, Any]:
    """Acquisisce le versioni runtime della tabella Unicode e dell'interprete Python."""
    return {
        "unicodedata_version": unicodedata.unidata_version,
        "python_version": sys.version.split()[0],
        "m2b_segmentation_status": M2B_STATUS_POLICY,
        "m2b_policy_explanation": M2B_POLICY_EXPLANATION
    }


def normalize_form(text: str, form: str) -> str:
    """Applica la normalizzazione Unicode UAX #15 (NFC, NFD, NFKC, NFKD)."""
    form_upper = form.upper()
    if form_upper not in ["NFC", "NFD", "NFKC", "NFKD"]:
        raise ValueError(f"Forma di normalizzazione non valida: {form}. Ammessi: NFC, NFD, NFKC, NFKD.")
    return unicodedata.normalize(form_upper, text)


def decompose_normalization_profile(text: str) -> Dict[str, Any]:
    """Genera il profilo completo delle 4 forme normalizzate con digest SHA-256 e codepoint."""
    profile: Dict[str, Any] = {
        "raw": {
            "literal": text,
            "scalar_count": len(text),
            "codepoints": " ".join(f"U+{ord(c):04X}" for c in text),
            "bytes_hex": text.encode("utf-8").hex().upper(),
            "sha256": hashlib.sha256(text.encode("utf-8")).hexdigest()
        },
        "forms": {}
    }

    for form in ["NFC", "NFD", "NFKC", "NFKD"]:
        norm_text = normalize_form(text, form)
        profile["forms"][form] = {
            "literal": norm_text,
            "scalar_count": len(norm_text),
            "codepoints": " ".join(f"U+{ord(c):04X}" for c in norm_text),
            "bytes_hex": norm_text.encode("utf-8").hex().upper(),
            "sha256": hashlib.sha256(norm_text.encode("utf-8")).hexdigest(),
            "is_identical_to_raw": (norm_text == text)
        }

    return profile


def evaluate_m2a_equivalence(s1: str, s2: str, form: str = "NFC") -> Dict[str, Any]:
    """Valuta se due stringhe s1 e s2 sono equivalenti sotto la forma normale specificata."""
    norm_s1 = normalize_form(s1, form)
    norm_s2 = normalize_form(s2, form)
    is_equiv = (norm_s1 == norm_s2)

    return {
        "criterion": f"M2a-{form.upper()}",
        "form": form.upper(),
        "is_equivalent": is_equiv,
        "s1_norm_sha256": hashlib.sha256(norm_s1.encode("utf-8")).hexdigest(),
        "s2_norm_sha256": hashlib.sha256(norm_s2.encode("utf-8")).hexdigest(),
        "exact_identity_M1": (s1 == s2)
    }


def analyze_unicode_codepoints(text: str) -> List[Dict[str, Any]]:
    """Scompone una stringa in singoli scalari Unicode con metadati categoriali completi."""
    breakdown = []
    for char in text:
        cp = ord(char)
        breakdown.append({
            "codepoint": f"U+{cp:04X}",
            "char_display": char if not unicodedata.category(char).startswith("C") else "<control>",
            "name": unicodedata.name(char, "<unnamed>"),
            "category": unicodedata.category(char),
            "combining_class": unicodedata.combining(char),
            "is_control_or_format": unicodedata.category(char) in ["Cf", "Cc", "Cs", "Co", "Cn"]
        })
    return breakdown


def main():
    parser = argparse.ArgumentParser(
        description="CDP/SOP v2.3 Unicode UAX #15 Engine & M2a Metrology Evaluator"
    )
    parser.add_argument("--text", default=None, help="Stringa scalare da analizzare")
    parser.add_argument("--file", default=None, help="File di input contenente il testo da analizzare")
    parser.add_argument("--compare", nargs=2, metavar=("S1", "S2"), help="Confronta due stringhe sotto equivalenza M2a")
    parser.add_argument("--form", choices=["NFC", "NFD", "NFKC", "NFKD"], default="NFC", help="Forma normale per il confronto (default: NFC)")
    parser.add_argument("--telemetry", action="store_true", help="Emette la telemetria delle versioni Unicode/Python")
    parser.add_argument("--out", default=None, help="File JSON di output (default: stdout)")
    args = parser.parse_args()

    if args.telemetry:
        res = get_unicode_telemetry()
    elif args.compare:
        res = evaluate_m2a_equivalence(args.compare[0], args.compare[1], args.form)
    else:
        target_text = ""
        if args.file:
            target_text = Path(args.file).read_text(encoding="utf-8")
        elif args.text is not None:
            target_text = args.text
        else:
            if not sys.stdin.isatty():
                target_text = sys.stdin.read()
            else:
                parser.print_help(sys.stderr)
                sys.exit(2)

        res = {
            "telemetry": get_unicode_telemetry(),
            "profile": decompose_normalization_profile(target_text),
            "codepoints": analyze_unicode_codepoints(target_text)
        }

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
    
