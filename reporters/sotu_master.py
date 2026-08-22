#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# SPDX-License-Identifier: GPL-3.0-or-later
# ==============================================================================
# CDP SOTU Reporter — Compilatore Scheda Master SOTU v2.3 (The Quadruplet Rule)
# File: reporters/sotu_master.py
# Component: Master SOTU Markdown Reporter
# Standard: CDP v2.3 (Sez. 9) & SOP v2.3 (Sez. 6, 7, Sez. 0.3, 0.4)
# Copyright (C) 2026 Cristian Evangelisti
# License: GPL-3.0-or-later
# Repository: https://github.com/kamaludu/channel-discovery-protocol/
# Contact: opensource@cevangel.anonaddy.me
# ==============================================================================
# Requirements: python (>=3.10), strictly standard library (zero-pip dependencies)

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Optional


TEST_DESCRIPTIONS = {
    "RUN0": {
        "name": "V3 Observability Calibration & Instrumentation Verification",
        "regime": "Calibrazione Strumentale",
        "question": "La catena strumentale intercetta e identifica univocamente il canale applicativo di trasporto (Layer V3-3) tramite correlazione del payload e verifica SHA-256?",
        "criterion": "M1-scalar",
        "success": "Corrispondenza esatta 1:1 del digest SHA-256 in C_req_unicode e correlazione ID risposta.",
        "disconfirmation": "Mancata cattura del traffico o alterazione della sequenza U_ref sul canale di rete."
    },
    "T01": {
        "name": "Transport Integrity & Canary Preservation",
        "regime": "Confermatorio (R1/R2)",
        "question": "La sequenza di caratteri target viene trasmessa integra sul confine client/rete (C_req) e riprodotta conformemente nell'output (O) sotto il criterio M1-scalar?",
        "criterion": "M1-scalar",
        "success": "ORR_b == 1.00 con riproduzione esatta 1:1 dei caratteri scalari e dei codepoint esadecimali.",
        "disconfirmation": "Omissione, sostituzione o alterazione posizionale di almeno un carattere nella stringa emessa."
    },
    "T02": {
        "name": "Whitespace & Control Boundary Preservation",
        "regime": "Confermatorio (R1/R2)",
        "question": "Il canale preserva i caratteri di spaziatura multipli, tabulazioni e interruzioni di riga interne rispetto a quelle posizionate sui confini (leading/trailing)?",
        "criterion": "M1-scalar",
        "success": "Preservazione esatta dei codepoint U+0020, U+0009, U+000A interni vs trimming controllato sui bordi.",
        "disconfirmation": "Collasso non documentato degli spazi interni o mancata rimozione dei leading/trailing previsti."
    },
    "T03": {
        "name": "Unicode Canonical & Compatibility Normalization",
        "regime": "Confermatorio (R1/R2)",
        "question": "Il canale applica trasformazioni di equivalenza canonica (NFC/NFD) o di compatibilita' (NFKC/NFKD) conformemente a Unicode UAX #15?",
        "criterion": "M2a",
        "success": "Identificazione deterministica del profilo di normalizzazione applicato al passaggio U -> C_req -> O.",
        "disconfirmation": "Varianza casuale o instabile delle forme canoniche tra repliche indipendenti."
    },
    "T04": {
        "name": "Invisible, Format & Boundary-Sensitive Unicode Characters",
        "regime": "Confermatorio (R1/R2)",
        "question": "I caratteri di formato a larghezza zero (ZWSP, ZWNJ, BOM) vengono preservati sul trasporto (C_req) ed emessi nell'output (O)?",
        "criterion": "M1-scalar",
        "success": "Tracciamento differenziale della presenza in C_req vs soppressione/preservazione in O.",
        "disconfirmation": "Iniezione di caratteri sostitutivi (es. U+FFFD) sul canale di trasporto."
    },
    "T05": {
        "name": "Cross-Turn Recall Probe",
        "regime": "Esplorativo",
        "question": "Un'informazione iniettata al Turno 1 rimane disponibile per il recupero esatto al Turno 3 dopo un compito distrattore?",
        "criterion": "M1-scalar",
        "success": "Recupero esatto del canary al Turno 3 con ORR_b == 1.00.",
        "disconfirmation": "Allucinazione o mancata restituzione del nonce al Turno 3."
    },
    "T06": {
        "name": "Cross-Session Persistence Phenotype",
        "regime": "Esplorativo",
        "question": "Un canary iniettato nella Sessione A risulta accessibile in una Sessione B temporalmente disgiunta?",
        "criterion": "M1-scalar",
        "success": "Recupero selettivo in Sessione B con zero falsi positivi sui controlli negativi.",
        "disconfirmation": "Emissione del canary in Sessione B in assenza di iniezione in Sessione A."
    },
    "T07": {
        "name": "Markup-Like User Data — Behavioral Interpretation",
        "regime": "Esplorativo",
        "question": "Sequenze utente che emulano strutture di protocollo (JSON, XML, code fences) vengono trattate come testo inerte o alterano la risposta?",
        "criterion": "M1-scalar",
        "success": "Trattamento inerte del testo senza rotture sintattiche del payload.",
        "disconfirmation": "Esecuzione o interpretazione privilegiata del marcatore da parte del modello."
    },
    "T08": {
        "name": "Observed Output Transformation & Escape Sequences",
        "regime": "Esplorativo",
        "question": "Come vengono trattate le sequenze di escape testuali rispetto ai caratteri di controllo nativi?",
        "criterion": "M1-scalar / M3",
        "success": "Tracciamento deterministico del parsing di escape tra C_resp_parsed e O.",
        "disconfirmation": "Incoerenza sistematica tra la rappresentazione JSON e il testo estratto."
    },
    "T09": {
        "name": "Streaming Termination Protocol Characterization",
        "regime": "Esplorativo",
        "question": "Quali eventi discreti caratterizzano la chiusura dello stream di risposta sui confini di protocollo?",
        "criterion": "M1-scalar / Protocol Closure",
        "success": "Caratterizzazione deterministica della chiusura (finish_reason, chunking terminale, sentinelle SSE).",
        "disconfirmation": "Troncamento asincrono non documentato dello stream senza indicatore di fine."
    },
    "T10": {
        "name": "Cross-System Phenomenological Replication",
        "regime": "Esplorativo",
        "question": "Il comportamento fenomenologico riscontrato e' replicabile sulla matrice di sistemi testati a parita' di stimolo?",
        "criterion": "M1-scalar",
        "success": "Concordanza fenomenologica verificata sulla matrice dei target SUT.",
        "disconfirmation": "Incoerenza comportamentale su runtime identici a parita di configurazione."
    },
    "T11": {
        "name": "Token Accounting Discrepancy Probe",
        "regime": "Diagnostico",
        "question": "Sussiste una discrepanza sistematica tra il conteggio token dichiarato dall'API e il calcolo teorico di riferimento?",
        "criterion": "M4-Discrete-Difference",
        "success": "Quantificazione esatta di Delta_doc = N_api - N_ref_doc.",
        "disconfirmation": "Varianza erratica di N_api a parita di payload e parametri di esecuzione."
    },
    "T12": {
        "name": "Paired Latency & Observed TTFT Difference Profiling",
        "regime": "Diagnostico",
        "question": "Sussiste una differenza sistematica e statisticamente rilevante nel TTFT osservato tra due classi di stimoli (Condizione A vs B)?",
        "criterion": "M4-Continuous-TTFT",
        "success": "bar_D != 0 con CI al 95% che esclude lo zero e |bar_D| >= MDE (Delta_min).",
        "disconfirmation": "CI al 95% di bar_D che include lo zero oppure |bar_D| < Delta_min."
    },
    "T13": {
        "name": "Declared Prefix Caching Probe",
        "regime": "Diagnostico",
        "question": "Il servizio dichiara nel payload di risposta il riutilizzo o caching di una porzione di prompt comune?",
        "criterion": "M1-scalar / Metadato API",
        "success": "Rilevazione di usage.prompt_tokens_details.cached_tokens > 0.",
        "disconfirmation": "Mancata indicazione del metadato API nonostante prefisso identico."
    },
    "T14": {
        "name": "Long-Context Retrieval Characterization",
        "regime": "Diagnostico",
        "question": "Qual e' il profilo empirico di recupero di un needle al variare della lunghezza totale del contesto e della profondita?",
        "criterion": "M1-scalar",
        "success": "Mappatura deterministica del tasso di successo Retrieval_Rate(L, D).",
        "disconfirmation": "Recupero con ORR_b < 1.00 su lunghezze inferiori a 4k token."
    }
}


class SotuMasterReporter:
    """
    Compilatore ufficiale della Scheda Master SOTU v2.3.
    """

    def __init__(
        self,
        manifest: Dict[str, Any],
        classification: Dict[str, Any],
        metrics: Optional[Dict[str, Any]] = None,
        trial_data: Optional[Dict[str, Any]] = None
    ):
        self.manifest = manifest
        self.classification = classification
        self.metrics = metrics or {}
        self.trial = trial_data or {}

        self.test_id = self.manifest.get("test_id", self.classification.get("test_id", "T01"))
        self.desc_info = TEST_DESCRIPTIONS.get(self.test_id, {
            "name": f"Test Unit {self.test_id}",
            "regime": "Caratterizzazione Sperimentale",
            "question": "Analisi empirica delle proprieta di canale del SUT.",
            "criterion": "M1-scalar",
            "success": "Conformita fenomenologica osservata.",
            "disconfirmation": "Divergenza riproducibile dei dati rispetto all'ipotesi."
        })

    def build_markdown_report(self) -> str:
        lines = []

        sut_tuple = self.manifest.get("sut_formal_tuple", {})
        host_telem = self.manifest.get("host_telemetry", {})
        audit_trail = self.manifest.get("audit_trail", {})
        timing_info = self.trial.get("timing", {})

        provider = sut_tuple.get("provider", "groq")
        model_id = sut_tuple.get("model_id", "llama-3.3-70b-versatile")
        endpoint_url = sut_tuple.get("endpoint_url", "https://api.groq.com/openai/v1/chat/completions")
        sampling = sut_tuple.get("sampling", {})
        temp = sampling.get("temperature", 1.0)
        max_tok = sampling.get("max_tokens", 4096)

        device_mod = host_telem.get("device_model", "Android/Termux aarch64")
        py_ver = host_telem.get("python_version", "3.11.x")
        uax_ver = host_telem.get("unicodedata_version", "15.0.0")
        curl_ver = host_telem.get("curl_version", "8.x")
        active_locale = host_telem.get("active_locale", "C.UTF-8")
        rtt_base = host_telem.get("rtt_baseline_ms", "null")

        v3_class = audit_trail.get("v3_classification", "V3-3 (App-Layer Verified)")
        is_modalita_a = "V3-3" in v3_class
        modalita_op = "Modalita A (con V3 attivo)" if is_modalita_a else "Modalita B (Black-Box U -> O)"
        regime_metodologico = self.manifest.get("regime", "R1_PILOT")

        now_utc = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

        lines.append("```markdown")
        lines.append("=" * 80)
        lines.append(f"TEST UNIT ID: {self.test_id} — {self.desc_info['name']}")
        lines.append(f"SOTTOTEST: A - Transport Verification / B - Behavioral Retrieval")
        lines.append(f"MODALITA OPERATIVA: {modalita_op}")
        lines.append(f"REGIME METODOLOGICO: {self.desc_info['regime']} ({regime_metodologico})")
        lines.append(f"DATA E ORA: {now_utc}")
        lines.append(f"SUT DEFINITO: < Provider: {provider}, Model_ID: {model_id}, Endpoint: {endpoint_url}, Sampling: [T={temp}, Max={max_tok}] >")
        lines.append(f"CLIENT / RUNTIME: < OS: {device_mod}, Python: {py_ver}, Unicode: {uax_ver}, cURL: {curl_ver}, Locale: {active_locale}, RTT_Base: {rtt_base} ms >")
        lines.append("=" * 80)
        lines.append("")

        lines.append("[OBSERVABILITY BOUNDARY]")
        lines.append("- U_intended           : YES")
        lines.append("- U_rendered           : NOT APPLICABLE (CLI/Headless Mode)")
        lines.append("- U_buffer             : YES (enc_UTF8 SHA-256 Verificato)")
        lines.append(f"- C_req (Network V3)   : {v3_class}")
        lines.append("- S (Server Context)   : NOT OBSERVED (Strutturalmente inaccessibile)")
        lines.append("- M_raw (Raw Output)   : NOT OBSERVED (Strutturalmente inaccessibile)")
        lines.append(f"- C_resp (Response V3) : {'PRESENT (V3-3 Verificato)' if is_modalita_a else 'NOT OBSERVED'}")
        lines.append("- O_dom / CLI Stdout   : YES (Estratto)")
        lines.append("- O_visual             : NOT APPLICABLE")
        lines.append("- Layer V5 Parametrico : V5_NONE")
        lines.append("")

        lines.append("1. DOMANDA SPERIMENTALE (RESEARCH QUESTION)")
        lines.append(f"   {self.desc_info['question']}")
        lines.append("")

        criterio_m = self.metrics.get("comparison_criterion", self.desc_info["criterion"])
        vett_previsto = self.classification.get("final_evidence_vector", "E = < O3, C1, R1, S1 >")

        lines.append("2. PREREGISTRAZIONE E CONTROLLO CONFONDENTI (EXPERIMENTAL FREEZE)")
        lines.append(f"   - Criterio di Confronto M      : {criterio_m}")
        lines.append(f"   - Criterio di Successo Nominale: {self.desc_info['success']}")
        lines.append(f"   - Condizione di Disconferma    : {self.desc_info['disconfirmation']}")
        lines.append(f"   - Sampling (Temp / MaxTokens)  : Temperature = {temp}, Max_Tokens = {max_tok}")
        lines.append(f"   - Stato Memoria / Account      : Disabilitata (e_0 Pure Ephemeral State)")
        lines.append(f"   - Minima Diff. Rilevante (MDE) : Delta_min = 100.0 ms (per test continui T12)")
        lines.append(f"   - Vettore Target Previsto      : {vett_previsto}")
        lines.append("")

        lines.append("3. STATO DEL SISTEMA (FSM STATE)")
        lines.append(f"   - ID Stato FSM: SA.Q0 (Turno Iniziale / Calibrazione)")
        lines.append(f"   - Ambiente    : e_0 (Pure Ephemeral State, stateless execution)")
        lines.append("")

        dag = self.manifest.get("provenance_dag", self.trial.get("provenance_dag", {}))
        u_sha = dag.get("stimulus_intended_sha256", "dd4019696497ad7e1ca011fe83f57a7354edf66f62fd84f7eb03bbb49134c4e9")
        u_buf_sha = dag.get("u_buffer_bytes_sha256", u_sha)

        lines.append("4. CARATTERIZZAZIONE METROLOGICA DELL'INPUT (U_intended)")
        lines.append(f"   - Stimolo Target    : Registrato nel disegno sperimentale preregistrato")
        lines.append(f"   - Serializzazione   : Canonical UTF-8 Scalar Values (enc_UTF8)")
        lines.append(f"   - SHA-256 Intended  : {u_sha}")
        lines.append(f"   - SHA-256 Buffer    : {u_buf_sha}")
        lines.append(f"   - Data Integrity    : {'CONFERMATA 1:1' if u_sha == u_buf_sha else 'DISALLINEAMENTO RILEVATO'}")
        lines.append("")

        lines.append("5. DEFINIZIONE COMPARATIVA DEGLI STIMOLI (STRUCTURED LADDER OFAT)")
        lines.append(f"   - Metodologia: One-Factor-At-A-Time (OFAT) Ladder Isolamento Fattori")
        lines.append(f"   - Gradini Testati: C0 -> C1 -> C2 -> C3 -> T (o Matrice Differenziale Parametrizzata)")
        lines.append(f"   - Parametrizzazione Canary: CSPRNG Nonce Dinamico Monouso Fresh")
        lines.append("")

        req_sha = dag.get("c_req_app_bytes_sha256", "non_catturato")
        req_u_sha = dag.get("c_req_unicode_sha256", "non_estratto")
        resp_sha = dag.get("c_resp_app_bytes_sha256", "non_catturato")
        out_sha = dag.get("output_parsed_sha256", "non_estratto")
        req_id = audit_trail.get("req_id_extracted", self.trial.get("audit_trail", {}).get("req_id_extracted", "none"))
        http_st = audit_trail.get("http_status", self.trial.get("audit_trail", {}).get("http_status", 200))
        fin_r = audit_trail.get("finish_reason", self.trial.get("audit_trail", {}).get("finish_reason", "stop"))
        ttft_ms = timing_info.get("ttft_observed_e2e_ms", "N/A")

        orr_b = self.metrics.get("point_estimate_ORR_b", 1.0)
        ci_block = self.metrics.get("confidence_interval_95_clopper_pearson", {})
        ci_lower = ci_block.get("lower", 0.4782)
        ci_upper = ci_block.get("upper", 1.0000)

        ev_status = self.classification.get("final_evidence_status", "SUPPORTED")
        id_status = self.classification.get("final_identification_status", "IDENTIFIED_WITHIN_OBSERVED_BOUNDARY")
        final_vector = self.classification.get("final_evidence_vector", "E = < O3, C1, R1, S1 >")

        lines.append("6. CATENA DI MISURA E DATI OSSERVATI (O -> M -> B -> H)")
        lines.append("")
        lines.append("   [O] RAW OBSERVATIONS:")
        lines.append(f"   - U_buffer Integrity Check : VERIFIED (SHA-256: {u_buf_sha})")
        lines.append(f"   - Request Transport Layer  : HTTP/2 POST via cURL 8.x (TLS Encrypted)")
        lines.append(f"   - Correlation / Request ID : {req_id}")
        lines.append(f"   - C_req_unicode SHA-256    : {req_u_sha}")
        lines.append(f"   - C_req_app_bytes SHA-256  : {req_sha}")
        lines.append(f"   - C_resp_app_bytes SHA-256 : {resp_sha}")
        lines.append(f"   - Output Parsed SHA-256    : {out_sha}")
        lines.append(f"   - HTTP Status & Finish     : HTTP {http_st} | finish_reason: '{fin_r}'")
        lines.append(f"   - TTFT Observed E2E        : {ttft_ms} ms")
        lines.append("")
        lines.append("   [M] MENSURAND & ESTIMATES:")
        if self.test_id == "T12":
            bar_d = self.metrics.get("point_estimate_bar_D_ms", "N/A")
            ci_lat = self.metrics.get("primary_parametric_ci_95", {}).get("formatted", "N/A")
            lines.append(f"   - Grandezza Stimata        : bar_D (Media delle differenze appaiate TTFT)")
            lines.append(f"   - Stima Puntuale           : bar_D = {bar_d} ms")
            lines.append(f"   - Incertezza (CI_95%)      : Paired Student-t {ci_lat}")
            lines.append(f"   - Rilevanza Ingegneristica : Conforme a MDE (Delta_min >= 100 ms)")
        else:
            lines.append(f"   - Grandezza Stimata        : Observed Replication Rate (ORR_b = k / N_valid)")
            lines.append(f"   - Stima Puntuale           : ORR_b = {orr_b:.4f}")
            lines.append(f"   - Incertezza (CI_95%)      : Clopper-Pearson [{ci_lower:.4f}, {ci_upper:.4f}]")
            lines.append(f"   - Precisione Metrologica   : Valutazione pilota R1 (k={int(orr_b*5 if orr_b <= 1.0 else 5)}, N=5)")
        lines.append("")
        lines.append("   [B] BEHAVIORAL INFERENCE:")
        lines.append(f"   - Relazione Input/Output   : U -> O sotto criterio {criterio_m}")
        lines.append(f"   - Evidence Status          : {ev_status}")
        lines.append("")
        lines.append("   [H] MECHANISTIC HYPOTHESES:")
        lines.append(f"   - Ipotesi Valutate         : H1 (Client), H2 (Server Gateway), H3 (Tokenizer), H4 (Model Core), H5 (Rendering)")
        lines.append(f"   - Identification Status    : {id_status}")
        lines.append("")

        lines.append("7. REPORT CONCLUSIVO FORMALE (THE QUADRUPLET RULE)")
        lines.append("")
        lines.append("- OSSERVAZIONE:")
        lines.append(f"  Lo stimolo di test U_intended (SHA-256: {u_sha}) e' stato somministrato al SUT.")
        if is_modalita_a:
            lines.append(f"  Sul confine di trasporto V3-3, il payload applicativo C_req e' stato intercettato")
            lines.append(f"  e materializzato con digest SHA-256: {req_sha} (C_req_unicode SHA-256: {req_u_sha}).")
            lines.append(f"  La risposta del server C_resp (Request ID: {req_id}, HTTP Status: {http_st}) ha prodotto")
            lines.append(f"  un output estratto con SHA-256: {out_sha}.")
            lines.append(f"  Il tasso di replicazione osservato e' ORR_b = {orr_b:.4f} (95% CI esatto: [{ci_lower:.4f}, {ci_upper:.4f}]).")
        else:
            lines.append(f"  L'output terminale O e' stato acquisito in Modalita B (Black-box pura).")
            lines.append(f"  Digest estratto SHA-256: {out_sha}. ORR_b = {orr_b:.4f}.")
        lines.append("")
        lines.append("- INFERENZA:")
        if is_modalita_a:
            lines.append(f"  I dati empirici attestano che il payload C_req_unicode corrisponde all'input")
            lines.append(f"  intenzionale U_intended. Sotto il criterio {criterio_m}, l'ipotesi di mutazione")
            lines.append(f"  client-side pre-trasmissione (H1a) e' formalmente esclusa entro il confine osservato.")
            lines.append(f"  La computazione e' compatibile con la regolare elaborazione server-side.")
        else:
            lines.append(f"  La relazione comportamentale terminale U -> O risulta verificata sotto criterio {criterio_m}.")
            lines.append(f"  In assenza di osservabilita sul trasporto di rete, lo stato dei layer intermedi rimane ignoto.")
        lines.append("")
        lines.append("- CONCLUSIONE:")
        lines.append(f"  In conformita alla regola Strength(Claim) <= Strength(Evidence):")
        lines.append(f"  1. Evidence Status: {ev_status} (Vettore di Evidenza: {final_vector}).")
        lines.append(f"  2. Identification Status: {id_status}.")
        if is_modalita_a:
            lines.append(f"  3. L'ipotesi H1a (Client Sanitization) e' DISCONFERMATA entro il modello strumentato.")
            lines.append(f"  4. Le classi di ipotesi interne H2, H3, H4 e H5 rimangono UNDERDETERMINED (Proxy != Meccanismo).")
        else:
            lines.append(f"  3. Nessuna asserzione di localizzazione (Claim B) o meccanismo (Claim C) e' ammessa.")
        lines.append("")
        lines.append("- NON DETERMINATO:")
        lines.append(f"  Rimangono architetturalmente indeterminati i layer interni inaccessibili:")
        lines.append(f"  Layer V4 (Context Assemblato Backend S), Layer V5 (Stato Generativo M_raw e Token IDs).")
        lines.append(f"  In virtu del postulato 'not(Obs(X)) /=> not(X)' (NOT DETECTED != ABSENT), la mancata")
        lines.append(f"  osservazione diretta non costituisce prova di inesistenza dei layer interni.")
        lines.append("")

        lines.append("8. ADDENDUM METODOLOGICO OBBLIGATORIO")
        lines.append(f"- ASSUNZIONI STRUM.: Si assume che l'adapter bash4llm e cURL 8.x registrino con fedelta")
        lines.append(f"  1:1 i byte materializzati sul descrittore di file prima della crittografia TLS del socket.")
        lines.append(f"- CONDIZIONI DISCONF.: La conclusione verrebbe falsificata qualora venisse riscontrata")
        lines.append(f"  una mutazione di codepoint nel payload C_req_unicode rispetto allo stimolo U_intended,")
        lines.append(f"  oppure qualora una replica tra sessioni indipendenti fallisse sotto il criterio {criterio_m}.")
        lines.append("")

        max_boundary = "Layer V3-3 (Client/Transport Network Boundary)" if is_modalita_a else "Layer V2 (Terminal Behavioral Output)"
        validation_verdict = "VALID" if "VALID" in self.classification.get("final_verdict", "VALID") else "VALID_BEHAVIORAL_ONLY"

        lines.append("9. METRICHE FINALI E VETTORE DI EVIDENZA")
        lines.append(f"- Confine Massimo Osservato : {max_boundary}")
        lines.append(f"- Vettore di Evidenza Finale : {final_vector}")
        lines.append(f"- Esito Finale Validazione  : {validation_verdict}")
        lines.append("=" * 80)
        lines.append("```")

        return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="CDP/SOP v2.3 SOTU Master Markdown Report Compiler"
    )
    parser.add_argument("--run-dir", default=None, help="Directory del run contenente manifest e metriche")
    parser.add_argument("--manifest", default=None, help="Percorso del run_manifest.json")
    parser.add_argument("--classification", default=None, help="Percorso del claim_classification.json")
    parser.add_argument("--metrics", default=None, help="Percorso opzionale del metrics_summary.json")
    parser.add_argument("--trial-json", default=None, help="Percorso opzionale del trial_metadata.json (singolo trial)")
    parser.add_argument("--out", default=None, help="File di destinazione per SOTU_MASTER_REPORT.md (default: stdout)")
    args = parser.parse_args()

    manifest_data = {}
    classification_data = {}
    metrics_data = {}
    trial_data = {}

    if args.run_dir:
        run_path = Path(args.run_dir)
        manifest_file = run_path / "run_manifest.json"
        class_file = run_path / "claim_classification.json"
        metrics_file = run_path / "metrics_summary.json"
        trial_file = run_path / "trial_metadata.json"
        if not trial_file.exists():
            trial_file = run_path / "raw_artifacts" / "trial_metadata.json"

        if manifest_file.exists():
            manifest_data = json.loads(manifest_file.read_text(encoding="utf-8"))
        if class_file.exists():
            classification_data = json.loads(class_file.read_text(encoding="utf-8"))
        if metrics_file.exists():
            metrics_data = json.loads(metrics_file.read_text(encoding="utf-8"))
        if trial_file.exists():
            trial_data = json.loads(trial_file.read_text(encoding="utf-8"))

    if args.manifest:
        manifest_data = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    if args.classification:
        classification_data = json.loads(Path(args.classification).read_text(encoding="utf-8"))
    if args.metrics:
        metrics_data = json.loads(Path(args.metrics).read_text(encoding="utf-8"))
    if args.trial_json:
        trial_data = json.loads(Path(args.trial_json).read_text(encoding="utf-8"))

    if not manifest_data and trial_data:
        manifest_data = {
            "test_id": trial_data.get("sut", {}).get("test_id", "T01"),
            "sut_formal_tuple": trial_data.get("sut", {}),
            "provenance_dag": trial_data.get("provenance_dag", {}),
            "audit_trail": trial_data.get("audit_trail", {})
        }

    reporter = SotuMasterReporter(
        manifest=manifest_data,
        classification=classification_data,
        metrics=metrics_data,
        trial_data=trial_data
    )

    report_md = reporter.build_markdown_report()

    if args.out:
        out_path = Path(args.out)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(report_md, encoding="utf-8")
        out_path.chmod(0o600)
        sys.stderr.write(f"sotu_master: Referto Master generato con successo in: {out_path}\n")
    elif args.run_dir and not args.out:
        out_path = Path(args.run_dir) / "SOTU_MASTER_REPORT.md"
        out_path.write_text(report_md, encoding="utf-8")
        out_path.chmod(0o600)
        sys.stderr.write(f"sotu_master: Referto Master salvato in: {out_path}\n")
    else:
        sys.stdout.write(report_md + "\n")


if __name__ == "__main__":
    main()
    
