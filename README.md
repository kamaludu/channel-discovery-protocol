# CHANNEL DISCOVERY PROTOCOL (CDP / SOP v2.3)
### *Framework Epistemologico Formale & Harness Metrologico per l'Identificazione di Sistemi LLM Black-Box*

```text
+==============================================================================+
|  Standard di Riferimento : CDP v2.3 (Theory) / SOP v2.3 (Laboratory Manual)  |
|  Architettura Software   : Harness Standalone POSIX Bash 4.0+ & Python 3.10+ |
|  Dipendenze Esterne      : ZERO-PIP (Esclusivamente Python Standard Library) |
|  Target Environment      : Android/Termux (aarch64) | Linux POSIX            |
|  Regime di Licenza       : GNU GPLv3 (Harness) | CC BY-SA 4.0 (Specifiche)   |
+==============================================================================+
```

---

## 1. VISIONE GENERALE ED ASSIOMATICA METROLOGICA

Il **Channel Discovery Protocol (CDP v2.3)** costituisce un framework teorico, metodologico ed operativo per l'identificazione di sistemi a scatola nera (*Black-Box System Identification*). È progettato per l'analisi metrologica, replicabile e controllata dei canali di interazione, delle trasformazioni di rappresentazione e dei confini di osservabilità nei sistemi basati su Modelli di Linguaggio (LLM), API Gateway e middleware applicativi.

Il protocollo elimina i salti inferenziali non giustificati subordinando ogni referto a **tre regole auree inviolabili**:

```text
+------------------------------------------------------------------------------+
|                         LE TRE REGOLE METROLOGICHE AUREE                     |
+------------------------------------------------------------------------------+
| 1. Golden Rule         : Strength(Claim) <= Strength(Evidence)               |
|                          Nessun verdetto puo' vantare un livello di certezza |
|                          superiore a quello direttamente intercettato dal    |
|                          Vettore di Evidenza E.                              |
|                                                                              |
| 2. Proxy != Meccanismo : Misurare una variazione esterna (es. TTFT o token)  |
|                          non identifica il modulo interno che l'ha generata. |
|                                                                              |
| 3. Postulato di        : not(Obs(X)) /=> not(X)  [NOT DETECTED != ABSENT]    |
|    Non-Dimostrazione     La mancata presenza di un elemento nell'output O    |
|                          attesta solo che non e' rilevato in O, ma non       |
|                          dimostra che non sia stato elaborato nei layer      |
|                          intermedi inaccessibili (S, Token IDs, M_raw).      |
+------------------------------------------------------------------------------+
```

---

## 2. TOPOLOGIA SISTEMICA E STRUTTURA DEI MODULI

L'harness opera categoricamente come **MODULO AUTONOMO (Standalone Metrology Suite)**, totalmente isolato dal System Under Test (SUT) e dai relativi adapter di invocazione locale (es. `bash4llm`). [Bash4LLM](https://github.com/kamaludu/bash4llm)

### 2.1 Topologia del File System Raccomandata

```text
~/
├── bash4llm/                        # Repository / Eseguibile del SUT
│   ├── bash4llm.d/
│   └── extras/test/                 # (Opzionale: script ponte verso CDP)
│
└── cdp_workspace/                   # Suite Metrologica Autonoma
    ├── cdp_run.sh                   # [MOD-01] Entrypoint CLI Master
    ├── core/
    │   ├── env_telemetry.sh         # [MOD-02] Telemetria Host & Baseline RTT
    │   ├── sut_adapter.sh           # [MOD-03] Adapter isolato bash4llm
    │   └── ofat_builder.py          # [MOD-04] Generatore CSPRNG & Matrici OFAT
    ├── metrology/
    │   ├── uax_engine.py            # [MOD-05] Gestore Normalizzazione UAX #15
    │   ├── cdp_stats.py             # [MOD-06] Engine Statistico (Clopper-Pearson)
    │   └── claim_classifier.py      # [MOD-07] Decision Engine & Ruling Ipotesi
    ├── reporters/
    │   └── sotu_master.py           # [MOD-08] Compilatore Scheda Master SOTU
    └── runs/                        # Storage Immutabile delle Prove Sperimentali
```

### 2.2 Inventario dei Moduli Software

* **`[MOD-01] cdp_run.sh`**: Orchestratore master in Bash 4.0+. Gestisce la CLI, l'isolamento dei descrittori di file, la creazione della sessione immutabile e l'esecuzione della suite.
* **`[MOD-02] core/env_telemetry.sh`**: Sonda telemetrica host. Rileva kernel, architettura CPU, locale `C.UTF-8` e misura la baseline di latenza di rete (RTT).
* **`[MOD-03] core/sut_adapter.sh`**: Wrapper trasparente per `bash4llm`. Materializza i payload su disco (`0600`) prima del cleanup e calcola i digest crittografici SHA-256.
* **`[MOD-04] core/ofat_builder.py`**: Generatore CSPRNG per canary con nonce fresh mono-uso e costruttore delle matrici di stimolo One-Factor-At-A-Time.
* **`[MOD-05] metrology/uax_engine.py`**: Motore di verifica delle forme normalizzate Unicode UAX #15 (`NFC`, `NFD`, `NFKC`, `NFKD`) e policy di segmentazione UAX #29.
* **`[MOD-06] metrology/cdp_stats.py`**: Calcolo esatto non parametrico di Clopper-Pearson al 95% (su distribuzione Beta), t-test appaiato e Bootstrap non parametrico (10.000 iterazioni).
* **`[MOD-07] metrology/claim_classifier.py`**: Motore logico deterministico (Decision DAG). Valuta la catena di custodia ed emette il verdetto logico senza alcun intervento di LLM.
* **`[MOD-08] reporters/sotu_master.py`**: Compilatore automatico del verbale di laboratorio conforme alla Scheda Master SOTU v2.3.

---

## 3. GUIDA RAPIDA DI AVVIO OPERATIVO (TERMUX / LINUX)

```bash
# 1. Assegnazione permessi di esecuzione a script e moduli
chmod -R 700 ~/cdp_workspace/*.sh \
             ~/cdp_workspace/core/*.sh ~/cdp_workspace/core/*.py \
             ~/cdp_workspace/metrology/*.py ~/cdp_workspace/reporters/*.py

# 2. Esecuzione Calibrazione RUN 0 (Verifica Catena Strumentale V3-3)
./cdp_run.sh --test RUN0 --provider groq

# 3. Esecuzione Batteria Fondazionale Confermatoria (T01 - T04) in regime Pilota
./cdp_run.sh --test ALL_FOUNDATIONAL --provider groq --regime pilot

# 4. Esecuzione Test Diagnostico di Latenza Appaiata (T12) con soglia MDE
./cdp_run.sh --test T12 --provider groq --regime pilot --mde 100.0
```

---

## 4. ANATOMIA DEGLI ARTEFATTI DI SESSIONE

Ogni esecuzione genera una directory immutabile in `runs/RUN_<TIMESTAMP>_<TEST>_<NONCE>/` strutturata su 5 blocchi di evidenza:

```text
runs/RUN_<TIMESTAMP>_<TEST>_<NONCE>/
├── run_manifest.json          # 1. Provenance DAG & Impronta Hardware/OS
├── metrics_summary.json       # 2. Grandezze Misurate & Statistica d'Incertezza
├── claim_classification.json  # 3. Decision DAG & Ruling delle Ipotesi H1-H5
├── SOTU_MASTER_REPORT.md      # 4. Referto Ufficiale (The Quadruplet Rule)
└── raw_artifacts/             # 5. Dump Grezzi (Byte C_req, JSON C_resp, log cURL)
```

1. **`run_manifest.json`**: Tupla invariante SUT `<Provider, Endpoint, Model_ID, Sampling>`, impronta telemetrica host, RTT baseline e catena di digest SHA-256 (`U_intended`, `C_req_unicode`, `C_req_app_bytes`, `C_resp_app_bytes`, `output_parsed`).
2. **`metrics_summary.json`**:
   * *Per variabili discrete (T01-T10, T14):* Tasso di replicazione `ORR_b = k / N_valid` e intervallo esatto di Clopper-Pearson al 95% (es. per `k = 5, N = 5 ==> [0.4782, 1.0000]`).
   * *Per variabili continue (T12):* Differenza media appaiata `bar_D`, deviazione standard `s_D`, intervallo Student-t, Bootstrap a 10.000 iterazioni e verifica di rilevanza pratica contro MDE (`Delta_min = 100.0 ms`).
3. **`claim_classification.json`**: Decision DAG deterministico. Assegna:
   * `Evidence Status`: `SUPPORTED` | `NOT SUPPORTED` | `DISCONFIRMED`.
   * `Identification Status`: `IDENTIFIED_WITHIN_OBSERVED_BOUNDARY` | `NOT IDENTIFIED` | `UNDERDETERMINED`.
   * `Vettore di Evidenza`: `E = < O_x, C_x, R_x, S_x >`.
   * `Ruling Ipotesi H1 - H5`: Esclusione o compatibilità per ciascuna classe causale.
4. **`SOTU_MASTER_REPORT.md`**: Verbale formale redatto secondo la **Quadruplet Rule** corredato dall'Addendum Metodologico.
5. **`raw_artifacts/`**: Flussi di byte grezzi catturati per audit indipendente.

---

## 5. MATRICE DI DIAGNOSI DIFFERENZIALE FONDAZIONALE

L'interpretazione si fonda sull'ispezione della catena dei confini discreti:
```text
[ U_intended ] ──> [ C_req (Layer V3) ] ──> [ Backend S / LLM ] ──> [ O (Output) ]
```

```text
+--------------+------------------+----------+---------------+----------------------------------------------------------+
| U_intended   | C_req_unicode    | Output O | Stabilita'    | Diagnosi Metrologica & Assegnazione Vettore E            |
+--------------+------------------+----------+---------------+----------------------------------------------------------+
| Integro      | Integro          | Conforme | ORR_b == 1.00 | PERFETTA CONFORMITA' SUI CONFINI OSSERVATI               |
| (SHA match)  | (SHA match con U)| (sotto M)| [0.478, 1.000]| Vettore: E = < O3, C1, R1, S1 >                          |
|              |                  |          |               | H1a DISCONFERMATA; H2-H5 UNDERDETERMINED.                |
+--------------+------------------+----------+---------------+----------------------------------------------------------+
| Integro      | ALTERATO         | Alterato | ORR_b == 1.00 | TRASFORMAZIONE CLIENT-SIDE (Pre-Trasporto)               |
|              | (SHA != U)       |          | [0.478, 1.000]| Vettore: E = < O3, C1, R1, S3 >                          |
|              |                  |          |               | H1a (Client Mutation) SUPPORTED / IDENTIFIED_DIRECT.     |
+--------------+------------------+----------+---------------+----------------------------------------------------------+
| Integro      | Integro          | ALTERATO | ORR_b == 1.00 | TRASFORMAZIONE POST-CLIENT (A valle della rete)          |
|              | (SHA match con U)| (SHA!= U)| [0.478, 1.000]| Vettore: E = < O3, C1, R1, S5 >                          |
|              |                  |          |               | H1a DISCONFERMATA; Causa tra H2-H5 INDETERMINATA.        |
+--------------+------------------+----------+---------------+----------------------------------------------------------+
| Integro      | Integro          | Conforme | 0 < ORR_b < 1 | VARIANZA DI CANALE O GENERATIVA                          |
|              |                  | / Alt.   | (Varianza)    | Fenomeno stocastico: compatibile con temperatura T > 0   |
|              |                  |          |               | o instabilita' di routing distribuito del backend.       |
+--------------+------------------+----------+---------------+----------------------------------------------------------+
| Integro      | NO-CAPTURE       | Conforme | ORR_b == 1.00 | OSSERVAZIONE BEHAVIORAL PURA (Modalita' B)               |
|              | (V3 non attivo)  |          | [0.478, 1.000]| Vettore: E = < O1, C0, R1, S1 >                          |
|              |                  |          |               | Valida solo su U -> O; nessun layer intermedio noto.     |
+--------------+------------------+----------+---------------+----------------------------------------------------------+
```

---

## 6. THE QUADRUPLET RULE (STRUTTURA DEI REPORT SOTU v2.3)

Ogni verbale ufficiale `SOTU_MASTER_REPORT.md` articola i risultati su quattro pilastri obbligatori:

```text
+-----------------------------------------------------------------------------+
|                         THE QUADRUPLET RULE (CDP v2.3)                      |
+-----------------------------------------------------------------------------+
| 1. OSSERVAZIONE    : Dati oggettivamente acquisiti dallo strumento di       |
|                      misura (byte esadecimali, timestamp, SHA-256).         |
| 2. INFERENZA       : Spazio delle ipotesi teoriche aperte (H1 - H5)         |
|                      qualificate sotto lo specifico criterio M dichiarato.  |
| 3. CONCLUSIONE     : Ipotesi formalmente ESCLUSE (falsificate) o SUPPORTATE |
|                      sotto il vincolo Strength(Claim) <= Strength(Evidence).|
| 4. NON DETERMINATO : Dichiarazione formale dei layer strutturalmente opachi |
|                      e non intercettati (Server Context S, Pesi M_raw).     |
+-----------------------------------------------------------------------------+
|                      ADDENDUM METODOLOGICO OBBLIGATORIO                     |
+-----------------------------------------------------------------------------+
| * ASSUNZIONI STRUM.: Ipotesi tecniche assunte sulla fedelta' degli strumenti|
| * CONDIZIONI DISCONF: Criterio empirico che avrebbe falsificato il verdetto |
+-----------------------------------------------------------------------------+
```

---

## 7. GUIDA ALL'INTERPRETAZIONE DEI TEST

### A. Test Confermatori (T01 – T04: Canary, Spazi, Normalizzazione, ZWSP)
* **Se esito = CONFORMANT_REPRODUCTION (`ORR_b == 1.00`):** Il canale preserva i caratteri speciali senza mutazioni. Non inferire l'architettura del tokenizer; inferisci solo che la risposta terminale è conforme sotto il criterio `M` dichiarato.
* **Se esito = POST_CLIENT_TRANSFORMATION (es. ZWSP `U+200B` soppresso in T04):** Il carattere è presente in `C_req` ma assente in `O`. L'ipotesi di alterazione client `H1a` è **falsificata**. La causa esatta (filtro gateway `H2a`, fusione token BPE `H3`, attenzione `H4`, DOM sanitize `H5b`) è categoricamente **sottodeterminata**.

### B. Test Diagnostico di Latenza Appaiata (T12)
* **Se `is_practically_relevant == True`:** La differenza media appaiata supera la soglia minima (`abs(bar_D) >= Delta_min = 100.0 ms`) e l'intervallo `CI_95%(bar_D)` esclude lo zero. Sussiste una discrepanza temporale sistematica e ingegneristicamente rilevante. L'origine rimane `NOT IDENTIFIED` (è vietato attribuirla a un "filtro di sicurezza" senza log di gateway `O4`).
* **Se `is_statistically_significant == True` ma `is_practically_relevant == False`:** La differenza temporale è misurabile (es. 8 ms), ma inferiore a `Delta_min`: va rubricata come jitter o rumore di rete non rilevante.

### C. Test Diagnostico Token Accounting (T11)
* **Se `Delta_doc = N_api - N_ref_doc > 0`:** L'API addebita sistematicamente più token rispetto al testo utente documentato. La discrepanza è `SUPPORTED`, ma la causa rimane `UNDERDETERMINED` tra framing di sistema non documentato (`H2b`), wrapper di sessione o differenze algoritmiche del vocabolario (`H3`). È formalmente vietato affermare con certezza l'esistenza di un "System Prompt segreto" sulla sola base di `Delta_doc > 0`.

---

## 8. DOCUMENTI NORMATIVI UFFICIALI

La documentazione integrale del framework è consultabile nella cartella `docs/`:

1. **`docs/CDP_Theory.md`**: *Specifiche Teoriche ed Epistemiche (Assiomi, Tassonomia Criteri M1-M5, Matrice Claim L0-L4, Vettore di Evidenza E).*
2. **`docs/SOP_Manual.md`**: *Manuale Operativo di Laboratorio (Procedura RUN 0, Protocollo Metrologico O->M->B->H, Suite T01-T14 e Appendice Fuzzing CDP-FZ).*
3. **`docs/GLOSSARIO.md`**: *Glossario Generale Integrato (Dizionario Sigle A-Z, Tavole di Verità ed Enciclopedia dei Concetti Metrologici).*

---

## 9. LICENZA E CONDIVISIONE

Il progetto è rilasciato sotto licenza ** [GNU General Public License v3.0 (GPLv3)](LICENSE) o superiore, per garantire che rimanga **libero, aperto e non privatizzabile per sempre**:
