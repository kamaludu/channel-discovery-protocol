# PIANO ESECUTIVO INTEGRALE: CDP/SOP v2.3 METROLOGY HARNESS
### *Specifiche di Progetto, Architettura Modulare e Contratti Software per Android/Termux*
**Standard di Riferimento:** *Channel Discovery Protocol (CDP v2.3)* e *Standard Operating Procedure (SOP v2.3)*  
**Target System Under Test (SUT):** *API Remote / Runtime LLM invocati tramite Adapter bash4llm (v2.8.5.3)*  
**Stato del Documento:** *SPECIFICATION — APPROVED*

---

```text
================================================================================
                    INDICE DEL PIANO ESECUTIVO DEFINITIVO
================================================================================
  1. Topologia Sistemica, Assiomi e Regole di Invarianza Metrologica
  2. Requisiti di Sistema, Runtime Termux e Igiene di Shell
  3. Alberatura del Workspace e File Inventory
  4. Specifiche Tecniche Dettagliate Modulo per Modulo
  5. Schemi JSON dei Contratti Dati (Provenance DAG & Metrics)
  6. Algoritmi Statistici e Matrice di Classificazione Deterministica
  7. Protocollo Esecutivo delle Fasi Sperimentali (RUN 0, T01 – T14)
  8. Roadmap di Implementazione Step-by-Step
================================================================================
```

---

## 1. TOPOLOGIA SISTEMICA E ASSIOMI METROLOGICI

### 1.1 Quadrupla Sistemica Formalizzata
Il sistema separa rigorosamente l'infrastruttura di test dal modello indagato:

```text
[ CDP Orchestrator ] (Harness Master in Bash 4.0+)
       |
       v (Parametri CLI, isolamento env, lockfile)
[ Invocation Adapter ] (bash4llm v2.8.5.3: Vault OpenSSL, rate limiting, payload staging)
       |
       v (Materializzazione su disco 0600: payload.json / resp.json)
[ Transport Instrumentation ] (cURL 8.x / POSIX FS capture: C_req_app_bytes, C_resp_app_bytes)
       |
       v (Trasmissione di rete TLS / HTTP/2)
[ System Under Test (SUT) ] (Remote API Gateway, Context Builder S, LLM Core M_raw)
```

```text
SUT = < Provider, Endpoint_URL, Model_ID, Declared_Runtime, Sampling_Params >
Adapter = < bash4llm_v2.8.5.3, Execution_Flags, Shell_Environment >
Instrument = < cURL_8.x, POSIX_File_Capture, Python_3.11_stdlib_Metrology >
```

### 1.2 Regole Cardinali di Invarianza

1. **Conservativita' Epistemica (Golden Rule):**
```text
Strength(Claim) <= Strength(Evidence)
```

2. **Proxy != Meccanismo:** L'identita' di output `(U == C_req_app == O)` dimostra preservazione della sequenza lungo i confini osservati, ma **non identifica alcun componente interno** del SUT (`S` e `M_raw` rimangono `UNDERDETERMINED`).

3. **Catena di Custodia V3-3:** Assegnata solo se sono verificati congiuntamente i quattro predicati deterministici:
```text
V3-3 <===> ( P_app_request_observed AND P_fingerprint_match AND P_response_correlation AND P_harness_isolation )
```
*(La concorrenza esterna al processo harness e' formalmente registrata come `P_external_concurrency = UNKNOWN`).*

4. **Stratificazione della Provenienza dell'Output:**
```text
Claim(SUT_produced(O)) <= VERIFIED
Claim(Invocation_returned(O)) <= ATTRIBUTED
```
*(Output orfano o non associabile <= `UNKNOWN`, con conseguente annullamento del trial per inferenze sul SUT).*

5. **Esclusione dell'LLM dal Circuito Decisionale:** L'assegnazione degli stati (`SUPPORTED`, `DISCONFIRMED`, `IDENTIFIED_WITHIN_OBSERVED_BOUNDARY`, `NOT IDENTIFIED`, `UNDERDETERMINED`) e' delegata a un **Deterministic Claim Classification Engine** basato su regole logiche compilate.

---

## 2. REQUISITI DI SISTEMA E AMBIENTE (TERMUX)

### 2.1 Pacchetti e Strumenti di Sistema
* **Shell:** `bash` (`>= 4.0`) con opzioni rigide `set -euo pipefail`.
* **POSIX & Core Utils:** `coreutils`, `findutils`, `util-linux`, `gawk`, `sed`, `grep`.
* **Rete e Parsing:** `curl` (`>= 8.0`), `jq` (`>= 1.6`).
* **Crittografia & Dump:** `openssl` (`>= 1.1.1` o `3.x`), `xxd` (per ispezione esadecimale byte per byte).
* **Interprete Python:** `python` (`>= 3.10`), **RIGOROSAMENTE ZERO-PIP** (solo standard library: `math`, `hashlib`, `unicodedata`, `json`, `sys`, `os`, `secrets`, `time`, `pathlib`, `argparse`).

### 2.2 Igiene OPSEC e Ambientale
* **Variabili Forzate:** `LC_ALL=C.UTF-8` e `LANG=C.UTF-8` in tutti gli script per prevenire mutazioni di codepoints a zero-width o multibyte.
* **Minimizzazione Dati:** Mascheramento totale di header `Authorization`, cookie e token nei file di log (`chmod 600` per i file, `chmod 700` per le directory, `umask 077`).
* **RAM Protection:** `ulimit -c 0` attivo per bloccare dump di memoria su crash.

---

## 3. ALBERATURA DEL WORKSPACE E FILE INVENTORY

L'harness opera interamente all'interno della sandbox protetta `~/cdp_workspace/`:

```text
~/cdp_workspace/
├── cdp_run.sh                     # [MOD-01] Orchestratore Principale e CLI Entrypoint
├── core/
│   ├── env_telemetry.sh           # [MOD-02] Sonda Telemetrica Termux e Profiling Ambientale
│   ├── sut_adapter.sh             # [MOD-03] Wrapper trasparente e isolato per bash4llm
│   └── ofat_builder.py            # [MOD-04] Generatore CSPRNG Canary & Ladder OFAT
├── metrology/
│   ├── uax_engine.py              # [MOD-05] Gestore Forme Normalizzate UAX #15 e Policy UAX #29
│   ├── cdp_stats.py               # [MOD-06] Engine Statistico Preregistrato (Clopper-Pearson, t-test, Bootstrap)
│   └── claim_classifier.py        # [MOD-07] Deterministic Claim Classification Engine (DAG)
├── reporters/
│   ├── campaign_dashboard.py.     # [MOD-09] Generatore Dossier di Campagna e Matrice Decadimento T14
│   └── sotu_master.py             # [MOD-08] Compilatore Scheda Master SOTU v2.3 (Quadruplet Rule)
└── runs/                          # Storage Immutabile delle Sessioni Sperimentali
    └── RUN_<TIMESTAMP>_<NONCE>/
        ├── run_manifest.json      # Provenance DAG, impronta hardware e metadata
        ├── calibration_run0.md    # Verbale ufficiale RUN 0
        ├── raw_artifacts/         # File binari payload, JSON di rete, dump xxd
        ├── metrics_summary.json   # Grandezze M misurate, CI 95%, test statistici
        └── SOTU_MASTER_REPORT.md  # Referto finale SOTU v2.3 pronto per l'archiviazione
```

---

## 4. SPECIFICHE TECNICHE DETTAGLIATE MODULO PER MODULO

---

### [MOD-01] `cdp_run.sh` — Orchestratore Principale e CLI Entrypoint
* **Linguaggio:** POSIX Bash 4.0+
* **Permessi:** `chmod 700`
* **Scopo:** Punto di ingresso unificato per l'esecuzione dei test CDP (da RUN 0 a T14). Gestisce il parsing dei parametri, l'inizializzazione del workspace, la creazione della sessione immutabile e la sequenza delle chiamate tra moduli.
* **Perché è necessario:** Coordina la catena metrologica garantendo che nessun test possa essere eseguito senza preliminare calibrazione RUN 0 e registrazione della telemetria ambientale.
* **Argomenti CLI Supportati:**
  * `--test <ID>`: ID test da eseguire (`RUN0`, `T01`, `T02`, `T03`, `T04`, `T05`, `T06`, `T07`, `T08`, `T09`, `T10`, `T11`, `T12`, `T13`, `T14` o `ALL_FOUNDATIONAL`).
  * `--regime <pilot|confirmatory>`: Regime di prova (`R1` con `N = 5` vs `R2` parametrico vincolato).
  * `--provider <name>`: Override esplicito del provider (es. `groq`, `mistral`).
  * `--model <id>`: Override esplicito del Model ID.
  * `--mde <val>`: Minima Differenza Rilevante per test continui (ms per T12, token per T11). Default: 100 ms.
  * `--debug`: Modalità diagnostica dettagliata con preservazione log intermedi.
* **Logica Operativa:**
  1. Verifica integrità ambiente (chiamata a `core/env_telemetry.sh`).
  2. Generazione UUID/Nonce di sessione e creazione cartella `runs/RUN_<TIMESTAMP>_<NONCE>/`.
  3. Esecuzione del test selezionato invocando l'OFAT builder, l'adapter SUT e raccogliendo gli artefatti grezzi.
  4. Invocazione della pipeline metrologica Python (`metrology/` -> `reporters/`).

---

### [MOD-02] `core/env_telemetry.sh` — Sonda Telemetrica Termux
* **Linguaggio:** POSIX Bash 4.0+
* **Permessi:** `chmod 700`
* **Scopo:** Rilevare l'impronta esatta del sistema host (Android/Termux), misurare la baseline di latenza di rete (RTT) e validare la conformità POSIX/Locale.
* **Perché è necessario:** Il test T12 misura `TTFT_observed_e2e`. Senza la caratterizzazione dell'hardware, della versione kernel, dell'interprete e del jitter di rete, qualsiasi variazione temporale risulterebbe inquinata da confondenti non documentati.
* **Dati Raccolti ed Emessi (JSON):**
  * `device_model`, `android_version`, `kernel_release`, `cpu_arch`.
  * `bash_version`, `curl_version`, `openssl_version`, `python_version`.
  * `active_locale` (Verifica che `LC_ALL == C.UTF-8`).
  * `rtt_baseline_ms` (Mediana su 5 ping/curl HTTP HEAD verso l'endpoint provider target).
  * `timestamp_epoch_utc`.

---

### [MOD-03] `core/sut_adapter.sh` — Wrapper Trasparente per `bash4llm`
* **Linguaggio:** POSIX Bash 4.0+
* **Permessi:** `chmod 700`
* **Scopo:** Interfacciare l'orchestratore con `bash4llm` garantendo l'acquisizione dei file materializzati (`C_req_app_bytes` e `C_resp_app_bytes`), l'isolamento dei descrittori di file e la gestione dei lock.
* **Perché è necessario:** Isola `bash4llm` come componente di invocazione locale. Cattura gli artefatti applicativi dal runtime tmpdir prima che vengano epurati dal cleanup di uscita, calcolandone immediatamente il digest SHA-256.
* **Meccanica Interna:**
  1. Imposta `DEBUG_PRESERVE=1` e definisce un `RUN_TMPDIR` dedicato e isolato sotto `~/cdp_workspace/tmp/`.
  2. Invoca `bash4llm` con i flag `--no-stream`, `--json`, `--nosave`.
  3. Preleva:
     * File `$PAYLOAD` (o decodifica `$PAYLOAD.b64`) -> salvato come `raw_artifacts/C_req_app.bin`.
     * File `$RESP` -> salvato come `raw_artifacts/C_resp_app.json`.
     * File `$ERRF` / exit code cURL -> salvato come `raw_artifacts/cURL.log`.
     * File `ui_state/last_api.json` per estrazione di `req_id` e `http_status`.
  4. Rilascia e distrugge la cartella temporanea locale nel rispetto dei permessi `0700`.

---

### [MOD-04] `core/ofat_builder.py` — Generatore CSPRNG Canary & Ladder OFAT
* **Linguaggio:** Python 3.10+ (Standard Library: `secrets`, `hashlib`, `json`, `argparse`)
* **Permessi:** `chmod 600`
* **Scopo:** Costruire programmaticamente le stringhe di stimolo canonico `U_intended`, i canary parametrizzati con nonce fresh e le structured ladder OFAT per ciascun test (T01–T14).
* **Perché è necessario:** Garantisce che nessun nonce sia riutilizzato tra sessioni indipendenti e certifica il digest SHA-256 pre-invio di ogni gradino della scala sperimentale.
* **Struttura degli Stimoli Emessi:**
  * **RUN 0 (`U_ref`):** `CANARY#7F3A91#OMEGA` (19 scalari ASCII, SHA-256 live verificato contro `dd4019696497ad7e1ca011fe83f57a7354edf66f62fd84f7eb03bbb49134c4e9`).
  * **T01 (Canary Preservation Ladder):**
    * `C^0`: `CANARY`
    * `C_1`: `CANARY#`
    * `C_2`: `CANARY#<NONCE_HEX_6>`
    * `C_3`: `CANARY#<NONCE_HEX_6>#`
    * `T`: `CANARY#<NONCE_HEX_6>#<SUFFIX_HEX_5>`
  * **T02 (Whitespace & Control Matrix):**
    * `T02-A`: `ALPHA` + `\u0020`*4 + `BETA`
    * `T02-B`: `ALPHA` + `\t` + `BETA`
    * `T02-C`: `ALPHA` + `\n`*3 + `BETA`
    * `T02-D`: `\n\n` + `ALPHA` (Leading)
    * `T02-E`: `ALPHA` + `\n\n` (Trailing)
  * **T03 (Unicode Normalization Matrix):**
    * `U_NFC`: `\u00e9` (`é` precomposta)
    * `U_NFD`: `\u0065\u0301` (`e` + combining acute)
    * `U_NFKC`: `\ufb01` (legatura `fi`)
    * `U_NFKD`: `\u0066\u0069` (`f` + `i` disgiunte)
  * **T04 (Invisible/Format Characters):**
    * `T04-A`: `ALPHA` + `\u200b` (ZWSP) + `BETA`
    * `T04-B`: `ALPHA` + `\u200c` (ZWNJ) + `BETA`
    * `T04-C`: `ALPHA` + `\ufeff` (In-stream BOM/ZWNBSP) + `BETA`

---

### [MOD-05] `metrology/uax_engine.py` — Gestore UAX #15 e Policy UAX #29
* **Linguaggio:** Python 3.10+ (Standard Library: `unicodedata`, `json`, `sys`)
* **Permessi:** `chmod 600`
* **Scopo:** Eseguire l'analisi delle trasformazioni di normalizzazione canonica e di compatibilità (`M2a`) e formalizzare lo stato di indisponibilità per `UAX #29` (`M2b`).
* **Perché è necessario:** Impedisce di assumere che una stringa in input rappresenti di per sé l'intenzione del modello e dichiara formalmente `UNAVAILABLE` per algoritmi di segmentazione che richiederebbero tabelle di proprietà derivate non esposte dalla standard library.
* **Funzionalità e Contratti:**
  1. `get_unicode_telemetry()`: Restituisce `unicodedata.unidata_version` e `sys.version`.
  2. `decompose_normalization_profile(text_bytes)`: Calcola le 4 forme standard (NFC, NFD, NFKC, NFKD) sia sul payload in ingresso `C_req_app` sia sull'output `O`.
  3. `evaluate_m2a_equivalence(s1, s2, form)`: Verifica la relazione:
```text
s1 ~_Norm s2 <===> Norm(s1) == Norm(s2)
```
  4. `M2B_POLICY`: Dichiara costantemente `M2b_STATUS = UNAVAILABLE_IN_STDLIB_MODE`.

---

### [MOD-06] `metrology/cdp_stats.py` — Engine Statistico Preregistrato
* **Linguaggio:** Python 3.10+ (Standard Library: `math`, `json`, `secrets`)
* **Permessi:** `chmod 600`
* **Scopo:** Calcolare in modo deterministico e non retroattivo tutti gli stimatori puntuali e gli intervalli di confidenza per variabili discrete e continue.
* **Perché è necessario:** Elimina qualsiasi arbitrio post-hoc nella scelta del test statistico o nella gestione degli outlier.
* **Formule e Metodi Implementati:**

1. **Exact Clopper-Pearson 95% Confidence Interval (Binomiale):**
Calcolo esatto dei limiti inferiore (`L`) e superiore (`U`) per `k` successi su `N_valid` prove tramite bisezione numerica sulla distribuzione Beta cumulativa incompleta regolarizzata `I_x(a, b)`:
```text
If k == 0:
    L = 0
    U = 1 - (alpha / 2)^(1 / N)

If k == N:
    L = (alpha / 2)^(1 / N)
    U = 1

If 0 < k < N:
    L e' la radice x di: I_x(k, N - k + 1) == alpha / 2
    U e' la radice x di: I_x(k + 1, N - k) == 1 - (alpha / 2)
```
*(Per `N = 5, k = 5, alpha = 0.05` ==> `[0.4782, 1.0000]`)*.

2. **Paired Difference Analysis per TTFT (T12):**
* Mensurando:
```text
D_i = TTFT_observed_e2e(B, i) - TTFT_observed_e2e(A, i)
bar_D = (1 / N) * sum(i=1 to N, D_i)
s_D = sqrt( (1 / (N - 1)) * sum(i=1 to N, (D_i - bar_D)^2) )
```
* **Analisi Primaria:**
```text
CI_95%(bar_D) = [ bar_D - t_crit * (s_D / sqrt(N)), bar_D + t_crit * (s_D / sqrt(N)) ]
```
* **Analisi Secondaria (Sensitivity Analysis):** Paired Bootstrap non parametrico (`B = 10000` repliche appaiate con calcolo dell'intervallo percentile).
* **Criterio di Rilevanza Ingegneristica:** Flag booleano `is_practically_relevant` attivo se e solo se:
```text
(0 not in CI_95%(bar_D)) AND (abs(bar_D) >= Delta_min)
```

3. **Power Analysis A Priori per Regime R2:**
Calcolo di `N_calc` da MDE (`Delta_min`), `alpha = 0.05`, `1 - beta = 0.80` e stima della varianza `(s_(D, pilot))^2` derivata da `R1`.

---

### [MOD-07] `metrology/claim_classifier.py` — Deterministic Claim Classification Engine
* **Linguaggio:** Python 3.10+ (Standard Library: `json`, `sys`, `pathlib`)
* **Permessi:** `chmod 600`
* **Scopo:** Valutare la quadrupla empirica `< U, C_req_app, C_resp_app, O >`, l'audit di trasporto `V3` e l'asse `OUTPUT_PROVENANCE` per emettere deterministicamente gli stati di evidenza e il Vettore `E`.
* **Perché è necessario:** È il cuore dell'integrità epistemica. Nessun LLM e nessuna euristica opaca decidono la conclusione. Il rule engine implementa rigidamente la tavola di verità della Sezione 10 della SOP v2.3.
* **Albero Logico delle Decisioni (DAG):**

```text
[ Input: Trial Data & Provenance ]
               |
               |--> TRANSPORT_OBSERVED == FALSE?
               |     |--> PROVENANCE in { VERIFIED, ATTRIBUTED }
               |     |     |--> Modalita B: Evidence = SUPPORTED (End-to-End Solo)
               |     |          Identification = NOT IDENTIFIED
               |     |          Vettore E = < O1, C0, R_x, S1 >
               |     |
               |     |--> PROVENANCE == UNKNOWN
               |           |--> Esito: OUTPUT_OBSERVED_UNATTRIBUTED (Trial nullo per inferenza SUT)
               |
               |--> TRANSPORT_OBSERVED == TRUE (V3-3 Verificato)
                     |
                     |--> Diff(U, C_req_app) != 0?
                     |     |--> Mutation Status: LOCAL_PRE_TRANSPORT_MUTATION
                     |          Identification = IDENTIFIED_WITHIN_OBSERVED_BOUNDARY
                     |          Vettore E = < O3, C1, R_x, S3 >
                     |
                     |--> Diff(U, C_req_app) == 0 AND Diff(C_req_app, O) == 0?
                     |     |--> Evidence Status: SUPPORTED
                     |          Identification = IDENTIFIED_WITHIN_OBSERVED_BOUNDARY
                     |          Vettore E = < O3, C1, R_x, S1 >
                     |
                     |--> Diff(U, C_req_app) == 0 AND Diff(C_req_app, O) != 0?
                           |--> Evidence Status: SUPPORTED (Post-Client Mut.)
                                Identification = UNDERDETERMINED (tra H2, H3, H4, H5)
                                Vettore E = < O3, C1, R_x, S5 >
```

---

### [MOD-08] `reporters/sotu_master.py` — Compilatore Scheda Master SOTU v2.3
* **Linguaggio:** Python 3.10+ (Standard Library: `json`, `pathlib`, `string`)
* **Permessi:** `chmod 600`
* **Scopo:** Assemblare tutti i dati osservati, i mensurandi `M`, i calcoli statistici e le decisioni del rule engine nel report ufficiale Markdown conforme alla Scheda Master della Sezione 6 e 7 della SOP v2.3.
* **Sezioni Compilate Obbligatorie:**
  1. Intestazione SUT e Parametri di Esecuzione.
  2. Observability Boundary Checklist.
  3. Structured Ladder OFAT e Tabella dei Digest SHA-256.
  4. Catena Metrologica `O -> M -> B -> H`.
  5. **The Quadruplet Rule:**
     * `OSSERVAZIONE`: Sintesi puramente descrittiva dei byte e dei codepoint grezzi.
     * `INFERENZA`: Spazio delle ipotesi residue qualificate sotto il criterio `M`.
     * `CONCLUSIONE`: Stati certificati sotto il vincolo `Strength(Claim) <= Strength(Evidence)`.
     * `NON DETERMINATO`: Esplicitazione formale dei layer inaccessibili (`S`, `M_raw`).
  6. **Addendum Metodologico Obbligatorio:** Assunzioni strumentali e condizioni empiriche di disconferma.
  7. Metriche Finali e Vettore di Evidenza `E = < O_x, C_x, R_x, S_x >`.

---

## 5. SCHEMI JSON DEI CONTRATTI DATI

### 5.1 `run_manifest.json` (Provenance DAG & Session Metadata)
```json
{
  "protocol_version": "CDP-v2.3 / SOP-v2.3",
  "session_id": "SES_7F3A91_20260821",
  "test_id": "T01",
  "regime": "R1_PILOT",
  "sut_formal_tuple": {
    "provider": "groq",
    "endpoint_url": "https://api.groq.com/openai/v1/chat/completions",
    "model_id": "llama-3.3-70b-versatile",
    "declared_runtime": "cloud-api",
    "sampling": {
      "temperature": 1.0,
      "max_tokens": 4096,
      "stream_mode": false
    }
  },
  "adapter_metadata": {
    "adapter_name": "bash4llm",
    "adapter_version": "2.8.5.3",
    "adapter_flags": "--no-stream --json --nosave"
  },
  "host_telemetry": {
    "device_model": "Android/Termux aarch64",
    "android_version": "14",
    "kernel_release": "5.15.x",
    "python_version": "3.11.8",
    "unicodedata_version": "15.0.0",
    "curl_version": "8.6.0",
    "active_locale": "C.UTF-8",
    "rtt_baseline_ms": 41.8
  },
  "concurrency_state": {
    "P_harness_isolation": true,
    "P_external_concurrency": "UNKNOWN (Non-observable without OS-wide tracing)"
  },
  "provenance_dag": {
    "stimulus_intended_sha256": "dd4019696497ad7e1ca011fe83f57a7354edf66f62fd84f7eb03bbb49134c4e9",
    "u_buffer_bytes_sha256": "dd4019696497ad7e1ca011fe83f57a7354edf66f62fd84f7eb03bbb49134c4e9",
    "c_req_app_bytes_sha256": "b812f9a7c3...",
    "c_resp_app_bytes_sha256": "19a4e8d2c0...",
    "output_parsed_sha256": "9f7b2a11e4..."
  },
  "audit_trail": {
    "req_id_match": true,
    "req_id_extracted": "chatcmpl-7f3a91",
    "v3_classification": "V3-3 (App-Layer Verified)",
    "v3_motivation": "Materialized JSON request hash verified and response correlation ID matched with invocation isolation."
  }
}
```

---

### 5.2 `metrics_summary.json` (Grandezze M e Statistica)
```json
{
  "test_id": "T01",
  "comparison_criterion": "M1-scalar",
  "sample_size_intended": 5,
  "sample_size_valid": 5,
  "execution_outcomes": {
    "VALID_TRIAL": 5,
    "PHENOMENOLOGICAL_TERMINATION": 0,
    "INVALID_STIMULUS": 0,
    "INVALID_ENVIRONMENT": 0,
    "INVALID_MEASUREMENT": 0
  },
  "point_estimate_ORR_b": 1.0,
  "confidence_interval_95_clopper_pearson": {
    "lower": 0.4782,
    "upper": 1.0000,
    "confidence_level": 0.95,
    "method": "Exact Binomial Beta Distribution"
  },
  "latency_metrics": null,
  "mde_relevance_check": null
}
```

---

## 6. ALGORITMI STATISTICI E MATRICE DELLE DECISIONI

### 6.1 Calcolo Esatto di Clopper-Pearson (Python Stdlib Puro)
Dati `k` successi su `N` prove valide, i limiti dell'intervallo `[L, U]` al livello di confidenza `1 - alpha` (`alpha = 0.05`) sono formalmente calcolati tramite la funzione di distribuzione Beta cumulativa incompleta regolarizzata `I_x(a, b)`:
* Se `k == 0` ==> `L = 0`, `U = 1 - (alpha / 2)^(1 / N)`
* Se `k == N` ==> `L = (alpha / 2)^(1 / N)`, `U = 1`
* Per `0 < k < N`:
  * `L` è la radice `x` di: `I_x(k, N - k + 1) == alpha / 2`
  * `U` è la radice `x` di: `I_x(k + 1, N - k) == 1 - (alpha / 2)`
* *Implementazione:* Risoluzione esatta tramite bisezione numerica con tolleranza `epsilon = 10^(-7)` su integrale di Beta implementato con `math.gamma`.

---

### 6.2 Matrice degli Stati dei Trial e Provenance

```text
+---------------------+-------------------+-------------------+--------------------------------------------+
| TRANSPORT_OBSERVED  | OUTPUT_OBSERVED   | OUTPUT_PROVENANCE | CLASSIFICAZIONE TRIAL                      |
+---------------------+-------------------+-------------------+--------------------------------------------+
| TRUE (V3-3)         | TRUE              | VERIFIED          | VALID_TRIAL (Full Modalita A)              |
| TRUE (V3-3)         | FALSE             | N/A               | CORRUPT_STREAM (Trial Invalido Trasporto)  |
| FALSE (V3-0a)       | TRUE              | VERIFIED          | BEHAVIORAL_ONLY_TRIAL (Modalita B SUT-Ver.)|
| FALSE (V3-0a)       | TRUE              | ATTRIBUTED        | BEHAVIORAL_ONLY_TRIAL (Modalita B Invoc.)  |
| FALSE (V3-0a)       | TRUE              | UNKNOWN           | OUTPUT_OBSERVED_UNATTRIBUTED (Trial Nullo) |
| FALSE (V3-0a)       | FALSE             | N/A               | FAILED_TRIAL (Trial Nullo / Errore Host)   |
+---------------------+-------------------+-------------------+--------------------------------------------+
```

---

## 7. PROTOCOLLO ESECUTIVO DELLE FASI SPERIMENTALI

### FASE 0: Calibrazione Metrologica Obbligatoria (RUN 0)
1. Generazione di `U_ref = CANARY#7F3A91#OMEGA` (19 scalari ASCII).
2. Ricalcolo live SHA-256 e confronto con `dd4019696497ad7e1ca011fe83f57a7354edf66f62fd84f7eb03bbb49134c4e9`.
3. Invocazione di `core/sut_adapter.sh` per prova singola.
4. Verifica audit trail `V3-3` e salvataggio di `calibration_run0.md`.

### FASE 1: Batteria Fondazionale Confermatoria (T01 – T04)
* **T01 (Transport & Canary):** Ladder OFAT a 5 gradini (`C^0 -> C_1 -> C_2 -> C_3 -> T`). Verifica 1:1 sotto `M1-scalar` e `M1-byte`.
* **T02 (Whitespace & Control Boundaries):** Matrice a 5 stimoli (spazi multipli, tab, newline interni vs leading/trailing).
* **T03 (Unicode Normalization):** Matrice differenziale a 4 rami (`U_NFC`, `U_NFD`, `U_NFKC`, `U_NFKD`). Profilo categorico delle trasformazioni senza forzature binomiali.
* **T04 (Invisible/0-Width Characters):** Sottotest isolati per ZWSP (`U+200B`), ZWNJ (`U+200C`) e in-stream BOM (`U+FEFF`).

### FASE 2: Batteria Diagnostica (T11 – T14)
* **T11 (Token Discrepancy):** Misura di `Delta_doc = N_api - N_ref_doc`. Se `Delta_doc > 0` ==> Discrepanza contabile `SUPPORTED`, causa `H_2b` `UNDERDETERMINED`.
* **T12 (Paired Latency / Observed TTFT):** Disegno a blocchi appaiati bilanciati ABAB/BABA (`N >= 20` coppie). Primary: Paired `t`-test; Secondary: Paired Bootstrap 10k Sensitivity. Nomenclatura vincolata a `TTFT_observed_e2e`.
* **T13 (Declared Prefix Caching):** Rilevazione del metadato API dichiarato `cached_tokens > 0` senza inferire GPU KV-cache fisica.
* **T14 (Context Retrieval Degradation):** Matrice parametrizzata `(L, D)` su needle fresh.

---

## 8. ROADMAP DI IMPLEMENTAZIONE STEP-BY-STEP

La scrittura del codice avverrà in **5 step sequenziali e collaudabili**:

```text
+-----------------------------------------------------------------------------+
| STEP 1: Core Foundation & Infrastructure Setup                              |
|         - Creazione struttura directory ~/cdp_workspace/                    |
|         - env_telemetry.sh (Sonda Termux, RTT, umask)                       |
|         - sut_adapter.sh (Wrapper sicuro bash4llm, estrazione artefatti)    |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
| STEP 2: Metrology & Statistical Engines (Pure Python Stdlib)                |
|         - ofat_builder.py (Generatore CSPRNG stimoli e matrici T01-T14)     |
|         - uax_engine.py (UAX #15 normalizer + UAX #29 UNAVAILABLE policy)   |
|         - cdp_stats.py (Clopper-Pearson esatto, Paired t-test, Bootstrap)   |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
| STEP 3: Deterministic Rule Engine & Decision DAG                            |
|         - claim_classifier.py (Tavola di verita Sezione 10 SOP v2.3,        |
|           provenance attribution, assegnazione Vettore E)                   |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
| STEP 4: Reporting & SOTU Generator                                          |
|         - sotu_master.py (Compilatore Markdown Scheda Master SOTU v2.3 con  |
|           The Quadruplet Rule e Addendum Metodologico)                      |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
| STEP 5: Main Orchestrator & End-to-End Validation                           |
|         - cdp_run.sh (CLI unificata, Runner RUN 0, suite T01-T14)           |
|         - Esecuzione RUN 0 di calibrazione e prova pilota T01               |
+-----------------------------------------------------------------------------+
```

---

### Stato del Piano
Il presente documento costituisce il **blueprint tecnico definitivo, completo e conforme alla sintassi ASCII pura**. 

È autosufficiente e pronto per l'implementazione: quando darai il consenso, procederemo generando i singoli moduli nell'ordine stabilito dallo Step 1 allo Step 5.
