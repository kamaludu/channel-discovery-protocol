# CHANNEL DISCOVERY PROTOCOL (CDP)
### Versione Ufficiale 2.3 — *Specifiche Teoriche del Protocollo (Theoretical Specifications & Epistemic Framework)*
#### Standard di Laboratorio per la Caratterizzazione e l'Identificazione di Canali nei Sistemi Black-Box

---

```text
+------------------------------------------------------------------------------+
|                 INDICE DELLE SPECIFICHE TEORICHE (CDP v2.3)                  |
+------------------------------------------------------------------------------+
|  0. Preambolo Epistemologico ed Assiomatica Formale                          |
|  1. Modello Formale del Canale, Stratificazione e Definizione del SUT        |
|  2. La Claim Strength Matrix a 5 Livelli (L0 - L4)                           |
|  3. Tassonomia dei Criteri di Confronto dell'Output (Classe M1 - M5)         |
|  4. Tassonomia Vettoriale di Evidenza E = <O_x, C_x, R_x, S_x>               |
|  5. Layer di Osservabilita' (V0 - V5[V]) e Classificazione V3                |
|  6. Spazio delle Classi di Ipotesi Concorrenti (H1 - H5)                     |
|  7. Sistema a Stati Composti e Grafo di Esecuzione Preregistrato             |
|  8. Metodologia di Misurazione, Structured Ladder OFAT e Blinding            |
|  9. La Quadruplet Rule e l'Addendum Metodologico                             |
|  10. Matrice di Diagnosi Differenziale Fondazionale                          |
+------------------------------------------------------------------------------+
```

---

## 0. PREAMBOLO EPISTEMOLOGICO ED ASSIOMATICA FORMALE

Il **Channel Discovery Protocol (CDP v2.3)** costituisce un framework teorico, formale e normativo per l'identificazione di sistemi a scatola nera (*Black-Box System Identification*). Il protocollo e' progettato per l'analisi metrologica, replicabile e controllata dei canali di comunicazione, delle trasformazioni di rappresentazione e dei confini di osservabilita' nei sistemi basati su Modelli di Linguaggio (LLM), middleware applicativi e architetture client-server distribuite.

```text
+------------------------------------------------------------------------------+
|                    ASSIOMATICA DEL PROTOCOLLO (CDP v2.3)                     |
+------------------------------------------------------------------------------+
| 1. Falsificazionismo Conservativo : Escludere modelli incompatibili;         |
|                                     non confermare euristiche interne.       |
| 2. Boundary Certainty             : Divieto di attribuire causalita' oltre   |
|                                     il confine strumentato.                  |
| 3. Triade dei Claim               : Claim A (Obs) /=> Claim B (Loc) /=>      |
|                                     Claim C (Mec).                           |
| 4. Postulato di Non-Dimostrazione : not(Obs(X)) /=> not(X)                   |
|                                     (NOT DETECTED != ABSENT).                |
| 5. Assioma di Non-Inclusione      : L'assenza di osservazione su un layer    |
|                                     non costituisce evidenza negativa sul    |
|                                     layer successivo salvo prova causale.    |
| 6. Separazione Temporale/Causale  : La sequenza t_A < t_B attesta ordine di  |
|                                     protocollo, mai derivazione causale.     |
| 7. Modello Analitico a Stadi      : U -> C -> S -> M -> O e' un costrutto    |
|                                     euristico, non una certezza fisica.      |
| 8. Data Integrity Chain           : Tracciamento tramite serializzazione     |
|                                     canonica UTF-8 e digest SHA-256.         |
+------------------------------------------------------------------------------+
```

### 0.1 Postulati Fondamentali

1. **Falsificazione vs. Induzione:** Il protocollo non tenta di descrivere il funzionamento interno del sistema tramite accumulazione induttiva di casi positivi. Il suo scopo e' delimitare lo spazio delle ipotesi ammissibili ed **escludere formalmente le ipotesi incompatibili** con i dati empirici e i controlli differenziali.
2. **Boundary Certainty (Confine di Evidenza Certo):** E' metodologicamente vietato formulare asserzioni causali su layer o componenti non direttamente intercettati. Ogni trasformazione che si verifichi a valle dell'ultimo confine osservabile deve essere formalmente rubricata come *architetturalmente indeterminata*.
3. **La Triade dei Claim e il Principio di Non-Derivabilita':**
   * **Claim A (Osservazione):** Asserzione puramente descrittiva su un dato rilevato allo strumento di misura.
   * **Claim B (Localizzazione):** Asserzione sul confine logico o fisico entro cui si e' verificata la variazione.
   * **Claim C (Meccanismo):** Asserzione sul componente architetturale interno che ha generato la trasformazione.
   ```text
   Claim A (Osservazione) /=> Claim B (Localizzazione) /=> Claim C (Meccanismo)
   ```
   *Nessun salto inferenziale tra livelli e' consentito senza strumentazione dedicata o interventi causali formalmente identificati.*
4. **Il Postulato `not(Obs(X)) /=> not(X)` (`NOT DETECTED != ABSENT`):** La mancata presenza di un codepoint, token o struttura nell'output finale `O` attesta esclusivamente che esso e' `NOT DETECTED` in `O`, ma **non dimostra** che tale elemento non sia stato ricevuto, elaborato o rappresentato nei layer intermedi inaccessibili (`S`, `Token IDs`, `M_raw`).
5. **Assioma di Non-Inclusione tra Layer:** L'assenza di osservazione su un dato layer non costituisce evidenza negativa sul layer successivo, a meno che non sia rigorosamente dimostrata una relazione di inclusione causale necessaria tra i due confini.
6. **Separazione tra Ordine Temporale e Causalita':** La rilevazione di un evento `A` al tempo `t_1` e di un evento `B` al tempo `t_2` con `t_1 < t_2` stabilisce una sequenza temporale di protocollo, non un nesso di causalita'. Una correlazione temporale priva di identificatore applicativo univoco preclude qualsiasi attribuzione causale.
7. **Natura Analitica del Modello a Stadi:** La scomposizione formale `U -> C_req -> S -> M_raw -> C_resp -> O` costituisce un modello concettuale analitico e non un'asserzione vincolante sull'architettura hardware/software interna del sistema target.
8. **Distinzione Semantica di Stato:** Nelle valutazioni e nei verbali devono essere distinti categoricamente i seguenti termini operativi:
   * **`OBSERVED`:** Dato fisicamente acquisito dallo strumento di misura sul confine designato.
   * **`SUPPORTED`:** Ipotesi che riceve evidenza empirica favorevole da un contrasto differenziale controllato.
   * **`NOT FALSIFIED`:** Ipotesi che rimane compatibile con i dati osservati pur in assenza di prove positive dirette.
   * **`INFERRED`:** Deduzione logica derivata formalmente sotto assunzioni esplicitamente dichiarate.
   * **`CAUSALLY IDENTIFIED`:** Effetto isolato tramite manipolazione interventistica contrastata (`do(X)` o DAG causale validato).
   * **`NOT DETERMINED`:** Fenomeno o layer strutturalmente inaccessibile alla configurazione di test.

---

## 1. MODELLO FORMALE DEL CANALE, STRATIFICAZIONE E DEFINIZIONE DEL SUT

Il canale di interazione e' formalizzato come una catena sequenziale a confini discreti di osservabilita', articolata su **quattro layer sperimentali**:

```text
+------------------------------------------------------------------------------+
|                   LAYER L0: STIMULUS INTEGRITY (CLIENT PRE-SUBMIT)           |
|                                                                              |
|  [ U_source ] ---> [ U_intended ] ---> [ U_rendered ] ---> [ U_buffer ]      |
+--------------------------------------------------------------+---------------+
                                                               | Evento Submit
                                                               v
+------------------------------------------------------------------------------+
|                   LAYER L1: TRANSPORT (NETWORK & PROTOCOL BOUNDARY)          |
|                                                                              |
|  [ U_serialized ] ---> [ C_req (Network Request) ] [Layer V3]                |
|                               │                                              |
|                               v                                              |
|  =================== LIVELLO SERVER (NON OSSERVABILE) =====================  |
|   [ GATEWAY / MIDDLEWARE / CONTEXT BUILDER ]                                 |
|        │ (System, Developer, Memory, RAG, Cronologia, Tools)                 |
|        v                                                                     |
|       ( S ) ---> [ TOKENIZER ] ---> ( Token IDs ) ---> [ LLM CORE ]          |
|                                                            │                 |
|                                                         ( M_raw )            |
|                                                            │                 |
|   [ POST-PROCESSING / STREAM FILTER / GUARDRAIL ] <────────┘                 |
|  ==========================================================================  |
|                               │                                              |
|                               v                                              |
|  [ C_resp (Response Stream) ] ---> [ Client Protocol Parser ] [Layer V3]     |
+--------------------------------------------------------------+---------------+
                                                               | Parsing Client
                                                               v
+------------------------------------------------------------------------------+
|                   LAYER L2: BEHAVIORAL & RENDERING (CLIENT POST-RECEIVE)     |
|                                                                              |
|  [ C_resp_parsed ] ---> [ O_markdown / O_html ] ---> [ O_dom ] ---> [ O_vis ]|
|                                                                              |
|  [ O (Observed Output Finale Composito) ]                                    |
+------------------------------------------------------------------------------+
+------------------------------------------------------------------------------+
|                   LAYER L3: CROSS-SESSION / CROSS-SYSTEM EXTENSION           |
|                                                                              |
|  [ Session_A (SA.Q0..Q4) ] ---> [ Session_B (SB.Q0..Q3) ] | [ SUT_1 vs SUT_2]|
+------------------------------------------------------------------------------+
```

### 1.1 Formalizzazione del System Under Test (SUT)

Ogni misurazione deve essere riferita in modo univoco alla tupla formale del sistema sotto test:
```text
SUT = < Provider, Model_ID, Runtime_Version, Interface_Type, Sampling_Configuration, Environment_Flags >
```
*E' formalmente vietato considerare misurazioni su interfacce, runtime o versioni differenti come repliche del medesimo SUT.*

### 1.2 Variabili di Canale Formalizzate

* `U_source`: La rappresentazione sorgente generata programmaticamente dal generatore di stimoli.
* `U_intended`: La sequenza astratta di caratteri definita nel disegno sperimentale preregistrato.
* `U_rendered`: La visualizzazione del testo nel campo di input dell'interfaccia client prima dell'invio.
* `U_buffer`: La rappresentazione del testo presente nel buffer di input del DOM pre-invio.
* `U_serialized`: Il testo dopo l'applicazione delle funzioni di escape, framing e serializzazione dell'interfaccia client.
* `C_req`: La rappresentazione applicativa osservabile della richiesta trasmessa dallo stack di rete del client sul confine di rete.
* `S`: Struttura composita di contesto backend assemblata prima della tokenizzazione al turno `n`:
  ```text
  S_n = Render( < Messages, SystemState, ToolsPayload, MultimodalData, History_(1...n-1), C_req_n > )
  ```
  *(Costantemente inaccessibile su sistemi commerciali chiusi).*
* `Token_IDs`: La sequenza discreta di interi generata dall'applicazione della funzione di tokenizzazione configurata nel runtime specifico.
* `M_raw`: Lo stato generativo interno discreto prima di qualsiasi elaborazione, post-processing o filtraggio di sicurezza *(Costantemente inaccessibile su sistemi commerciali chiusi).*
* `C_resp`: Lo stream o payload di risposta ricevuto dallo stack di rete del client.
* `O_markdown / O_html`: La rappresentazione strutturata intermedia generata dai parser client a partire da `C_resp`.
* `O_dom`: Il contenuto testuale effettivo presente all'interno del nodo di testo nell'albero DOM dell'interfaccia client.
* `O_visual`: La rappresentazione grafica terminale renderizzata a schermo (glifi visibili e layout tipografico).
* `O`: L'output composito finale osservato ed estratto dal client.

### 1.3 Stratificazione Formale dei Payload di Rete (`C_req` e `C_resp`)

Il payload di richiesta `C_req` e il payload di risposta `C_resp` sono analizzati lungo le rispettive catene di rappresentazione formale:
```text
C_req_byte  ---(decoding UTF-8)---> C_req_text ---> C_req_json ---> C_req_unicode
C_resp_byte ---(framing HTTP/WS)--> C_resp_stream -> C_resp_parsed
```
Ogni comparazione con l'input `U_intended` deve dichiarare esplicitamente il livello formale a cui viene effettuata la verifica.

### 1.4 Data Integrity Chain (Tracciamento tramite Serializzazione Canonica UTF-8)

L'integrita' metrologica del dato tra rappresentazioni eterogenee e' definita attraverso l'applicazione esplicita della funzione di serializzazione canonica in byte `enc_UTF8()`:
```text
SHA256( enc_UTF8(U_intended) ) == SHA256( enc_UTF8(U_buffer) ) == SHA256( C_req_byte )
```
Nel caso del livello estratto `C_req_unicode`, il digest SHA-256 viene calcolato esclusivamente previa decodifica e normalizzazione a stringa scalare UTF-8:
```text
SHA256( enc_UTF8(U_intended) ) == SHA256( enc_UTF8( ExtractUnicode(C_req_json) ) )
```

---

## 2. LA CLAIM STRENGTH MATRIX A 5 LIVELLI (L0 - L4)

Il protocollo subordina rigidamente la validita' delle conclusioni al confine di osservabilita' effettivamente intercettato:

```text
+------------------------------------------------------------------------------+
|                    CLAIM STRENGTH MATRIX A 5 LIVELLI                         |
+------+----------------------+------------------------------------------------+
| Liv. | Denominazione        | Confine Minimo Richiesto & Asserzione Ammessa  |
+------+----------------------+------------------------------------------------+
|  L0  | Raw Observation      | Rilevazione empirica diretta allo strumento    |
|      |                      | (es. stringa C_req_unicode catturata).         |
+------+----------------------+------------------------------------------------+
|  L1  | Empirical Relation   | Differenziale controllato tra input e output   |
|      |                      | sotto specifico criterio di confronto M.       |
+------+----------------------+------------------------------------------------+
|  L2  | Localization Claim   | Isolamento della trasformazione entro un       |
|      |                      | confine strumentato (es. U -> C_req).          |
+------+----------------------+------------------------------------------------+
|  L3  | Local Mechanism      | Effetto causale locale dimostrato tramite      |
|      |                      | manipolazione interventistica ed assunzioni.   |
+------+----------------------+------------------------------------------------+
|  L4  | Architectural Claim  | Asserzione sull'architettura interna dei pesi  |
|      |                      | (Consentito SOLO con Layer V5 documentato).    |
+------+----------------------+------------------------------------------------+
```

> **Regola di Non-Trascendenza:** Un risultato sperimentale non puo' essere refertato a un livello superiore (`L_(n+1)`) qualora non siano pienamente soddisfatti e documentati i criteri di evidenza del livello sottostante (`L_n`).

---

## 3. TASSONOMIA DEI CRITERI DI CONFRONTO DELL'OUTPUT (CLASSE M1 - M5)

E' categoricamente vietato l'uso generico del termine *"relazione di equivalenza"* per confrontare stringhe o output che non rispettano le proprieta' matematiche di equivalenza (riflessivita', simmetria, transitivita'). Il protocollo definisce la **Tassonomia dei Criteri di Confronto M1 - M5**:

```text
+------------------------------------------------------------------------------+
|                TASSONOMIA DEI CRITERI DI CONFRONTO (CLASSE M)                |
+------------------------+--------------------------+--------------------------+
| Classe Formale         | Natura Matematica        | Istanze nel Protocollo   |
+------------------------+--------------------------+--------------------------+
| M1: Exact Identity     | Uguaglianza formale (=)  | I_byte, I_scalar         |
+------------------------+--------------------------+--------------------------+
| M2a: Normalization-Eq. | Relazione di equivalenza | E_NFC, E_NFD,            |
|      (Unicode UAX #15) | per partizione           | E_NFKC, E_NFKD           |
+------------------------+--------------------------+--------------------------+
| M2b: Segmentation-Eq.  | Equivalenza su sequenza  | E_EGC                    |
|      (Unicode UAX #29) | di cluster deterministica| (Extended Grapheme Cl.)  |
+------------------------+--------------------------+--------------------------+
| M3: Deterministic      | Predicato di identita'   | R_render | Phi           |
|     Rendering Criteria | su raster vincolato      | (Pixel Diff == 0 in Phi) |
+------------------------+--------------------------+--------------------------+
| M4: Distance & Metric  | Pseudometriche e         | Distanza di Levenshtein, |
|     Functions          | funzioni di costo        | Token Overlap Ratio      |
+------------------------+--------------------------+--------------------------+
| M5: Semantic           | Protocollo empirico di   | P_sem                    |
|     Concordance        | concordanza convenzionale| (NLI, Blind Rubric)      |
+------------------------+--------------------------+--------------------------+
```

### 3.1 Definizione Formale delle Classi M

* **M1 — Exact Identity (`I_byte`, `I_scalar`):**
  Uguaglianza matematica 1:1 della sequenza di byte UTF-8 (`I_byte`) o della sequenza di Unicode Scalar Values (`I_scalar`).
* **M2a — Normalization-Based Equivalence (Unicode UAX #15):**
  Relazione di equivalenza formale definita sull'identita' delle forme canoniche o di compatibilita':
  ```text
  x ~_Norm y  <===>  Norm(x) == Norm(y)   con Norm in { NFC, NFD, NFKC, NFKD }
  ```
* **M2b — Segmentation Sequence Equivalence (Unicode UAX #29):**
  Relazione di equivalenza definita sull'uguaglianza della tupla ordinata dei segmenti di testo discreti calcolati dall'applicazione deterministica dell'algoritmo di segmentazione:
  ```text
  x ~_EGC y  <===>  Seg_UAX29(x) == Seg_UAX29(y)
  ```
  *(Non costituisce una normalizzazione Unicode, ma un confronto tra sequenze di partizioni).*
* **M3 — Deterministic Rendering Criteria (`R_render | Phi`):**
  Predicato di identita' raster vincolato al vettore esplicito di configurazione ambientale `Phi`:
  ```text
  Phi = < Engine, OS, Rasterizer, Font_Family, Font_Size, Antialiasing, DPR, Viewport >
  R_render(O_1, O_2 | Phi)  <===>  RasterDiff( O_1, O_2 | Phi ) == 0
  ```
* **M4 — Distance & Metric Functions:**
  Misure di similarita' quantitative non binarie calcolate tramite funzioni di costo o metriche di stringa (es. Distanza di Levenshtein, Jaccard Similarity su n-grammi).
* **M5 — Semantic Concordance Protocol (`P_sem`):**
  Protocollo empirico operativo di valutazione specificato dalla tupla:
  ```text
  P_sem = < Valutatore, Metrica, Soglia_tau >
  ```
  * *Istanza Automatica:* Modello NLI dichiarato con soglia di entailment bidirezionale:
    ```text
    P(Entail(O, U)) >= tau_NLI  AND  P(Entail(U, O)) >= tau_NLI
    ```
  * *Istanza Umana:* Protocollo a doppio cieco standardizzato con calcolo formale dell'accordo inter-osservatore (es. indice Kappa di Cohen con `kappa >= 0.85`), inteso come misura di affidabilita' del protocollo e non come proprieta' semantica assoluta.

---

## 4. TASSONOMIA VETTORIALE DI EVIDENZA ESTESA (E = <O_x, C_x, R_x, S_x>)

Ogni refertazione sperimentale deve specificare il vettore formale `E` a quattro coordinate indipendenti:

```text
                              VETTORE DI EVIDENZA E
                         +-----------------------------+
                         |  E = < Ox ,  Cx ,  Rx , Sx >|
                         +------┬-------┬-------┬---┬--+
                                │       │       │   │
       +------------------------+       │       │   +--------------------+
       v                                v       v                        v
  [ ASSE O: Observability ]   [ ASSE C: Causal Ident. ]  [ ASSE R: Scope ]  [ ASSE S: Scope ]
   O0: Nessun confine          C0: Associazione pura      R0: Singola (N=1)  S0: Solo U
   O1: Solo output U->O        C1: Contrasto differenz.   R1: Pilota         S1: U -> O
   O2: Ispezione DOM           C2: Intervento diretto     R2: Stima VincolataS2: U -> DOM
   O3: Confine rete U->C_req   C3: Ident. Strutturale     R3: Cross-system   S3: U -> C_req
   O4: Middleware server       C4: Validaz. Meccanicistica                   S4: C_req -> C_resp
   O5: Parametrico V5[V]                                                     S5: C_req -> O
                                                                             S6: End-to-end comp.
```

### 4.1 Asse O — Observability Boundary
* `O0`: Nessun confine strumentato.
* `O1`: Osservazione comportamentale terminale `U -> O`.
* `O2`: Ispezione del DOM client pre-invio e post-ricezione (`U_buffer`, `O_dom`).
* `O3`: Ispezione del confine client/rete (`U -> C_req`, `C_resp`).
* `O4`: Accesso a log di gateway/middleware server-side verificabili.
* `O5`: Accesso strumentato a variabili interne `V5[V]` su runtime locale.

### 4.2 Asse C — Scala di Evidenza Causale CDP (C_CDP)
La scala `C_CDP` e' una tassonomia proprietaria del protocollo per la qualificazione dell'evidenza causale:
* `C0` — **Associazione Osservazionale Pura:** Stima di probabilita' condizionata `P(O | U)` priva di isolamento dei fattori.
* `C1` — **Contrasto Differenziale Comparativo:** Evidenza discriminativa basata su variazioni controllate dello stimolo (OFAT) per escludere confondenti espliciti.
* `C2` — **Intervento Sperimentale Diretto:** Risultato di una manipolazione attiva `P(O | do(X = x))` su parametri configurabili del SUT mantenendo fisso l'ambiente.
* `C3` — **Identificazione Causale Strutturale:** Effetto causale derivato sotto un Grafo Causale Diretto Acomplesso (DAG) che soddisfa formali criteri di identificabilita' (es. Backdoor o Frontdoor Criterion) con assunzioni di non-confondimento esplicitate.
* `C4` — **Validazione Meccanicistica Locale:** Evidenza empirica locale derivata dalla manipolazione diretta di variabili interne (pesi, attivazioni, token).

### 4.3 Asse R — Replication Scope & Statistica di Precisione
Il protocollo elimina l'euristica convenzionale `N >= 30` come garanzia universale di robustezza. La dimensione campionaria e' vincolata al **Margin of Error (MOE)** desiderato:
* `R0`: Singola osservazione non replicata (`N = 1`).
* `R1`: **Studio Pilota a Bassa Precisione (`N in [5, 10]`):** Valutazione descrittiva iniziale. Per `k = 5, N = 5`, l'intervallo esatto di Clopper-Pearson al 95% e' `[0.478, 1.000]`. Attesta l'assenza di fallimenti nel campione pilota ma non esclude un tasso di errore reale fino al 52.2%.
* `R2`: **Stima Parametrica Vincolata:** Dimensione campionaria `N` dimensionata a priori sul semintervallo del CI desiderato (es. `MOE <= 0.05` con potenza `1 - beta >= 0.80`).
* `R3`: **Replicazione Multi-Ambiente Cross-System:** Replicazione indipendente su vendor, runtime e contesti operativi eterogenei.

#### Definizione Matematica dell'Observed Replication Rate (ORR)
L'indice di replicazione e' formalmente definito su run validi escludendo le anomalie ambientali:
```text
ORR_b = k / N_valid      con  N_valid = N_attempts - N_invalid
```

### 4.4 Asse S — Evidence Scope
* `S0`: Circoscritto al solo stimolo di input (`U`).
* `S1`: Relazione comportamentale diretta `U -> O`.
* `S2`: Relazione di input client `U -> O_dom`.
* `S3`: Confine di trasporto client/rete `U -> C_req`.
* `S4`: Confine di rete bidirezionale `C_req -> C_resp`.
* `S5`: Confine da rete a output utente `C_req -> O`.
* `S6`: Catena composita end-to-end completamente osservata *(Applicabile SOLO con Layer O5/V5 attivo su tutti i segmenti)*.

---

## 5. LAYER DI OSSERVABILITA' (V0 - V5[V]) E CLASSIFICAZIONE V3

### 5.1 Layer di Osservabilita'

| Layer | Confine Strumentale Osservato | Accessibilita' Standard |
| :--- | :--- | :--- |
| **`V0`** | Input intenzionale digitato o generato (`U_intended`) | Sempre accessibile |
| **`V1`** | Rappresentazione DOM / UI client pre-invio (`U_buffer`) | Accessibile via ispezione interfaccia |
| **`V2`** | Output finale renderizzato a schermo (`O`) | Sempre accessibile |
| **`V3`** | Traffico applicativo di rete (`C_req`, `C_resp`) | Accessibile via DevTools, proxy HTTP |
| **`V4`** | Payload effettivo ricevuto ed elaborato dal server | Non accessibile su sistemi cloud proprietari |
| **`V5[V]`** | Variabili interne strumentate sul runtime locale | Parametrizzato sul sottoinsieme `V` |

### 5.2 Tassonomia di Classificazione del Layer V3

* **`V3-0a` [No-Instrumentation (`NO-CAPTURE`)]:** Assenza di strumenti di cattura attivi o impossibilita' tecnica di intercettare lo stack di rete (`not(Obs(C))`).
* **`V3-0b` [No-Relevant-Channel (`NOT-FOUND`)]:** Strumentazione attiva ma nessun canale applicativo correlabile al Submit identificato (`Obs(traffic) AND not(Obs(C_relevant))`).
* **`V3-1` [Traffico con U Rilevato]:** La sequenza `U` compare nel traffico di rete, ma la sua funzione (es. telemetria) non e' univoca.
* **`V3-2` [Correlazione Temporale]:** Richiesta associata temporalmente all'evento Submit (`t_submit approx t_req`), priva di correlation ID univoco.
* **`V3-3` [Canale Applicativo Verificato]:** Correlazione applicativa univocamente verificata mediante: (1) Correlation/Request ID esplicito, (2) ID di operazione/thread corrispondente, oppure (3) Mapping deterministico documentato tra `C_req` e lo stream `C_resp`.
* **`V3-X` [Payload Non Decodificabile (`UNDECODABLE`)]:** Traffico intercettato ma payload cifrato, compresso in modo proprietario o binario non documentato.

---

### 5.3 Mappatura Parametrica del Layer V5[V] e Claim Ammissibili

Il layer `V5` e' formalmente definito come **Accesso Strumentato alle Variabili Interne**, parametrizzato sul sottoinsieme effettivo di variabili intercettate `V`:
```text
V5[V]   con V sottoinsieme di { TokenIDs, Logits, AttentionWeights, KVCache, HiddenStates, Weights }
```

```text
+------------------------------------------------------------------------------+
|           MATRICE DI MAPPATURA: VARIABILE INTERNA V5[V] -> CLAIM             |
+----------------------+--------------------+----------------------------------+
| Variabile in V5[V]   | Confine Misurato   | Claim Ammissibile (CDP v2.3)     |
+----------------------+--------------------+----------------------------------+
| V5[TokenIDs]         | Sequenza discreta  | Descrizione esatta della         |
|                      | di interi          | partizione di token processata.  |
+----------------------+--------------------+----------------------------------+
| V5[Logits]           | Vettore reale      | Valori grezzi z e, previa        |
|                      | z in R^(|V|)       | softmax con temperatura T,       |
|                      |                    | distribuzione p e entropia H(p|T)|
+----------------------+--------------------+----------------------------------+
| V5[AttentionWeights] | Matrici A_(l,h)    | Pattern di mixing e pesatura     |
|                      | in [0, 1]^(N x N)  | scalare post-softmax tra posiz.  |
+----------------------+--------------------+----------------------------------+
| V5[Ablation/Patching]| Risposta a         | Evidenza causale locale          |
|                      | manipolazioni      | dell'intervento sul nodo/circuito|
|                      | interne            | sotto modello dichiarato.        |
+----------------------+--------------------+----------------------------------+
```

#### Specifiche Matematiche Obbligatorie per V5[V]

1. **Distribuzione ed Entropia Condizionata a T (`V5[Logits]`):**
   Dati i logit grezzi `z in R^(|V|)` e la temperatura di campionamento `T > 0`, la distribuzione di probabilita' categorica `p(z; T)` e l'Entropia di Shannon condizionata sono formalmente definite:
   ```text
   p(z; T)_i = exp( z_i / T ) / ( sum(j=1 to |V|, exp( z_j / T )) )
   
   H(p | T)  = - sum(i=1 to |V|, p(z; T)_i * log( p(z; T)_i ) )
   ```
   *Ogni refertazione dell'entropia deve specificare il valore esatto di T utilizzato (oppure assumere come baseline standard T = 1.0).*

2. **Pesi di Attenzione (`V5[AttentionWeights]`):**
   La rappresentazione matriciale a righe stocastiche `A_(l,h) in [0, 1]^(N x N)` con `sum(j=1 to N, A_(i,j)) == 1` e' formalmente vincolata a modelli basati su **Multi-Head Attention (MHA/GQA/MQA) a prodotto scalare standard, calcolata post-applicazione della funzione Softmax**.
   *Divieto:* E' formalmente vietato equiparare i pesi di attenzione a "routing causale dell'informazione", stante il contributo essenziale delle matrici di valore (`W_V`), delle proiezioni di output (`W_O`) e del flusso non lineare lungo il residual stream.

3. **Interventi Meccanicistici (`V5[Ablation/Patching]`):**
   I claim derivanti da activation patching o ablazione sono validi solo specificando il modello di perturbazione dichiarato (es. mean ablation, zero ablation, interchange intervention) e costituiscono **evidenza causale locale** dell'intervento sul componente testato.

---

## 6. SPAZIO DELLE CLASSI DI IPOTESI CONCORRENTI (H1 - H5)

Per qualsiasi variazione o divergenza riscontrata tra `U` e `O`, lo spazio delle spiegazioni ammissibili e' strutturato in classi generali:

```text
[U] ---> ( H1: Client ) ---> [C_req] ---> ( H2: Server ) ---> [S]
                                                               │
[O] <--- ( H5: Post/Render ) <--- [M_raw] <--- ( H4: Model ) <─┴─ ( H3: Tokenizer )
```

* **`H1` — Trasformazioni Client-Side:** Modifica o sanitizzazione applicata dal codice client prima o durante la trasmissione in rete.
  * `H1a`: Trasformazione testuale localizzata nel percorso `U_intended -> C_req` (escludibile direttamente via ispezione V3).
  * `H1b`: Mutazione del DOM / UI pre-invio nel buffer `U_buffer`.
* **`H2` — Trasformazioni Server-Side (Pre-Context):** Modifica apportata dall'infrastruttura remota a monte della costruzione del context `S`.
  * `H2a`: Sanitizzazione presso API Gateway, Web Application Firewall (WAF) o proxy intermedi.
  * `H2b`: Formattazione o iniezione di wrapper/system prompts da parte del context builder backend.
* **`H3` — Classe di Condizionamento da Tokenizzazione e Discretizzazione:** La tokenizzazione configurata produce una specifica partizione discreta di token IDs:
  * `H3` modella l'ipotesi descrittiva secondo cui la partizione di token `T = tokenize(U)` correla con la risposta del modello.
  * *Attribuzione Causale:* L'attribuzione causale a `H3` e' considerata identificata solo se verificata tramite interventi mirati (es. perturbazione differenziale dei confini di subword `T_split` o iniezione controllata di sequenze alternative `T' != T` con `detokenize(T') == U`).
* **`H4` — Dinamica Computazionale e Generativa del Modello:** La sequenza di token entra correttamente nei tensori, ma la computazione autoregressiva genera un output divergente.
  * Ipotesi latenti non falsificate (es. prior semantico dominante, interferenze attentive nel contesto) rimangono categorizzate come *meccanismi interni non direttamente identificati* in assenza di Layer `V5`.
* **`H5` — Trasformazioni Post-Generazione e Rendering:** La sequenza e' emessa nello stato interno `M_raw`, ma viene alterata prima della visualizzazione finale.
  * `H5a`: Intercettazione o troncamento da parte di guardrail asincroni nello stream `C_resp`.
  * `H5b`: Stripping o parsing distruttivo da parte dei motori di rendering Markdown/HTML o del DOM (`O_dom`, `O_visual`).

---

## 7. SISTEMA A STATI COMPOSTI E GRAFO DI ESECUZIONE PREREGISTRATO

La modellazione della sessione e' definita come un **Sistema a Stati Composti**:
```text
S_state = < q_session, e_env >   in   Q_session x E_env
```

### 7.1 Configurazione Ambientale (`E_env`)
* `e_0` — **Pure Ephemeral State:** Sessione stateless, assenza di memoria account o cronologie persistenti.
* `e_1` — **Persistent Account State:** Ambiente con memorie globali cross-chat, custom instructions attive o RAG persistente.

### 7.2 Grafo di Esecuzione Deterministico Preregistrato (`G_protocol`)

La macchina a stati non impone una topologia standard universale a priori, ma coincide rigorosamente con il grafo delle azioni del **disegno sperimentale preregistrato**:
```text
G_protocol = < Q_prereg, Sigma_actions, delta_transitions, q_init, F_terminal > x E_env
```

* **Esempio: Protocollo Cross-Session Standard (Recall Diretto):**
  * *Sessione A (Iniezione):*
    ```text
    < SA.Q0, e_0 > --(Iniezione Canary)--> < SA.Q1, e_0 > --(Teardown/Close)--> < SA.Q_closed, e_0 >
    ```
  * *Sessione B (Verifica Indipendente):*
    ```text
    < SB.Q0, e_0 > --(Recall Probe)------> < SB.Q_probe, e_0 > --(Risposta)--> < SB.Q_terminal, e_0 >
    ```
*Regola di Fedeltà Sperimentale:* Se il disegno preregistrato include turni intermedi o distrattori (`SA.Q1 -> SA.Q2 -> SA.Q3`), la FSM traccera' esattamente quegli stati. E' formalmente vietato alterare a posteriori la struttura degli stati per fini puramente estetici.

---

## 8. METODOLOGIA DI MISURAZIONE, STRUCTURED LADDER OFAT E BLINDING

### 8.1 Structured Ladder One-Factor-At-A-Time (OFAT)
I controlli differenziali isolano **una singola variabile per gradino**:
```text
Ladder OFAT: C^0 --(Delta F_1)--> C_1 --(Delta F_2)--> C_2 --(Delta F_3)--> C_3 --(Delta F_4)--> T
```
*Vincolo Metodologico:* L'approccio OFAT produce **evidenza comparativa/discriminativa (`C1`)**, ma non garantisce identificazione causale pura in presenza di interazioni non lineari o variabili latenti non controllate.

### 8.2 Canary Parametrici con CSPRNG Fresh
Tutti i canary sperimentali sono generati dinamicamente:
```text
CANARY = PREFIX + NONCE_HEX + SUFFIX
```
Il valore casuale `NONCE_HEX` deve essere generato tramite CSPRNG crittograficamente sicuro e utilizzato una sola volta.

### 8.3 Doppio Sottotest di Laboratorio
* **Sottotest A (Transport Observation — Layer L1):** Somministrazione dello stimolo target grezzo. Risponde a: *"La rappresentazione `C_req_unicode` contiene l'esatta sequenza attesa?"*
* **Sottotest B (Behavioral Retrieval — Layer L2):** Somministrazione della Ladder OFAT con prompt delimitato standardizzato. Risponde a: *"Dato l'input, quale output O viene emesso sotto il criterio M dichiarato?"*

---

## 9. LA QUADRUPLET RULE E L'ADDENDUM METODOLOGICO

Ogni refertazione formale conclusiva (verbale SOTU v2.3) deve essere redatta rispettando i **quattro pilastri analitici obbligatori**, corredati dall'Addendum Metodologico:

```text
+-----------------------------------------------------------------------------+
|                    THE QUADRUPLET RULE (CDP v2.3)                           |
+-----------------------------------------------------------------------------+
| 1. OSSERVAZIONE    : Dati empirici oggettivi su U, C_req, C_resp, O_dom,    |
|                      O_visual e relativi digest canonici SHA-256.           |
| 2. INFERENZA       : Spazio rigoroso delle ipotesi residue aperte (H1-H5)   |
|                      qualificate sotto il criterio di confronto M adottato. |
| 3. CONCLUSIONE     : Ipotesi formalmente ESCLUSE dai dati osservati sotto   |
|                      le assunzioni dichiarate, con Vettore E=<O, C, R, S>.  |
| 4. NON DETERMINATO : Dichiarazione categorica ed esplicita dei layer opachi |
|                      e dei fenomeni non direttamente osservati (S, M_raw).  |
+-----------------------------------------------------------------------------+
|                    ADDENDUM METODOLOGICO OBBLIGATORIO                       |
+-----------------------------------------------------------------------------+
| * ASSUNZIONI STRUM.: Ipotesi tecniche adottate sugli strumenti di misura    |
|                      (es. fedelta' del socket DevTools o pipe stdout).      |
| * CONDIZIONI DI    : Criterio sperimentale specifico che avrebbe            |
|   DISCONFERMA        disconfermato la conclusione raggiunta.                |
+-----------------------------------------------------------------------------+
```

---

## 10. MATRICE DI DIAGNOSI DIFFERENZIALE FONDAZIONALE

```text
+----------------------------------------------------------------------------------------------------+
| U_intended | C_req (V3) | O        | StabilitÃ  (ORR_b & CI) | Inferenza Formale e Confine Evidenza  |
+------------+------------+----------+------------------------+--------------------------------------+
| Integro    | Integro    | Conforme | ORR_b == 1.00          | Nessuna alterazione rilevata nei     |
|            |            | (sotto M)| [0.478, 1.000] (Pilota)| confini osservati.                   |
|            |            |          |                        | Vettore: E = < O3, C1, R1, S1 >      |
+------------+------------+----------+------------------------+--------------------------------------+
| Integro    | Alterato   | Alterato | ORR_b == 1.00          | Trasformazione Client-Side:          |
|            |            |          | [0.478, 1.000] (Pilota)| Avvenuta nel percorso U -> C_req     |
|            |            |          |                        | (H1a SUPPORTED).                     |
|            |            |          |                        | Vettore: E = < O3, C1, R1, S3 >      |
+------------+------------+----------+------------------------+--------------------------------------+
| Integro    | Integro    | Alterato | ORR_b == 1.00          | Trasformazione Post-Client:          |
|            |            |          | [0.478, 1.000] (Pilota)| Avvenuta a valle di C_req.           |
|            |            |          |                        | Causa tra H2, H3, H4, H5             |
|            |            |          |                        | INDETERMINATA.                       |
|            |            |          |                        | Vettore: E = < O3, C1, R1, S5 >      |
+------------+------------+----------+------------------------+--------------------------------------+
| Integro    | Integro    | Alterato | ORR_b < 1.00           | Varianza di Canale o Generativa:     |
|            |            |          | (Varianza osservata)   | Fenomeno non deterministico; compa-  |
|            |            |          |                        | tibile con sampling (T > 0) o        |
|            |            |          |                        | instabilita' di routing distribuito. |
+------------+------------+----------+------------------------+--------------------------------------+
| Integro    | NO-CAPTURE | Alterato | ORR_b == 1.00          | Discrepanza End-to-End (Modalita' B):|
|            |            |          | [0.478, 1.000] (Pilota)| Impossibile localizzare la causa     |
|            |            |          |                        | lungo la catena U -> O.              |
|            |            |          |                        | Vettore: E = < O1, C0, R1, S1 >      |
+----------------------------------------------------------------------------------------------------+
```

---
*Fine delle Specifiche Teoriche Ufficiali — CHANNEL DISCOVERY PROTOCOL (CDP v2.3)*
