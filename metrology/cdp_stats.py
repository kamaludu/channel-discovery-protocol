#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# CDP Statistical Engine — Calcolo Esatto Clopper-Pearson 95% e Paired TTFT Stats
# File: metrology/cdp_stats.py
# Component: Metrology Statistical Calculator
# Standard: CDP v2.3 (Sez. 4.3) & SOP v2.3 (Sez. 4.3, 4.4, T12)
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/channel-discovery-protocol/
# Contact: opensource@cevangel.anonaddy.me
# ==============================================================================
# Requirements: python (>=3.10), strictly standard library (zero-pip dependencies)

import argparse
import json
import math
import random
import sys
from pathlib import Path


def _betacf(a: float, b: float, x: float, max_iter: int = 200, eps: float = 1e-15) -> float:
    qab = a + b
    qap = a + 1.0
    qam = a - 1.0
    c = 1.0
    d = 1.0 - (qab * x / qap)
    if abs(d) < 1e-30:
        d = 1e-30
    d = 1.0 / d
    h = d

    for m in range(1, max_iter + 1):
        m2 = 2 * m
        aa = m * (b - m) * x / ((qam + m2) * (a + m2))
        d = 1.0 + aa * d
        if abs(d) < 1e-30:
            d = 1e-30
        c = 1.0 + aa / c
        if abs(c) < 1e-30:
            c = 1e-30
        d = 1.0 / d
        h *= d * c

        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
        d = 1.0 + aa * d
        if abs(d) < 1e-30:
            d = 1e-30
        c = 1.0 + aa / c
        if abs(c) < 1e-30:
            c = 1e-30
        d = 1.0 / d
        del_h = d * c
        h *= del_h

        if abs(del_h - 1.0) < eps:
            break

    return h


def betainc(a: float, b: float, x: float) -> float:
    if x < 0.0 or x > 1.0:
        raise ValueError("x deve appartenere all'intervallo [0, 1]")
    if x == 0.0:
        return 0.0
    if x == 1.0:
        return 1.0

    lbeta = math.lgamma(a) + math.lgamma(b) - math.lgamma(a + b)
    front = math.exp(a * math.log(x) + b * math.log(1.0 - x) - lbeta)

    if x < (a + 1.0) / (a + b + 2.0):
        return (front * _betacf(a, b, x)) / a
    else:
        return 1.0 - (front * _betacf(b, a, 1.0 - x)) / b


def inv_betainc(a: float, b: float, target_p: float, tol: float = 1e-8) -> float:
    if target_p <= 0.0:
        return 0.0
    if target_p >= 1.0:
        return 1.0

    low = 0.0
    high = 1.0
    for _ in range(100):
        mid = (low + high) / 2.0
        val = betainc(a, b, mid)
        if abs(val - target_p) < tol:
            return mid
        if val < target_p:
            low = mid
        else:
            high = mid
    return (low + high) / 2.0


def student_t_cdf(t_val: float, df: int) -> float:
    if df <= 0:
        raise ValueError("I gradi di liberta (df) devono essere > 0")
    if t_val == 0.0:
        return 0.5

    x = df / (df + (t_val * t_val))
    prob_tail = 0.5 * betainc(df / 2.0, 0.5, x)

    if t_val > 0.0:
        return 1.0 - prob_tail
    else:
        return prob_tail


def student_t_inv_two_tailed(alpha: float, df: int, tol: float = 1e-7) -> float:
    target_p = 1.0 - (alpha / 2.0)
    low = 0.0
    high = max(1000.0, 10.0 / alpha)

    for _ in range(100):
        mid = (low + high) / 2.0
        p = student_t_cdf(mid, df)
        if abs(p - target_p) < tol:
            return mid
        if p < target_p:
            low = mid
        else:
            high = mid
    return (low + high) / 2.0


def clopper_pearson_ci(k: int, n: int, alpha: float = 0.05) -> dict:
    if n <= 0:
        raise ValueError("La dimensione campionaria n deve essere > 0")
    if k < 0 or k > n:
        raise ValueError("k deve essere compreso tra 0 e n")

    point_estimate = k / float(n)

    if k == 0:
        lower = 0.0
        upper = 1.0 - (alpha / 2.0) ** (1.0 / n)
    elif k == n:
        lower = (alpha / 2.0) ** (1.0 / n)
        upper = 1.0
    else:
        lower = inv_betainc(k, n - k + 1, alpha / 2.0)
        upper = inv_betainc(k + 1, n - k, 1.0 - (alpha / 2.0))

    return {
        "mensurand": "ORR_b",
        "sample_size_n": n,
        "successes_k": k,
        "point_estimate": round(point_estimate, 4),
        "point_estimate_ORR_b": round(point_estimate, 4),
        "confidence_level": 1.0 - alpha,
        "ci_lower": round(lower, 4),
        "ci_upper": round(upper, 4),
        "confidence_interval_95_clopper_pearson": {
            "lower": round(lower, 4),
            "upper": round(upper, 4)
        },
        "ci_formatted": f"[{lower:.4f}, {upper:.4f}]",
        "method": "Exact Binomial Clopper-Pearson (Beta Analytical/Bisection)"
    }


def paired_difference_ttft(
    pairs: list,
    mde_ms: float = 100.0,
    alpha: float = 0.05,
    bootstrap_reps: int = 10000
) -> dict:
    n = len(pairs)
    if n < 2:
        raise ValueError("L'analisi appaiata richiede almeno N = 2 coppie")

    diffs = []
    for p in pairs:
        if isinstance(p, dict):
            diffs.append(float(p["ttft_b"]) - float(p["ttft_a"]))
        else:
            diffs.append(float(p[1]) - float(p[0]))

    bar_d = sum(diffs) / float(n)
    variance_d = sum((x - bar_d) ** 2 for x in diffs) / float(n - 1)
    s_d = math.sqrt(variance_d)
    se_d = s_d / math.sqrt(n)

    df = n - 1
    t_crit = student_t_inv_two_tailed(alpha, df)
    ci_param_lower = bar_d - (t_crit * se_d)
    ci_param_upper = bar_d + (t_crit * se_d)

    rng = random.Random(42)
    boot_means = []
    for _ in range(bootstrap_reps):
        sample = [rng.choice(diffs) for _ in range(n)]
        boot_means.append(sum(sample) / float(n))

    boot_means.sort()
    idx_lower = int((alpha / 2.0) * bootstrap_reps)
    idx_upper = int((1.0 - (alpha / 2.0)) * bootstrap_reps)
    ci_boot_lower = boot_means[idx_lower]
    ci_boot_upper = boot_means[idx_upper]

    excludes_zero = (ci_param_lower > 0.0 and ci_param_upper > 0.0) or (ci_param_lower < 0.0 and ci_param_upper < 0.0)
    is_practically_relevant = excludes_zero and (abs(bar_d) >= mde_ms)

    return {
        "sample_size_pairs_N": n,
        "point_estimate_bar_D_ms": round(bar_d, 2),
        "std_dev_s_D_ms": round(s_d, 2),
        "standard_error_ms": round(se_d, 2),
        "degrees_of_freedom": df,
        "t_critical_value": round(t_crit, 4),
        "primary_parametric_ci_95": {
            "lower_ms": round(ci_param_lower, 2),
            "upper_ms": round(ci_param_upper, 2),
            "formatted": f"[{ci_param_lower:.2f}, {ci_param_upper:.2f}] ms"
        },
        "secondary_bootstrap_ci_95": {
            "replications": bootstrap_reps,
            "lower_ms": round(ci_boot_lower, 2),
            "upper_ms": round(ci_boot_upper, 2),
            "formatted": f"[{ci_boot_lower:.2f}, {ci_boot_upper:.2f}] ms"
        },
        "mde_relevance_evaluation": {
            "mde_delta_min_ms": mde_ms,
            "is_statistically_significant": excludes_zero,
            "is_practically_relevant": is_practically_relevant,
            "verdict": "RELEVANT_DIFFERENCE_SUPPORTED" if is_practically_relevant else "NO_RELEVANT_DIFFERENCE"
        }
    }


def a_priori_sample_size_r2(
    mde_delta_min: float,
    pilot_s_d: float,
    alpha: float = 0.05,
    power: float = 0.80
) -> dict:
    if mde_delta_min <= 0.0 or pilot_s_d <= 0.0:
        raise ValueError("MDE e deviazione standard pilota devono essere > 0")

    z_alpha_half = 1.95996
    z_beta = 0.84162 if abs(power - 0.80) < 0.01 else (1.28155 if abs(power - 0.90) < 0.01 else 0.84162)

    n_exact = (((z_alpha_half + z_beta) ** 2) * (pilot_s_d ** 2)) / (mde_delta_min ** 2)
    n_calc = math.ceil(n_exact)

    return {
        "regime": "R2_CONSTRAINED_ESTIMATION",
        "mde_delta_min": mde_delta_min,
        "pilot_std_dev_s_D": pilot_s_d,
        "alpha": alpha,
        "target_power_1_minus_beta": power,
        "exact_calculated_n": round(n_exact, 2),
        "recommended_sample_size_N": max(n_calc, 10)
    }


def main():
    common_parser = argparse.ArgumentParser(add_help=False)
    common_parser.add_argument("--out", default=None, help="Percorso file JSON di output")

    parser = argparse.ArgumentParser(
        description="CDP/SOP v2.3 Metrology Statistical Engine",
        parents=[common_parser]
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    p_binom = subparsers.add_parser("binomial", parents=[common_parser], help="Intervallo Esatto Clopper-Pearson")
    p_binom.add_argument("-k", "--k", type=int, required=True)
    p_binom.add_argument("-n", "--n", type=int, required=True)
    p_binom.add_argument("--alpha", type=float, default=0.05)

    p_ttft = subparsers.add_parser("paired-ttft", parents=[common_parser], help="Analisi Appaiata TTFT (T12)")
    p_ttft.add_argument("--pairs-json", type=str, required=True)
    p_ttft.add_argument("--mde", type=float, default=100.0)
    p_ttft.add_argument("--alpha", type=float, default=0.05)
    p_ttft.add_argument("--bootstrap-reps", type=int, default=10000)

    p_power = subparsers.add_parser("power", parents=[common_parser], help="Power Analysis Regime R2")
    p_power.add_argument("--mde", type=float, required=True)
    p_power.add_argument("--pilot-sd", type=float, required=True)
    p_power.add_argument("--power", type=float, default=0.80)

    args = parser.parse_args()

    if args.command == "binomial":
        res = clopper_pearson_ci(args.k, args.n, args.alpha)
    elif args.command == "paired-ttft":
        pairs_data = json.loads(Path(args.pairs_json).read_text(encoding="utf-8"))
        res = paired_difference_ttft(pairs_data, args.mde, args.alpha, args.bootstrap_reps)
    elif args.command == "power":
        res = a_priori_sample_size_r2(args.mde, args.pilot_sd, power=args.power)

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
    
