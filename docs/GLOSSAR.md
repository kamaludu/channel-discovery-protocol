## CHANNEL DISCOVERY PROTOCOL (CDP / SOP v2.3)
# 📖 GLOSSARIO GENERALE E GUIDA INTERPRETATIVA ​
### *Standard di Laboratorio, Epistemologia Sperimentale e Metrologia dei Sistemi Black-Box*

---

**INDICE**
- Sezione 0 — **Dizionario Sigle e Acronimi (A - Z)**
- Sezione 1 — **Assiomatica ed Epistemologia Metrologica**
- Sezione 2 — **La Catena delle Variabili di Canale (U -> O)**
- Sezione 3 - **I LAYER DI OSSERVABILITÀ (V0 - V5) E CLASSIFICAZIONE V3**
- Sezione 4 - **LO SPAZIO DELLE IPOTESI CONCORRENTI (H1 - H5)**
- Sezione 5 - **TASSONOMIA DEI CRITERI DI CONFRONTO DELL'OUTPUT (CLASSE M)**
- Sezione 6 - **IL VETTORE DI EVIDENZA `E = < O_x, C_x, R_x, S_x >`**
- Sezione 7 — **Mensurandi, Statistica e Incertezza**
- Sezione 8 - **STATI DI VALUTAZIONE E MATRICE DI DIAGNOSI DIFFERENZIALE**
- Sezione 9 - **THE QUADRUPLET RULE E REFERTAZIONE SOTU v2.3**

---

## SEZIONE 0: 🔍 DIZIONARIO DELLE SIGLE E DEGLI ACRONIMI 
*(Voci indicizzate per la ricerca immediata con Ctrl+F nel browser)*

---

### 0.1 BPE — Byte-Pair Encoding

* **TERMINE / SIMBOLO**: `BPE` | `Byte-Pair Encoding`
* **DEFINIZIONE METROLOGICA**: Algoritmo deterministico di compressione e tokenizzazione statistica subword-based. Costruisce ricorsivamente un vocabolario finito `|V|` fondendo iterativamente le coppie di byte o caratteri piu' frequenti identificate nel corpus di addestramento.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Subword*: Unita' testuale intermedia tra il singolo carattere tipografico e la parola intera delimitata da spazi.
  * *Vocabolario (|V|)*: Tabella discreta di mapping che associa a ogni token un indice intero compreso tra `0` e `|V| - 1`.
* ***NOTA PRATICA***: E' il modo in cui i modelli LLM leggono il testo. Invece di guardare le singole lettere, il BPE raggruppa sillabe o blocchi di parole comuni in numeri singoli. Sequenze rare o codici speciali vengono frammentati in pezzi insoliti, originando spesso errori di elaborazione.

---

### 0.2 CDP — Channel Discovery Protocol

* **TERMINE / SIMBOLO**: `CDP` | `Channel Discovery Protocol`
* **DEFINIZIONE METROLOGICA**: Framework teorico, normativo ed epistemologico per l'identificazione formale di sistemi a scatola nera (*Black-Box System Identification*). Definisce i modelli analitici di canale, i layer di osservabilita' `V0 - V5`, la matrice di claim strength `L0 - L4` e la tassonomia dei criteri di confronto `M`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Black-Box System Identification*: Disciplina ingegneristica volta a modellare matematicamente le trasformazioni di un sistema opaco basandosi unicamente sul contrasto controllato tra segnali di ingresso e segnali di uscita.
* ***NOTA PRATICA***: E' la "costituzione teorica" dell'intero framework. Stabilisce cosa e' scientificamente lecito affermare e vieta di fare supposizioni non verificate su cosa accade dentro i server remoti.

---

### 0.3 CDP-FZ — Channel Discovery Protocol Fuzzing Extension (Appendice A)

* **TERMINE / SIMBOLO**: `CDP-FZ` | `Protocol Fuzzing Extension`
* **DEFINIZIONE METROLOGICA**: Modulo di estensione sperimentale formalmente segregato dalla SOP ordinaria, dedicato all'iniezione diretta a livello di socket di frame WebSocket malformati, sequenze non-UTF-8 e byte RAW per testare la robustezza dei parser di trasporto.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Fuzzing*: Tecnica di test consistente nell'inviare dati di ingresso non validi, imprevisti o casuali per provocare crash o errori di protocollo.
* ***NOTA PRATICA***: E' il protocollo per i test di "sfondamento" a basso livello. Serve a verificare se il server si rompe quando gli invii byte corrotti, ed e' utilizzabile solo su endpoint autorizzati o modelli locali.

---

### 0.4 CI / CI_95% — Confidence Interval (Intervallo di Confidenza al 95%)

* **TERMINE / SIMBOLO**: `CI` | `CI_95%` | `Confidence Interval`
* **DEFINIZIONE METROLOGICA**: Intervallo di stima parametrica o non parametrica `[Lower_Bound, Upper_Bound]` che, sotto campionamento ripetuto sotto le medesime condizioni sperimentali, racchiude il vero valore del parametro ignoto della popolazione con una frequenza a lungo termine pari al 95% (`1 - alpha = 0.95`).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * `alpha`: Livello di significativita' o probabilita' di errore di primo tipo (fissato standard a `0.05`).
* ***NOTA PRATICA***: E' la "forchetta di precisione" dei dati. Ti mostra entro quali valori minimi e massimi si trova il risultato reale, impedendoti di trarre conclusioni affrettate basate su un singolo numero fortunato.

---

### 0.5 CSPRNG — Cryptographically Secure Pseudo-Random Number Generator

* **TERMINE / SIMBOLO**: `CSPRNG` | `Cryptographically Secure PRNG`
* **DEFINIZIONE METROLOGICA**: Generatore algoritmico di numeri pseudocasuali che soddisfa il postulato di impredicibilita' crittografica (Next-Bit Test) e garantisce resistenza alla ricostruzione dello stato interno, impiegato per la sintesi di canary e nonce sperimentali mono-uso (*fresh*).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Nonce*: Stringa alfanumerica generata per essere utilizzata una sola ed esclusiva volta (`Number Used Once`), garantendo collisione nulla tra sessioni indipendenti.
* ***NOTA PRATICA***: E' il generatore di numeri casuali ad altissima sicurezza. Assicura che i codici segreti immessi nei test siano sempre unici al mondo e impossibili da indovinare per il modello.

---

### 0.6 DAG — Directed Acyclic Graph (Grafo Causale Diretto Acomplesso)

* **TERMINE / SIMBOLO**: `DAG` | `Directed Acyclic Graph`
* **DEFINIZIONE METROLOGICA**: Struttura matematica e topologica `G = < V, E >` composta da nodi `V` (variabili sperimentali) e archi orientati `E` (relazioni causali dirette) priva di circuiti chiusi. Utilizzata per formalizzare l'identificazione causale strutturale (`C3`) e la provenienza del dato.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Acomplesso*: Assenza strutturale di percorsi ad anello, che garantisce che una causa non possa mai essere effetto di se stessa.
* ***NOTA PRATICA***: E' una mappa di frecce a senso unico. Spiega come le variabili si influenzano l'una con l'altra (es. `Input -> Rete -> Modello -> Schermo`) senza mai creare contraddizioni logiche o cerchi viziosi.

---

### 0.7 DOM — Document Object Model

* **TERMINE / SIMBOLO**: `DOM` | `Document Object Model`
* **DEFINIZIONE METROLOGICA**: Struttura dati ad albero gerarchico residente nella memoria RAM del browser/client, rappresentante il documento web strutturato. Nel CDP costituisce il confine per l'ispezione di `U_buffer` (pre-invio) e `O_dom` (post-ricezione).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Text Node*: Elemento terminale dell'albero DOM contenente esclusivamente sequenze scalari prive di tag di marcatura.
* ***NOTA PRATICA***: E' lo scheletro della pagina web memorizzato nel browser. E' il posto dove il tuo messaggio risiede un istante prima di partire e dove la risposta viene salvata prima di essere dipinta a schermo.

---

### 0.8 EGC — Extended Grapheme Cluster (Unicode UAX #29)

* **TERMINE / SIMBOLO**: `EGC` | `Extended Grapheme Cluster`
* **DEFINIZIONE METROLOGICA**: Sequenza ordinata di uno o piu' Unicode Scalar Values che definisce una singola unita' grafica indivisibile percepita dall'utente umano, calcolata applicando deterministicamente le regole di segmentazione formale dell'Unicode Standard Annex #29.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Grafema Esteso*: L'unione inscindibile di un carattere base con diacritici combinatori, modificatori di tonalita' o connettori Zero-Width Joiner (es. emoji composite).
* ***NOTA PRATICA***: E' il "carattere visivo reale". Un'emoji complessa con bandiera o tono di pelle puo' essere formata da 4 codici informatici diversi: l'EGC la tratta come un unico blocco che non puo' essere tagliato a meta'.

---

### 0.9 FSM — Finite State Machine (Macchina a Stati Finiti)

* **TERMINE / SIMBOLO**: `FSM` | `Finite State Machine`
* **DEFINIZIONE METROLOGICA**: Modello formale di computazione descritto dalla tupla `< Q, Sigma, delta, q_0, F >`, dove `Q` e' l'insieme degli stati della sessione, `Sigma` le azioni di protocollo e `delta` la funzione di transizione deterministica che regola l'avanzamento dei trial preregistrati.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Stato della Sessione*: La condizione esatta del contesto (es. `SA.Q0` sessione vergine, `SA.Q1` stimolo somministrato, `SA.Q2` distrattore inviato).
* ***NOTA PRATICA***: E' il tabellone di marcia del test. Tiene traccia precisa di ogni fase della conversazione, garantendo che i test vengano eseguiti sempre nello stesso ordine senza salti arbitrari.

---

### 0.10 GQA — Grouped-Query Attention

* **TERMINE / SIMBOLO**: `GQA` | `Grouped-Query Attention`
* **DEFINIZIONE METROLOGICA**: Variante architetturale dei moduli di attenzione multi-testa in cui piu' teste di Query (*Query Heads*) condividono un singolo gruppo di teste di Chiave (*Key*) e Valore (*Value*), riducendo l'impronta di memoria della KV-Cache mantenendo un'elevata capacita' rappresentativa.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Query/Key/Value*: Proiezioni lineari dei vettori di attivazione utilizzate dal meccanismo di Self-Attention per calcolare l'interdipendenza contestuale tra token.
* ***NOTA PRATICA***: E' una soluzione ingegneristica usata nei modelli moderni (come Llama 3) per risparmiare memoria RAM della scheda video senza far perdere intelligenza al modello.

---

### 0.11 KV-Cache — Key-Value Cache

* **TERMINE / SIMBOLO**: `KV-Cache` | `Key-Value Cache`
* **DEFINIZIONE METROLOGICA**: Buffer di memoria ad altissimo throughput allocato nella VRAM delle GPU/TPU di inferenza. Memorizza i tensori di Chiave e Valore calcolati nei passi autoregressivi precedenti, evitando la ricalcolazione quadratica della storia del contesto.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *VRAM*: Memoria video ad alta larghezza di banda su cui risiedono i pesi e gli stati intermedi del modello durante l'esecuzione.
* ***NOTA PRATICA***: E' la memoria di lavoro rapida del modello. Serve a non fargli rileggere da zero tutta la conversazione a ogni singola parola che scrive. Nel CDP e' vietato affermare di averla vista se non si sta eseguendo il modello sul proprio computer (`V5`).

---

### 0.12 MDE — Minimum Detectable Effect (Delta_min)

* **TERMINE / SIMBOLO**: `MDE` | `Delta_min` | `Minima Differenza Rilevante`
* **DEFINIZIONE METROLOGICA**: Soglia quantitativa minima stabilita *a priori* nel disegno sperimentale preregistrato al di sotto della quale una divergenza metrologica (es. `Delta_min = 100 ms` per latenza o `Delta_min = 1 token` per accounting) e' convenzionalmente considerata priva di rilevanza ingegneristica o applicativa.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Rilevanza Ingegneristica*: Entita' minima di una variazione affinche' essa produca un impatto tangibile sulle prestazioni o sull'architettura del sistema.
* ***NOTA PRATICA***: E' la soglia del "rumore trascurabile". Se un test rileva che un carattere speciale fa rallentare il modello di mezzo millesimo di secondo, l'MDE ci ricorda che questa differenza e' troppo minuscola per avere importanza pratica.

---

### 0.13 MHA — Multi-Head Attention

* **TERMINE / SIMBOLO**: `MHA` | `Multi-Head Attention`
* **DEFINIZIONE METROLOGICA**: Architettura classica di attenzione introdotta nei modelli Transformer, in cui ogni testa di Query possiede una corrispondente testa indipendente e dedicata di Key e Value.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Matrice di Attenzione*: Matrice quadrata `N x N` a righe stocastiche risultante dall'applicazione della funzione Softmax sul prodotto scalare scalato `(Q * K^T) / sqrt(d_k)`.
* ***NOTA PRATICA***: E' il motore di attenzione originario dei Transformer. Permette al modello di guardare parole diverse in punti diversi della frase nello stesso momento.

---

### 0.14 MOE — Margin of Error (Margine di Errore)

* **TERMINE / SIMBOLO**: `MOE` | `Margin of Error`
* **DEFINIZIONE METROLOGICA**: Il semiampliezza dell'intervallo di confidenza calcolato attorno allo stimatore puntuale:
  ```text
  MOE = (Upper_Bound - Lower_Bound) / 2
  ```
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Semiampliezza*: Il raggio di incertezza statistica simmetrico o asimmetrico associato alla stima campionaria.
* ***NOTA PRATICA***: E' il classico "piu' o meno" della statistica. Ti dice quanto e' stretta la stima del tuo test (es. 90% con MOE del 5% significa che il valore reale e' compreso tra 85% e 95%).

---

### 0.15 MQA — Multi-Query Attention

* **TERMINE / SIMBOLO**: `MQA` | `Multi-Query Attention`
* **DEFINIZIONE METROLOGICA**: Variante del meccanismo di attenzione in cui tutte le teste di Query condividono una sola e identica coppia di teste Key e Value, massimizzando il risparmio di banda di memoria a spese di una lieve riduzione della capacita' modellante.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Memory Bandwidth Bottleneck*: Il limite fisico di velocita' con cui i dati vengono trasferiti tra la VRAM e i core di calcolo della GPU.
* ***NOTA PRATICA***: E' una versione ultra-leggera del motore attentivo, progettata per far funzionare i modelli molto velocemente su server con poca memoria.

---

### 0.16 NLI — Natural Language Inference

* **TERMINE / SIMBOLO**: `NLI` | `Natural Language Inference`
* **DEFINIZIONE METROLOGICA**: Paradigma formale di elaborazione del linguaggio naturale per stabilire la relazione logica tra due enunciati testuali (Premessa `P` e Ipotesi `H`), con classificazione deterministica in *Entailment* (implicazione), *Contradiction* (contraddizione) o *Neutral* (neutralita').
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Entailment Bidirezionale*: Criterio formale per `M5` in cui `P` implica `H` e contemporaneamente `H` implica `P` con probabilita' superiore alla soglia `tau_NLI`.
* ***NOTA PRATICA***: E' il sistema informatico che valuta se due frasi significano esattamente la stessa cosa anche se usano vocaboli e strutture grammaticali totalmente differenti.

---

### 0.17 OFAT — One-Factor-At-A-Time (Ladder Sperimentale)

* **TERMINE / SIMBOLO**: `OFAT` | `One-Factor-At-A-Time`
* **DEFINIZIONE METROLOGICA**: Metodo sperimentale di isolamento in cui ogni stimolo intermedio della catena differisce dal precedente per la manipolazione controllata di **una singola variabile atomica** (`C^0 -> C_1 -> C_2 -> C_3 -> T`), fornendo evidenza comparativa `C1`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Isolamento Monofattoriale*: Divieto di modificare contemporaneamente due parametri o caratteri nello stesso gradino sperimentale.
* ***NOTA PRATICA***: E' il test "un passo alla volta". Si aggiunge una sola lettera o un solo simbolo alla volta per scoprire esattamente quale elemento fa scattare l'errore nel modello.

---

### 0.18 OOV — Out-Of-Vocabulary

* **TERMINE / SIMBOLO**: `OOV` | `Out-Of-Vocabulary`
* **DEFINIZIONE METROLOGICA**: Condizione metrologica in cui una sequenza o codepoint in ingresso non e' mappabile su alcun token presente nella tabella del tokenizer, imponendo il ricorso a token speciali di fallback (`<unk>`) o la frammentazione forzata in byte grezzi isolati.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Byte-Level Fallback*: Tecnica che mappa caratteri sconosciuti sui rispettivi valori esadecimali UTF-8 `[0x00 .. 0xFF]`.
* ***NOTA PRATICA***: E' un carattere "sconosciuto" al vocabolario del modello. Quando accade, il sistema e' costretto a fare i salti mortali per leggerlo pezzo per pezzo, rischiando di fraintenderlo.

---

### 0.19 OPSEC — Operations Security (Igiene di Misura)

* **TERMINE / SIMBOLO**: `OPSEC` | `Operations Security`
* **DEFINIZIONE METROLOGICA**: Protocollo normativo per la bonifica e protezione dei dati di laboratorio. Impone il mascheramento preventivo e categorico di token di autenticazione Bearer, API key, identificatori utente e cookie di sessione da ogni file di log e referto pubblico.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Redacting*: Procedura di cancellazione o offuscamento irreversibile dei dati sensibili prima dell'archiviazione del report.
* ***NOTA PRATICA***: E' l'igiene di sicurezza del laboratorio. Cancella automaticamente chiavi API e password dai report prima che vengano condivisi o salvati.

---

### 0.20 ORR / ORR_b — Observed Replication Rate

* **TERMINE / SIMBOLO**: `ORR` | `ORR_b` | `Observed Replication Rate`
* **DEFINIZIONE METROLOGICA**: Rapporto matematico tra il numero di trial conformi `k` e il numero totale di prove valide eseguite `N_valid`:
  ```text
  ORR_b = k / N_valid      con N_valid = N_attempts - N_invalid
  ```
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * `N_invalid`: Prove nulle a causa di anomalie esterne (es. caduta connessione, input buffer errato).
* ***NOTA PRATICA***: E' la percentuale reale di successo ottenuta nelle prove valide (es. 5 successi su 5 prove valide = 1.00, ovvero 100%).

---

### 0.21 RTT — Round-Trip Time

* **TERMINE / SIMBOLO**: `RTT` | `Round-Trip Time`
* **DEFINIZIONE METROLOGICA**: Tempo fisico impiegato da un pacchetto dati per transitare dal client locale al server remoto e ritornare alla sonda di cattura originaria, misurato sul layer di trasporto TCP/TLS.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Jitter*: Varianza statistica dell'RTT indotta da congestioni di rete intermedie.
* ***NOTA PRATICA***: E' il ping della tua connessione internet. Misura quanti millisecondi impiega un segnale per fare andata e ritorno.

---

### 0.22 SHA-256 — Secure Hash Algorithm 256-bit

* **TERMINE / SIMBOLO**: `SHA-256` | `Digest SHA-256`
* **DEFINIZIONE METROLOGICA**: Funzione di hash crittografico unidirezionale (FIPS PUB 180-4) che trasforma una stringa di byte UTF-8 canonica in un'impronta esadecimale deterministica e non invertibile a 64 caratteri (256 bit).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Integrita' Canonica*: Verifica dell'identita' del testo mediante uguaglianza degli hash:
    ```text
    SHA256( enc_UTF8(U) ) == SHA256( enc_UTF8(C_req_unicode) )
    ```
* ***NOTA PRATICA***: E' l'impronta digitale assoluta del testo. Se cambi anche solo un carattere invisibile, l'hash cambia radicalmente, smascherando ogni minima alterazione.

---

### 0.23 SOP — Standard Operating Procedure

* **TERMINE / SIMBOLO**: `SOP` | `Standard Operating Procedure`
* **DEFINIZIONE METROLOGICA**: Manuale operativo vincolante di laboratorio che codifica le procedure strumentali, la calibrazione `RUN 0`, la catena metrologica `O -> M -> B -> H` e le regole di esecuzione della suite di test `T01 - T14`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Standardizzazione*: Protocollo procedurale rigido che azzera la variabilita' esecutiva introdotta dall'operatore umano.
* ***NOTA PRATICA***: E' il manuale operativo pratico che ti guida passo-passo nell'esecuzione corretta dei test.

---

### 0.24 SOTU — State Of The Unit (Verbale di Prova)

* **TERMINE / SIMBOLO**: `SOTU` | `State Of The Unit`
* **DEFINIZIONE METROLOGICA**: Struttura documentale unificata di refertazione metrologica che certifica i risultati di un'unita' di test articolando obbligatoriamente i quattro pilastri della *Quadruplet Rule* e il Vettore di Evidenza `E`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Master Report*: Documento finale Markdown immutabile archiviato al termine della sessione.
* ***NOTA PRATICA***: E' il referto finale ufficiale che sintetizza i risultati del test.

---

### 0.25 SSE — Server-Sent Events

* **TERMINE / SIMBOLO**: `SSE` | `Server-Sent Events`
* **DEFINIZIONE METROLOGICA**: Standard di trasporto HTTP unidirezionale persistente che consente al server di trasmettere flussi asincroni di eventi testuali formattati come payload `data: {...}\n\n`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Streaming Chunk*: Singolo pacchetto di testo emesso dal server man mano che i token vengono generati.
* ***NOTA PRATICA***: E' la tecnologia che fa apparire le parole a schermo una alla volta mentre il modello sta ancora elaborando.

---

### 0.26 SUT — System Under Test

* **TERMINE / SIMBOLO**: `SUT` | `System Under Test`
* **DEFINIZIONE METROLOGICA**: Tupla invariante a 6 elementi che identifica il sistema indagato:
  ```text
  SUT = < Provider, Model_ID, Runtime_Version, Interface_Type, Sampling_Configuration, Environment_Flags >
  ```
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Invarianza del SUT*: Principio che vieta di aggregare statisticamente test condotti con configurazioni di campionamento o interfacce differenti.
* ***NOTA PRATICA***: E' la carta d'identita' rigorosa del modello e del software che stai testando.

---

### 0.27 TTFT — Time-To-First-Token

* **TERMINE / SIMBOLO**: `TTFT` | `TTFT_observed_e2e`
* **DEFINIZIONE METROLOGICA**: Latenza fisica misurata in millisecondi tra l'invio dell'ultimo byte della richiesta sul socket di rete e la ricezione del primo byte utile del primo chunk di risposta.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Mensurando Differenziale*: Grandezza continua utilizzata nel Test T12 per confrontare due condizioni tramite disegni a blocchi appaiati (ABAB).
* ***NOTA PRATICA***: E' il tempo di reazione iniziale del sistema: quanti millisecondi passano prima che compaia la prima lettera della risposta.

---

### 0.28 UAX — Unicode Standard Annex (UAX #15, UAX #29)

* **TERMINE / SIMBOLO**: `UAX` | `Unicode Standard Annex`
* **DEFINIZIONE METROLOGICA**: Documenti tecnici vincolanti dell'Unicode Consortium:
  * `UAX #15`: Definisce le forme di normalizzazione del testo (`NFC`, `NFD`, `NFKC`, `NFKD`).
  * `UAX #29`: Definisce la segmentazione del testo in Extended Grapheme Clusters, parole e frasi.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Normalizzazione*: Algoritmo che trasforma rappresentazioni binarie diverse di caratteri equivalenti in una forma binaria standard unica.
* ***NOTA PRATICA***: Sono le regole universali del testo digitale per gestire lettere accentate, simboli speciali ed emoji.

---

### 0.29 WAF — Web Application Firewall

* **TERMINE / SIMBOLO**: `WAF` | `Web Application Firewall`
* **DEFINIZIONE METROLOGICA**: Modulo di protezione di rete intermedio server-side (`H2a`) che analizza e filtra il traffico HTTP in ingresso bloccando o modificando richieste con pattern non consentiti prima dell'inoltro al context builder.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Sanitizzazione Trasparente*: Alterazione del payload applicata dal firewall all'insaputa del client mittente.
* ***NOTA PRATICA***: E' il filtro di sicurezza del server che blocca o ripulisce i messaggi prima che arrivino all'intelligenza artificiale.

---

### 0.30 WS — WebSocket (RFC 6455)

* **TERMINE / SIMBOLO**: `WS` | `WebSocket`
* **DEFINIZIONE METROLOGICA**: Protocollo standard di trasporto di rete bidirezionale e full-duplex su singola connessione TCP, dotato di codici formali di controllo del frame e chiusura (`1000`, `1001`, `1008`, `1011`).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Frame Control*: Pacchetti speciali del protocollo WebSocket utilizzati per verificare la salute della connessione (ping/pong) o notificare chiusure ordinate.
* ***NOTA PRATICA***: E' un canale di comunicazione bidirezionale continuo e velocissimo tra il tuo browser e il server.

---

### 0.31 ZWNBSP / BOM — Zero-Width No-Break Space / Byte Order Mark (U+FEFF)

* **TERMINE / SIMBOLO**: `ZWNBSP` | `BOM` | `U+FEFF`
* **DEFINIZIONE METROLOGICA**: Codepoint Unicode speciale appartenente alla categoria *Format (Cf)*. Se posizionato a inizio file indica l'ordine dei byte (Byte Order Mark); se posizionato all'interno del flusso funge da spazio insecabile a larghezza zero.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Codepoints Cf*: Caratteri di controllo tipografico non stampabili a schermo.
* ***NOTA PRATICA***: E' un codice invisibile usato in informatica per segnalare come leggere i file o per unire parole senza lasciare spazi visibili.

---

### 0.32 ZWNJ — Zero-Width Non-Joiner (U+200C)

* **TERMINE / SIMBOLO**: `ZWNJ` | `U+200C`
* **DEFINIZIONE METROLOGICA**: Codepoint Unicode della categoria *Format (Cf)* impiegato nei sistemi tipografici complessi per inibire esplicitamente la formazione di legature tipografiche tra caratteri adiacenti, senza introdurre spaziatura grafica visibile.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Legatura Tipografica*: Fusione grafica di due lettere adiacenti in un unico glifo (es. "fi").
* ***NOTA PRATICA***: E' un separatore invisibile: dice al computer di non fondere due lettere insieme, pur senza lasciare alcuno spazio visibile.

---

### 0.33 ZWSP — Zero-Width Space (U+200B)

* **TERMINE / SIMBOLO**: `ZWSP` | `U+200B`
* **DEFINIZIONE METROLOGICA**: Codepoint Unicode della categoria *Format (Cf)* che inserisce un punto di interruzione di riga potenziale a larghezza zero, senza alcun rendering grafico visibile.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Line-Break Opportunity*: Indicazione per il motore di rendering del browser che consente di andare a capo in quel punto se necessario.
* ***NOTA PRATICA***: E' uno spazio totalmente invisibile a larghezza zero, utilizzato nei test CDP (come T04) per scoprire se i modelli o i server cancellano i caratteri nascosti.

---

### INTEGRAZIONE SIGLE DI INFRASTRUTTURA E STANDARD

* **`API` — Application Programming Interface**: Insieme di definizioni e protocolli che consentono a due componenti software di comunicare (nel SUT: gli endpoint HTTP REST/RPC dei vendor).
* **`CLI` — Command Line Interface**: Interfaccia a riga di comando tramite cui l'orchestratore (`cdp_run.sh`) riceve i parametri operativi.
* **`HTTP` / `HTTPS` — Hypertext Transfer Protocol (Secure)**: Protocollo applicativo su cui transitano le richieste `C_req` e le risposte `C_resp` cifrate tramite TLS.
* **`JSON` — JavaScript Object Notation (RFC 8259)**: Formato standard di interscambio dati testuale strutturato a coppie chiave-valore e array ordinati.
* **`LLM` — Large Language Model**: Rete neurale profonda basata su architettura Transformer addestrata su compiti autoregressivi di modellazione del linguaggio.
* **`MAD` — Median Absolute Deviation**: Misura statistica robusta di dispersione dei dati attorno alla mediana, non influenzata dalla presenza di valori anomali (outlier) nei test di latenza.
* **`POSIX` — Portable Operating System Interface**: Standard internazionale (IEEE 1003.1) che definisce le API di sistema operativo e la sintassi della shell per garantire portabilità tra Linux, Android/Termux e macOS.
* **`RFC` — Request For Comments**: Documenti formali pubblicati dall'Internet Engineering Task Force (IETF) che definiscono gli standard di internet (es. RFC 6455 per WebSocket, RFC 8259 per JSON).
* **`TLS` — Transport Layer Security**: Protocollo crittografico che garantisce confidenzialità e integrità dei dati scambiati sul socket di trasporto.
* **`UTF-8` — 8-bit Unicode Transformation Format**: Codifica a lunghezza variabile (da 1 a 4 byte per codepoint) standard universale del Web e del protocollo CDP.
* **`UUID` — Universally Unique Identifier**: Identificatore alfanumerico standard a 128 bit utilizzato per nominare univocamente le cartelle di sessione (`RUN_<TIMESTAMP>_<NONCE>`).
* **`VIM` — Vocabolario Internazionale di Metrologia (JCGM 200)**: Standard mondiale di riferimento per le definizioni dei concetti fondamentali della misurazione (mensurando, incertezza, precisione).

---

## SEZIONE 1: ASSIOMATICA ED EPISTEMOLOGIA METROLOGICA

```text
+-------------------------------------------------------------------------------+
|                         QUADRO DEI PRINCIPI EPISTEMICI                        |
|                                                                               |
|  [ Falsificazionismo ] ──> Esclusione rigorosa di ipotesi incompatibili       |
|  [ Boundary Certainty ] ──> Nessun salto causale oltre il confine misurato    |
|  [ Triade dei Claim ]   ──> Claim A (Obs) /=> Claim B (Loc) /=> Claim C (Mec) |
|  [ Postulato not(Obs) ] ──> not(Obs(X)) /=> not(X) [NOT DETECTED != ABSENT]   |
|  [ Golden Rule ]        ──> Strength(Claim) <= Strength(Evidence)             |
|  [ Proxy != Meccanismo] ──> La variazione metrica non spiega l'architettura   |
+-------------------------------------------------------------------------------+
```

---

### 1.1 Falsificazionismo Conservativo vs Induzione

* **TERMINE / SIMBOLO**: `Falsificazionismo Conservativo vs Induzione`
* **DEFINIZIONE METROLOGICA**: Principio epistemico fondazionale del protocollo CDP che impone di strutturare ogni protocollo sperimentale esclusivamente per delimitare lo spazio delle ipotesi ammissibili ed **escludere formalmente i modelli incompatibili** con i dati empirici (`H_i == FALSE`), vietando categoricamente la validazione o la conferma positiva di euristiche interne tramite accumulo induttivo di casi conformi (`P(H_i | Data) == 1.0` non e' mai dimostrabile su sistemi a scatola nera).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Falsificazione*: Processo logico-deduttivo mediante il quale un'ipotesi predice un evento `E`; se l'osservazione rileva `not(E)`, l'ipotesi e' categoricamente respinta (modus tollens).
  * *Induzione*: Procedimento inferenziale che pretende di estrapolare una legge generale o un meccanismo interno invariante a partire dalla reiterazione di osservazioni positive particolari (approccio formalmente rigettato dal CDP in quanto vulnerabile al problema del cigno nero).
  * *Ipotesi Ammissibili*: Insieme residuale dei modelli architetturali o fisici che non sono ancora stati disconfermati dai dati empirici raccolti.
* ***NOTA PRATICA***: Se vedi un modello LLM riprodurre correttamente 1.000 volte una stringa, non hai dimostrato come funziona all'interno ne' che non la modifichera' mai. Hai solo dimostrato che l'ipotesi che quel modello fallisca in quelle 1.000 condizioni e' falsa. Nei report SOTU non troverai mai scritto "il modello funziona cosi'", ma "i dati raccolti escludono che il modello abbia applicato la trasformazione X".

---

### 1.2 Boundary Certainty (Confine di Evidenza Certo)

* **TERMINE / SIMBOLO**: `Boundary Certainty`
* **DEFINIZIONE METROLOGICA**: Assioma normativo che vieta la formulazione di asserzioni causali su strati elaborativi o componenti fisici non direttamente intercettati da sonde di misura strumentate. Qualsiasi trasformazione dello stimolo che si verifichi a valle dell'ultimo confine strumentalmente osservato deve essere formalmente rubricata come **architetturalmente indeterminata** (`UNDERDETERMINED` o `NOT DETERMINED`).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Confine Strumentato*: La superficie fisica o logica esatta in cui uno strumento di misura (es. sniffer di rete, logger del DOM, debugger di memoria) cattura lo stato dei dati senza intermediari opachi.
  * *Asserzione Causale*: Affermazione secondo cui l'azione o mutazione `X` e' stata prodotta in modo necessario e sufficiente dal componente `Y`.
  * *Indeterminatezza Architetturale*: Stato formale in cui molteplici spiegazioni teoriche concorrenti sono indistinguibili a causa dell'assenza di strumentazione sui layer intermedi.
* ***NOTA PRATICA***: Se stai guardando i pacchetti che escono dal tuo browser e poi guardi il testo che appare a schermo, tutto cio' che accade dentro i server remoti del provider e' una stanza buia. Il principio di Boundary Certainty ti vieta di dire "il server ha fatto questo", perche' non hai occhi dentro quel server. Puoi solo dire cosa e' entrato e cosa e' uscito.

---

### 1.3 La Triade dei Claim e Regola di Non-Trascendenza

* **TERMINE / SIMBOLO**: `La Triade dei Claim` | `Claim A /=> Claim B /=> Claim C` | `Regola di Non-Trascendenza`
* **DEFINIZIONE METROLOGICA**: Gerarchia di derivazione logica che articola le conclusioni sperimentali su tre livelli vincolati:
  * `Claim A (Osservazione)`: Asserzione puramente descrittiva su un dato rilevato allo strumento sul confine di misura.
  * `Claim B (Localizzazione)`: Asserzione sul confine logico o fisico entro cui si e' verificata la variazione dello stimolo.
  * `Claim C (Meccanismo)`: Asserzione sul componente architetturale interno che ha generato la trasformazione.
  La *Regola di Non-Trascendenza* sancisce che `Claim A /=> Claim B /=> Claim C` (il simbolo `/=>` denota *non implica logicamente*). Un risultato sperimentale non puo' essere refertato a un livello superiore senza la soddisfazione dei requisiti di misura del livello sottostante.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Non-Trascendenza*: Divieto formale di trasferire la certezza empirica di un'osservazione grezza (Claim A) a una congettura sulla sua collocazione topologica (Claim B) o sul suo motore meccanico (Claim C).
  * *Salto Inferenziale*: Errore metodologico consistente nell'utilizzare un dato del livello `N` per asserire conclusioni al livello `N+1` in assenza di sonde sul confine intermedio.
* ***NOTA PRATICA***:
  1. *Claim A*: "Ho visto sparire una lettera dall'output" (Fatto puro).
  2. *Claim B*: "La lettera e' sparita nel percorso tra il browser e la rete" (Richiede di aver sniffato i pacchetti di rete per dimostrarlo).
  3. *Claim C*: "Il tokenizer BPE del server ha cancellato la lettera perche' non era nel vocabolario" (Richiede di avere accesso al codice sorgente o ai tensori interni del modello).
  Non puoi usare il Claim A per spacciare il Claim C come verita'.

#### 1.3-bis LA CLAIM STRENGTH MATRIX A 5 LIVELLI (L0 - L4)

* **TERMINE / SIMBOLO**: `Claim Strength Matrix` | `Livelli L0 - L4`
* **DEFINIZIONE METROLOGICA**: Scala gerarchica normativa a 5 gradini che subordina la validità di qualsiasi conclusione al confine di osservabilità effettivamente intercettato, in ottemperanza alla *Regola di Non-Trascendenza*:
  * `Livello L0 [Raw Observation]`: Registrazione del dato empirico grezzo allo strumento (es. byte catturati sul socket).
  * `Livello L1 [Empirical Relation]`: Rilevazione di un differenziale controllato stimolo-risposta sotto specifico criterio `M`.
  * `Livello L2 [Localization Claim]`: Isolamento della trasformazione entro un confine strumentato certo (es. mutazione avvenuta in `U -> C_req`).
  * `Livello L3 [Local Mechanism]`: Identificazione dell'effetto causale locale tramite manipolazione interventistica (`do(X)`) o DAG validato.
  * `Livello L4 [Architectural Claim]`: Asserzione sui pesi, sull'attenzione o sull'architettura interna della rete neurale (consentito **esclusivamente** con Layer `V5[V]` attivo e documentato).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Regola di Non-Trascendenza*: Un verdetto non può essere classificato a livello `L_(n+1)` se non soddisfa pienamente i requisiti del livello `L_n`.
* ***NOTA PRATICA***: È la scala che impedisce di fare "il passo più lungo della gamba". Se hai testato un modello solo tramite API (senza guardare dentro i server di OpenAI o Google), puoi formulare al massimo claim di livello `L1` (comportamento) o `L2` (se hai sniffato la rete). I claim di livello `L4` (sul funzionamento del cervello del modello) sono severamente vietati.

---

### 1.4 Postulato not(Obs(X)) /=> not(X) (NOT DETECTED != ABSENT)

* **TERMINE / SIMBOLO**: `not(Obs(X)) /=> not(X)` | `NOT DETECTED != ABSENT`
* **DEFINIZIONE METROLOGICA**: Postulato di non-dimostrazione secondo cui la mancata rilevazione (`not(Obs(X))`) di un codepoint, token, struttura o segnale all'interno del layer terminale osservato `O` attesta esclusivamente che tale elemento e' `NOT DETECTED` sul confine strumentato, ma **non dimostra** che tale elemento non sia stato ricevuto, elaborato, memorizzato o rappresentato negli stadi intermedi inaccessibili (`S`, `Token IDs`, `M_raw`).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * `not(Obs(X))`: Predicato logico che indica che lo strumento di misura non ha intercettato l'evento `X`.
  * `not(X)`: Asserzione ontologica di inesistenza fisica o logica dell'evento `X` nell'intero sistema.
  * `NOT DETECTED`: Stato metrologico che certifica l'assenza di segnale entro la soglia di sensibilita' e sul perimetro dello strumento di misura utilizzato.
* ***NOTA PRATICA***: Se chiedi a un modello di restituirti un carattere invisibile e il modello non lo scrive nel messaggio finale, non puoi concludere che il modello non l'abbia letto o capito. Potrebbe averlo ricevuto, compreso benissimo nel suo contesto interno, ma semplicemente deciso (o filtrato) di non stamparlo a schermo. L'assenza della traccia visibile non e' prova dell'assenza di elaborazione interna.

---

### 1.5 Assioma di Non-Inclusione tra Layer

* **TERMINE / SIMBOLO**: `Assioma di Non-Inclusione tra Layer`
* **DEFINIZIONE METROLOGICA**: Principio topologico secondo cui l'assenza di osservazione di un fenomeno su un determinato confine di misura `Layer_k` non costituisce evidenza negativa ne' preclude la presenza del fenomeno sul confine successivo `Layer_(k+1)`, a meno che non sia rigorosamente dimostrata e formalizzata una relazione di inclusione causale necessaria e sufficiente tra i due confini.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Inclusione Causale*: Relazione deterministica in cui ogni stato del `Layer_(k+1)` e' funzione biiettiva e tracciabile dello stato del `Layer_k`.
  * *Evidenza Negativa*: Dato empirico che dimostra l'impossibilita' teorica o pratica del verificarsi di un evento.
* ***NOTA PRATICA***: Se un filtro del browser non tocca il tuo testo, non significa che il gateway del server non lo tocchi. E se non vedi un header HTTP cambiare, non significa che il server non abbia modificato il prompt internamente prima di darlo in pasto alla rete neurale. Ogni layer e' una scatola a se' finche' non viene intercettato.

---

### 1.6 Separazione tra Ordine Temporale e Causalita'

* **TERMINE / SIMBOLO**: `Separazione tra Ordine Temporale e Causalita'` | `t_A < t_B != Causa`
* **DEFINIZIONE METROLOGICA**: Canone metrologico che stabilisce che la rilevazione temporale sequenziale di due eventi `A` e `B` (con timestamp `t_A < t_B`) attesta esclusivamente un **ordine di protocollo** all'interno dello stream osservato, ma non costituisce prova di derivazione causale (`A -> B`). In assenza di un identificatore di correlazione applicativa univoco (`Correlation ID`) o di un intervento causale manipolativo (`do(A)`), l'inferenza causale basata sulla sola prossimita' temporale e' rigettata come fallacia del *post hoc ergo propter hoc*.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Ordine di Protocollo*: La successione cronologica con cui i pacchetti o gli eventi transitano attraverso un'interfaccia di rete o di esecuzione.
  * *Correlation ID*: Identificatore crittografico o alfanumerico univoco inserito nel frame di richiesta e restituito nel frame di risposta che lega deterministicamente i due eventi alla medesima transazione.
  * `do(A)`: Operatore di manipolazione causale (secondo il formalismo di Judea Pearl) in cui la variabile `A` e' forzata dall'esterno mantenendo invariato l'intero ambiente circostante.
* ***NOTA PRATICA***: Se invii una richiesta alle 12:00:00 e il server risponde alle 12:00:01 dicendo "Errore", non puoi dire con certezza che la tua richiesta ha provocato quell'errore. Il server potrebbe essere andato in crash per conto suo alle 12:00:00.5 per colpa di un altro utente. Senza un ID univoco che colleghi la tua richiesta a quella specifica risposta, la sequenza nel tempo non prova la causa.

---

### 1.7 Golden Rule: Strength(Claim) <= Strength(Evidence)

* **TERMINE / SIMBOLO**: `Golden Rule di Conservativita' Epistemica` | `Strength(Claim) <= Strength(Evidence)`
* **DEFINIZIONE METROLOGICA**: Regola fondamentale di ammissibilita' del framework CDP/SOP v2.3 che impone un vincolo di disuguaglianza formale: il livello di certezza, portata o estensione architetturale di qualsiasi claim refertato (`Strength(Claim)`) non puo' mai eccedere la forza dimostrativa, la risoluzione e l'isolamento causale dell'evidenza empirica fisicamente raccolta (`Strength(Evidence)`).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * `Strength(Claim)`: Grado di certezza e generalita' dell'affermazione conclusiva (da semplice constatazione di byte fino a modello teorico dei pesi interni).
  * `Strength(Evidence)`: Vettore quantitativo e qualitativo dei dati raccolti, funzione dell'osservabilita' (Asse O), dell'isolamento causale (Asse C) e della replicabilita' statistica (Asse R).
* ***NOTA PRATICA***: E' la regola d'oro anti-speculazione. Se hai fatto un test rapido con 5 prove guardando solo la schermata del telefono, puoi solo affermare cosa hai visto sullo schermo in quelle 5 prove. Non puoi scrivere nel report finale che "il modello ha un bug strutturale nell'attenzione", perche' la tua evidenza e' debole rispetto alla grandezza della tua affermazione.

---

### 1.8 Proxy != Meccanismo

* **TERMINE / SIMBOLO**: `Proxy != Meccanismo`
* **DEFINIZIONE METROLOGICA**: Principio di non-sovrapposizione ontologica secondo cui la misura quantitativa di una variabile proxy esterna o di una discrepanza comportamentale (es. incremento del Time-To-First-Token, variazione del conteggio dei token contabili dell'API, calo della replicabilita') **non costituisce identificazione** dell'entita' hardware, del modulo software o dell'algoritmo interno che l'ha generata.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Variabile Proxy*: Grandezza fisica o metrica indiretta direttamente misurabile (es. tempo di risposta, consumo di token) utilizzata per rilevare variazioni di stato in un sistema inaccessibile.
  * *Meccanismo*: La specifica implementazione algoritmica, strutturale o architetturale responsabile del comportamento (es. algoritmo di scheduling, KV-cache GPU, injection di prompt di sistema).
* ***NOTA PRATICA***: Se una macchina impiega 2 secondi in piu' per rispondere a una domanda con un carattere speciale, hai misurato un ritardo (proxy). Non hai scoperto che "il server ha un filtro di sicurezza per quel carattere" (meccanismo). Il ritardo potrebbe essere causato da saturazione della rete, da un tokenizer lento o dal semplice accodamento delle richieste. La misura esterna non spiega il motore interno.

---

### 1.9 Distinzione Semantica degli Stati di Giudizio

* **TERMINE / SIMBOLO**: `OBSERVED` | `SUPPORTED` | `NOT FALSIFIED` | `INFERRED` | `CAUSALLY IDENTIFIED` | `NOT DETERMINED`
* **DEFINIZIONE METROLOGICA**: Set di etichette linguistiche formali con semantica rigidamente disgiunta per la compilazione dei verbali:
  * `OBSERVED`: Dato grezzo fisicamente acquisito dallo strumento di misura sul confine designato.
  * `SUPPORTED`: Ipotesi che riceve evidenza empirica favorevole e riproducibile da un contrasto differenziale controllato.
  * `NOT FALSIFIED`: Ipotesi teorica che rimane compatibile con i dati osservati pur in assenza di sonde di cattura diretta.
  * `INFERRED`: Deduzione logica derivata formalmente sotto assunzioni esplicitamente dichiarate.
  * `CAUSALLY IDENTIFIED`: Effetto isolato univocamente tramite manipolazione interventistica contrastata (`do(X)` o DAG validato).
  * `NOT DETERMINED`: Fenomeno o layer strutturalmente inaccessibile alla configurazione strumentale adottata.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Semantica Disgiunta*: Proprieta' per cui i termini non possono essere utilizzati come sinonimi intercambiabili.
* ***NOTA PRATICA***: Sono i "mattoni del linguaggio scientifico" del report. Non puoi scrivere "abbiamo osservato che il server e' lento" se non hai sonde sul server: devi scrivere "e' stato OSSERVATO un ritardo al client, ed e' INFERITO che possa dipendere dal server, mentre il meccanismo esatto rimane NOT DETERMINED".

---

## SEZIONE 2: LA CATENA DELLE VARIABILI DI CANALE (DALL'INPUT ALL'OUTPUT)

```text
+------------------------------------------------------------------------------+
|                    CATENA DELLE TRASFORMAZIONI DI CANALE                     |
|                                                                              |
|  [U_intended] ──> [U_buffer] ──> [U_serialized] ──> [C_req (V3)]            |
|                                                            │                 |
|                                                      (Rete / Server)         |
|                                                            v                 |
|  [O_dom] <── [O_markdown] <── [C_resp (V3)] <── (M_raw) <── (S Context)    |
+------------------------------------------------------------------------------+
```

---

### 2.1 Catena Sequenziale di Canale e SUT (System Under Test)

* **TERMINE / SIMBOLO**: `Catena di Canale` | `SUT`
* **DEFINIZIONE METROLOGICA**: Modello formale a stadi discreti che descrive il tragitto del dato dallo stimolo generatore fino alla percezione dell'output finale. Il **System Under Test (SUT)** e' formalmente definito dalla tupla invariante:
  ```text
  SUT = < Provider, Model_ID, Runtime_Version, Interface_Type, Sampling_Configuration, Environment_Flags >
  ```
  La variazione di un singolo elemento della tupla invalida l'aggregazione dei dati sperimentali.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Provider*: L'infrastruttura o l'entita' commerciale che eroga il servizio (es. Groq, Mistral, OpenAI).
  * *Model_ID*: La stringa esatta che identifica l'asset dei pesi neurali interrogati (es. `llama-3.3-70b-versatile`).
  * *Sampling_Configuration*: Il vettore dei parametri di decodifica stocastica (Temperatura `T`, `top_p`, `max_tokens`, `seed`).
* ***NOTA PRATICA***: Il SUT e' l'identikit precisissimo del sistema che stai testando. Se esegui 3 test su Claude via Web e 2 test su Claude via API, non hai 5 test dello stesso SUT: hai due esperimenti diversi su due sistemi diversi, perche' il canale e il software attorno al modello cambiano radicalmente.

---

### 2.2 U_intended e U_source

* **TERMINE / SIMBOLO**: `U_intended` | `U_source`
* **DEFINIZIONE METROLOGICA**:
  * `U_source`: Rappresentazione sorgente astratta generata programmaticamente dal generatore di stimoli (es. array di byte in memoria o stringa nel codice sorgente dello script).
  * `U_intended`: La sequenza ordinata esatta di Unicode Scalar Values e byte UTF-8 che il disegno sperimentale preregistrato ha stabilito di trasmettere come stimolo formale al canale.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Unicode Scalar Value*: Qualsiasi valore numerico Unicode nell'intervallo da `U+0000` a `U+D7FF` e da `U+E000` a `U+10FFFF` (tutti i codepoint esclusi i surrogati UTF-16).
  * *Disegno Preregistrato*: Documento o file di configurazione congelato prima dell'inizio delle prove che definisce univocamente gli stimoli e i criteri di test.
* ***NOTA PRATICA***: `U_intended` e' il testo perfetto e immacolato che hai deciso di testare (es. "CANARY#123"). E' il punto di riferimento aureo contro cui verra' confrontato tutto il resto della catena.

---

### 2.3 U_rendered e U_buffer

* **TERMINE / SIMBOLO**: `U_rendered` | `U_buffer`
* **DEFINIZIONE METROLOGICA**:
  * `U_rendered`: La rappresentazione visiva e tipografica dello stimolo visualizzata all'interno del campo di input dell'interfaccia client prima dell'azione di invio.
  * `U_buffer`: La sequenza di byte o codepoint effettivamente presente nella struttura dati del Document Object Model (DOM) o nel buffer di memoria dell'applicazione client immediatamente prima dell'evento di submit.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *DOM (Document Object Model)*: La struttura ad albero degli oggetti che rappresenta il documento caricato nel browser web.
  * *Evento di Submit*: L'istante di trigger (click su bottone o pressione tasto Invio) che avvia la procedura di serializzazione e trasmissione del testo.
* ***NOTA PRATICA***: `U_buffer` e' il testo come e' memorizzato dentro il browser nel momento esatto in cui premi "Invio". Se incolli un testo con spazi speciali e il browser li cancella prima ancora che tu prema "Invio", `U_buffer` sara' gia' diverso da `U_intended`.

---

### 2.4 U_serialized

* **TERMINE / SIMBOLO**: `U_serialized`
* **DEFINIZIONE METROLOGICA**: La stringa di testo risultante dall'applicazione dei meccanismi di framing, escaping e codifica (es. JSON string escaping `\"`, conversione caratteri di controllo in `\n` o sequenze `\uXXXX`) applicati dal codice client prima del passaggio allo stack di rete.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Escaping*: La trasformazione di caratteri speciali o riservati in sequenze di testo sicure e interpretabili (es. trasformare un a-capo nel testo letterale `\n`).
  * *Framing*: L'inserimento del dato all'interno di una struttura formale di protocollo (es. wrapping dentro un oggetto JSON `{"messages": [{"content": ...}]}`).
* ***NOTA PRATICA***: Prima di spedire un messaggio in rete, il client deve impacchettarlo dentro una struttura (solitamente JSON). `U_serialized` e' il tuo testo con tutti gli accorgimenti tecnici necessari per non rompere il pacchetto di trasmissione.

---

### 2.5 C_req e la sua Quadrupla di Decodifica

```text
+------------------------------------------------------------------------------+
|                     STRATIFICAZIONE DEL PAYLOAD C_req                        |
|                                                                              |
|  [ C_req_byte ] ────> Flusso esadecimale grezzo sul socket TCP/TLS          |
|        │                                                                     |
|        ▼ (Decodifica UTF-8)                                                 |
|  [ C_req_text ] ────> Stringa di testo decodificata                         |
|        │                                                                     |
|        ▼ (Parsing JSON)                                                     |
|  [ C_req_json ] ────> Struttura dati ad albero JSON                         |
|        │                                                                     |
|        ▼ (Estrazione Campo Utente)                                          |
|  [ C_req_unicode ] ─> Sequenza scalare pura dello stimolo estratto           |
+------------------------------------------------------------------------------+
```

* **TERMINE / SIMBOLO**: `C_req` | `C_req_byte` | `C_req_text` | `C_req_json` | `C_req_unicode`
* **DEFINIZIONE METROLOGICA**: Il payload formale di richiesta osservato sul confine di trasporto (Layer V3). Viene analizzato metrologicamente lungo quattro stadi progressivi di estrazione:
  1. `C_req_byte`: Flusso binario grezzo di byte trasmesso sullo stack di rete TCP/TLS.
  2. `C_req_text`: Stringa testuale ottenuta dalla decodifica binaria conforme a UTF-8 di `C_req_byte`.
  3. `C_req_json`: Oggetto strutturato derivato dal parsing sintattico di `C_req_text` (secondo RFC 8259).
  4. `C_req_unicode`: La sequenza pura di Unicode Scalar Values estratta dal campo specifico del messaggio utente (es. `messages[last].content`).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Socket TCP/TLS*: Il canale di comunicazione bidirezionale cifrato aperto tra il client e l'endpoint remoto.
  * *RFC 8259*: Lo standard internazionale che definisce la grammatica formale del formato JSON.
* ***NOTA PRATICA***: Quando sniffi la rete con i DevTools, non vedi subito il testo pulito. Prima vedi i byte (`C_req_byte`), poi il testo del pacchetto HTTP (`C_req_text`), poi il documento JSON (`C_req_json`) e infine il pezzettino esatto che contiene il tuo prompt (`C_req_unicode`). Verificare tutti e 4 i livelli ti garantisce che la rete abbia ricevuto esattamente quello che volevi mandare.

---

### 2.6 S (Context Backend Assemblato)

* **TERMINE / SIMBOLO**: `S` | `Server Context`
* **DEFINIZIONE METROLOGICA**: Struttura composita di contesto backend assemblata dal server a monte del modulo di tokenizzazione al turno `n`. Formalizzata come:
  ```text
  S_n = Render( < Messages, SystemState, ToolsPayload, MultimodalData, History_(1...n-1), C_req_n > )
  ```
  Nei sistemi commerciali e cloud proprietari, `S` e' **costantemente inaccessibile** e non osservabile (`NOT OBSERVED`).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Context Builder*: Il componente software server-side che fonde il messaggio utente con il System Prompt, le memorie persistenti, la cronologia dei messaggi precedenti e le descrizioni dei tools/funzioni.
  * *Inaccessibilita' Strutturale*: Impossibilita' tecnica e fisica di intercettare lo stato di una variabile che risiede esclusivamente nella memoria RAM di un server remoto gestito da terzi.
* ***NOTA PRATICA***: `S` e' il "piattone" finale che il server prepara per il modello prima di convertirlo in numeri. Contiene il tuo messaggio piu' tutto cio' che il fornitore aggiunge di nascosto (istruzioni di sicurezza, data e ora, prompt invisibili). Su ChatGPT o Claude via web, `S` non potrai mai vederlo direttamente.

---

### 2.7 Token_IDs

* **TERMINE / SIMBOLO**: `Token_IDs`
* **DEFINIZIONE METROLOGICA**: Sequenza discreta e ordinata di numeri interi non negativi `T = [t_1, t_2, ..., t_m]` con `t_i in [0, |V|-1]` (dove `|V|` e' la cardinalita' del vocabolario), generata dall'applicazione dell'algoritmo deterministico di tokenizzazione (es. BPE, WordPiece, Unigram) sul contesto testuale `S`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Vocabolario (|V|)*: L'insieme finito di sotto-parole, singoli caratteri o sequenze di byte su cui il modello e' stato pre-addestrato (tipicamente tra 32.000 e 256.000 elementi).
  * *BPE (Byte-Pair Encoding)*: Algoritmo di compressione e segmentazione che unisce iterativamente i caratteri o byte piu' frequenti in token singoli.
* ***NOTA PRATICA***: I modelli LLM non leggono lettere o parole, ma numeri interi. Il tokenizer e' il traduttore che prende il testo e lo spezza in pezzettini numerici (`Token_IDs`). Se una parola viene spezzata in due numeri invece che in uno, il modello la elaborera' in modo completamente diverso.

---

### 2.8 M_raw (Stato Generativo Interno)

* **TERMINE / SIMBOLO**: `M_raw` | `Raw Model Output`
* **DEFINIZIONE METROLOGICA**: Lo stato generativo interno discreto (sequenza grezza di Token ID emessi dal ciclo autoregressivo della rete neurale) campionato dalla distribuzione dei logit all'uscita dei blocchi Transformer, prima dell'applicazione di qualsiasi post-processing, guardrail asincrono o filtro di sicurezza.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Ciclo Autoregressivo*: Il processo iterativo in cui il modello genera un token alla volta, reinserendo il nuovo token nell'input del passo successivo.
  * *Logits*: I vettori di numeri reali non normalizzati emessi dall'ultimo layer lineare del modello, che rappresentano i punteggi di probabilita' non scalati per ciascun token del vocabolario.
* ***NOTA PRATICA***: `M_raw` e' la voce pura e grezza del modello neurale prima che i filtri aziendali, i controlli di sicurezza o i parser del sito web ci mettano le mani sopra. Anche questo stato, sui servizi commerciali, e' invisibile all'utente comune.

---

### 2.9 C_resp e la sua Triade di Decodifica

* **TERMINE / SIMBOLO**: `C_resp` | `C_resp_byte` | `C_resp_stream` | `C_resp_parsed`
* **DEFINIZIONE METROLOGICA**: Lo stream o payload di risposta ricevuto dallo stack di rete del client sul confine di trasporto (Layer V3). Si articola in tre livelli:
  1. `C_resp_byte`: Flusso esadecimale di byte catturato sul socket di ricezione.
  2. `C_resp_stream`: Sequenza di frame applicativi decodificati secondo il protocollo di trasporto (es. chunk HTTP/1.1, eventi SSE `data: {...}`, frame binari o di testo WebSocket RFC 6455).
  3. `C_resp_parsed`: Struttura dati JSON finale estratta dagli eventi di stream contenente il delta o l'aggregato di testo emesso.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *SSE (Server-Sent Events)*: Standard che consente al server di inviare flussi asincroni di eventi testuali unidirezionali su una connessione HTTP persistente.
  * *Chunked Transfer*: Modalita' di trasmissione HTTP in cui i dati vengono spediti come una serie di blocchi non dimensionati a priori.
* ***NOTA PRATICA***: E' la risposta che viaggia nei cavi di rete verso il tuo computer. Prima arriva come byte grezzi (`C_resp_byte`), poi viene ricomposta come flusso di pezzettini di streaming (`C_resp_stream`), e infine viene convertita nell'oggetto JSON finale (`C_resp_parsed`) pronto per essere letto dall'applicazione.

---

### 2.10 O_markdown, O_html, O_dom, O_visual e O (Output Finale Composito)

```text
+------------------------------------------------------------------------------+
|                     STADI DI RENDERING CLIENT POST-RECEIVE                   |
|                                                                              |
|  [ C_resp_parsed ] ────> JSON estratto dalla rete                           |
|        │                                                                     |
|        ▼ (Parsing Markdown/HTML)                                            |
|  [ O_markdown / O_html ] ─> Codice strutturato con tag                       |
|        │                                                                     |
|        ▼ (Costruzione DOM)                                                   |
|  [ O_dom ] ────────────> Nodi di testo nell'albero della pagina            |
|        │                                                                     |
|        ▼ (Rasterizzazione Grafica)                                           |
|  [ O_visual ] ─────────> Pixel disegnati a schermo                         |
|        │                                                                     |
|        ▼                                                                     |
|  [ O ] ────────────────> Output Composito Finale di Riferimento           |
+------------------------------------------------------------------------------+
```

* **TERMINE / SIMBOLO**: `O_markdown` | `O_html` | `O_dom` | `O_visual` | `O`
* **DEFINIZIONE METROLOGICA**: La catena di rappresentazione finale dell'output sul client:
  * `O_markdown / O_html`: Testo intermedio generato dai parser client interpretando i caratteri di marcatura.
  * `O_dom`: Il contenuto testuale effettivo risiedente nel nodo di testo (`textContent` o `innerText`) dell'albero DOM.
  * `O_visual`: La rappresentazione grafica terminale rasterizzata a display (glifi e layout renderizzato).
  * `O`: L'output finale composito estratto ed eletto a riferimento per la valutazione metrologica.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Rasterizzazione*: Il processo di trasformazione dei caratteri tipografici e vettoriali in una griglia discreta di pixel a schermo.
  * *Text Node*: L'oggetto del DOM che contiene esclusivamente stringhe testuali senza ulteriori tag nidificati.
* ***NOTA PRATICA***: Spesso il testo che leggi sullo schermo non e' identico a quello che e' arrivato dalla rete. Se il modello manda due spazi, il browser potrebbe fonderli in uno solo (`O_visual`). Se manda codice HTML, il browser potrebbe nasconderlo o formattarlo (`O_dom`). Il framework CDP distingue minuziosamente tra cio' che e' nel codice della pagina (`O_dom`) e cio' che vedi con gli occhi (`O_visual`).

---

### 2.11 Data Integrity Chain (Serializzazione Canonica UTF-8 e SHA-256)

* **TERMINE / SIMBOLO**: `Data Integrity Chain` | `Serializzazione Canonica UTF-8` | `enc_UTF8()`
* **DEFINIZIONE METROLOGICA**: Metodologia formale di tracciamento e audit crittografico che impone la serializzazione binaria deterministica invariante `enc_UTF8()` prima del calcolo del digest SHA-256:
  ```text
  SHA256( enc_UTF8(U_intended) ) == SHA256( enc_UTF8(U_buffer) ) == SHA256( C_req_byte )
  ```
  Nel caso del livello estratto `C_req_unicode`, il digest SHA-256 viene calcolato esclusivamente previa decodifica e normalizzazione a stringa scalare UTF-8.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Serializzazione Canonica*: Procedura deterministica che converte una struttura dati astratta in una sequenza esatta di byte senza ambiguita' di spaziatura, ordine di chiavi o codifica dei caratteri.
* ***NOTA PRATICA***: E' la catena di custodia digitale. Serve a garantire che nessuno possa dire "il testo e' cambiato" solo perche' un software ha usato una codifica diversa o ha riordinato le virgolette nel JSON. Se gli hash SHA-256 combaciano lungo tutta la catena, il testo non e' stato toccato da nessuno.

---

## SEZIONE 3: I LAYER DI OSSERVABILITÀ (V0 - V5) E CLASSIFICAZIONE V3

```text
+------------------------------------------------------------------------------+
|                    I LAYER DI OSSERVABILITA' STRUMENTALE                     |
|                                                                              |
|  V0 ───> Input Intenzionale Digitato (U_intended)                            |
|  V1 ───> DOM / Buffer Client Pre-Submit (U_buffer)                           |
|  V2 ───> Output Finale a Schermo / Client (O)                                |
|  V3 ───> Traffico di Rete Applicativo (C_req, C_resp)                        |
|  V4 ───> Payload Elaborato dal Server (S Context) [Non accessibile su Cloud] |
|  V5[V]─> Variabili Interne Runtime (TokenIDs, Logits, Weights) [Locale]      |
+------------------------------------------------------------------------------+
```

---

### 3.1 Disambiguazione Notazionale e Layer di Osservabilita' (V0 - V4)

```text
+------------------------------------------------------------------------------+
|             GUIDA ALLA DISAMBIGUAZIONE DELLA NOTAZIONE "L"                   |
|                                                                              |
|  1. LAYER SPERIMENTALI DI CANALE  (L0 - L3) ──> Segmenti fisici del tragitto |
|  2. LAYER DI OSSERVABILITA'       (V0 - V5) ──> Confini con sonde di cattura |
|  3. CLAIM STRENGTH MATRIX         (L0 - L4) ──> Forza logica del verdetto   |
+------------------------------------------------------------------------------+
```

* **TERMINE / SIMBOLO**: `Disambiguazione della Notazione L` | `Layer Sperimentali (L0-L3)` vs `Claim Strength (L0-L4)` vs `Layer di Osservabilita' (V0-V5)`
* **DEFINIZIONE METROLOGICA**: Regola di disambiguazione lessicale necessaria per evitare confusioni tra tre concetti distinti del framework indicati storicamente con lettere simili:
  1. *Layer Sperimentali di Canale (`Layer L0 .. L3`)*: I quattro macro-segmenti dell'architettura client-server (`L0: Pre-Submit`, `L1: Transport`, `L2: Behavioral/Rendering`, `L3: Cross-Session`).
  2. *Layer di Osservabilita' Strumentale (`Layer V0 .. V5`)*: I sei punti di accesso fisico o logico in cui e' possibile collocare strumenti di misura (`V0` input, `V1` DOM buffer, `V2` output visuale, `V3` rete, `V4` context server, `V5` pesi/attivazioni locali).
  3. *Claim Strength Matrix (`Livelli L0 .. L4`)*: I cinque livelli normativi di validita' scientifica dell'asserzione conclusiva.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Disambiguazione Tassonomica*: Separazione formale tra la topologia dell'infrastruttura (dove viaggia il dato), la strumentazione (dove guardiamo) e l'epistemologia (cosa possiamo affermare).
* ***NOTA PRATICA***: Se in un report leggi "Layer L1", fai attenzione al contesto: se si parla del tragitto di rete e' il *Layer Sperimentale L1*; se si parla della forza della conclusione e' il *Livello L1 di Claim* (Relazione Empirica). Per evitare errori, il protocollo raccomanda di usare la lettera `V` per i confini strumentati (`V3` per la rete) e `L` solo per i livelli di claim (`L0-L4`).

---

* **TERMINE / SIMBOLO**: `Layer V0` | `Layer V1` | `Layer V2` | `Layer V3` | `Layer V4`
* **DEFINIZIONE METROLOGICA**: Stratificazione metrologica dei confini strumentali del sistema target:
  * `V0`: Confine dello stimolo generatore/intenzionale (`U_intended`). Sempre accessibile.
  * `V1`: Confine del buffer dell'interfaccia client pre-trasmissione (`U_buffer`). Accessibile via script o ispezione DOM.
  * `V2`: Confine dell'output terminale del client (`O`). Sempre accessibile.
  * `V3`: Confine di trasporto di rete applicativo (`C_req`, `C_resp`). Accessibile tramite DevTools, proxy HTTP o adapter di rete.
  * `V4`: Confine del server-side context builder (`S`). Non accessibile su sistemi cloud chiusi.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Confine Strumentale*: La linea di demarcazione fisica o software in cui e' possibile collocare una sonda di cattura dati senza alterare il funzionamento del sistema.
  * *Accessibilita' Standard*: La disponibilita' operativa del dato per un ricercatore che opera senza privilegi di amministrazione sull'infrastruttura remota.
* ***NOTA PRATICA***: Sono i "punti di controllo" dove puoi piazzare le tue telecamere. V0 e' cosa vuoi scrivere tu; V1 e' cosa c'e' nella casella di testo; V2 e' cosa vedi scritto come risposta; V3 sono i pacchetti che viaggiano su internet; V4 e' la memoria del computer del fornitore remoto (dove non puoi entrare).

---

### 3.2 Layer V5[V] Parametrico e relative Variabili Interne

* **TERMINE / SIMBOLO**: `Layer V5[V]` | `V5[TokenIDs]` | `V5[Logits]` | `V5[AttentionWeights]` | `V5[Weights]` | `V5[Ablation/Patching]`
* **DEFINIZIONE METROLOGICA**: Layer di accesso strumentato alle **variabili interne del modello**, operante esclusivamente su runtime locali o white-box. E' formalmente parametrizzato sul sottoinsieme effettivo di variabili intercettate `V`:
  ```text
  V5[V]   con V sottoinsieme di { TokenIDs, Logits, AttentionWeights, KVCache, HiddenStates, Weights }
  ```
  Le specifiche matematiche per i claim ammissibili impongono:
  * *Logits e Distribuzione Categorica condizionata a T*:
    ```text
    p(z; T)_i = exp( z_i / T ) / ( sum(j=1 to |V|, exp( z_j / T )) )
    H(p | T)  = - sum(i=1 to |V|, p(z; T)_i * log( p(z; T)_i ) )
    ```
  * *Attention Weights*: Matrici a righe stocastiche `A_(l,h) in [0, 1]^(N x N)` post-Softmax, vincolate a modelli dot-product attention standard.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Softmax*: Funzione matematica che converte un vettore di numeri reali arbitrari in una distribuzione di probabilita' (somma pari a 1.0).
  * *Entropia di Shannon H(p | T)*: Misura quantitativa dell'incertezza o della dispersione della distribuzione di probabilita' dei token successivi a una data temperatura.
  * *Activation Patching*: Tecnica di interpretabilita' meccanicistica che sostituisce chirurgicamente le attivazioni interne di un layer per misurarne l'effetto causale sull'output.
* ***NOTA PRATICA***: V5 e' la modalita' "a cuore aperto". E' possibile solo se fai girare il modello sul tuo computer (es. con Ollama, vLLM o PyTorch). In V5 puoi guardare i neuroni, i calcoli matematici e i pesi della rete, potendo finalmente spiegare esattamente il perche' fisico di ogni decisione del modello.

---

### 3.3 Modalita' A (V3 Attivo) vs Modalita' B (Black-Box Pura)

* **TERMINE / SIMBOLO**: `Modalita' A` | `Modalita' B`
* **DEFINIZIONE METROLOGICA**:
  * `Modalita' A (V3 Attivo)`: Configurazione di test in cui il confine di trasporto di rete e' pienamente intercettato, decodificato e verificato (`V3-3`), consentendo l'isolamento causale delle trasformazioni nel tragitto client-to-network (`U -> C_req`).
  * `Modalita' B (Black-Box Pura)`: Configurazione di test in cui sono accessibili esclusivamente lo stimolo di input e l'output terminale (`U -> O`), rendendo strutturalmente impossibile localizzare dove avvengano le mutazioni lungo la catena di canale.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Isolamento Causale*: La capacita' sperimentale di escludere categoricamente l'influenza di un intero segmento di trasmissione (es. il codice del browser) su un fenomeno osservato.
* ***NOTA PRATICA***: In Modalita' A stai usando gli strumenti per sviluppatori (o cURL) e sai esattamente cosa parte e cosa arriva su internet. In Modalita' B stai guardando solo l'interfaccia grafica (come un utente qualunque): se qualcosa si rompe, in Modalita' B non potrai mai sapere se la colpa e' del browser o del server.

---

### 3.4 Tassonomia di Classificazione del Layer V3

```text
+------------------------------------------------------------------------------+
|                   TASSONOMIA DEGLI STATI DI RETE (LAYER V3)                  |
|                                                                              |
|  [ V3-0a ] ──> NO-CAPTURE   : Nessuna sonda attiva / cattura fallita         |
|  [ V3-0b ] ──> NOT-FOUND    : Sonda attiva, ma nessun pacchetto correlato    |
|  [ V3-1  ] ──> TRAFFIC-OBS  : Testo U presente, ma funzione non univoca      |
|  [ V3-2  ] ──> TIME-CORR    : Correlazione temporale pura (senza Request ID) |
|  [ V3-3  ] ──> APPL-VERIF   : Canale Verificato (Correlation ID + Isolamento)|
|  [ V3-X  ] ──> UNDECODABLE  : Payload cifrato / binario non documentato      |
+------------------------------------------------------------------------------+
```

* **TERMINE / SIMBOLO**: `V3-0a` | `V3-0b` | `V3-1` | `V3-2` | `V3-3` | `V3-X`
* **DEFINIZIONE METROLOGICA**: Tassonomia normativa per qualificare lo stato di osservabilita' del canale di rete:
  * `V3-0a [NO-CAPTURE]`: Assenza totale di strumenti di intercettazione di rete attivi.
  * `V3-0b [NOT-FOUND]`: Strumentazione attiva ma nessun frame o richiesta correlabile all'evento di Submit individuata.
  * `V3-1 [Traffico con U Rilevato]`: La sequenza `U` compare nel payload di rete, ma la sua destinazione o funzione applicativa non e' univocamente correlata all'inferenza.
  * `V3-2 [Correlazione Temporale]`: Richiesta associata per vicinanza temporale (`t_submit approx t_req`), priva di correlation ID applicativo esplicito.
  * `V3-3 [Canale Applicativo Verificato]`: Richiesta verificata congiuntamente da correlation/request ID univoco, fingerprinting deterministico del payload e isolamento dell'harness.
  * `V3-X [UNDECODABLE]`: Traffico intercettato ma payload cifrato in modo proprietario, compresso con codec ignoto o non parsabile.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Fingerprinting Deterministico*: Calcolo del digest crittografico SHA-256 sul payload per certificarne l'esatta corrispondenza 1:1 con il dato di input.
* ***NOTA PRATICA***: E' il voto di affidabilita' della tua cattura di rete. Se non hai catturato nulla sei in `V3-0a`. Se hai catturato il pacchetto perfetto, decodificato, con il suo codice identificativo univoco che combacia con la risposta, ottieni la certificazione massima `V3-3`. Senza `V3-3`, non puoi fare affermazioni certe sul trasporto di rete.

---

### 3.5 I 4 Predicati Deterministici di Custodia V3-3

* **TERMINE / SIMBOLO**: `Predicati di Custodia V3-3` | `P_app_request_observed` | `P_fingerprint_match` | `P_response_correlation` | `P_harness_isolation`
* **DEFINIZIONE METROLOGICA**: Condizioni logiche booleane che devono essere **tutte simultaneamente vere** per assegnare la classificazione `V3-3`:
  ```text
  V3-3 <===> ( P_app_request_observed == TRUE  AND
               P_fingerprint_match == TRUE     AND
               P_response_correlation == TRUE  AND
               P_harness_isolation == TRUE )
  ```
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * `P_app_request_observed`: Il payload HTTP/WS della richiesta applicativa e' stato catturato e materializzato su disco.
  * `P_fingerprint_match`: Il digest SHA-256 dello stimolo estratto da `C_req_unicode` e' identico al digest di `U_intended`.
  * `P_response_correlation`: La risposta ricevuta `C_resp` reca il medesimo identificatore univoco (`req_id` o `stream_id`) generato o associato alla richiesta.
  * `P_harness_isolation`: L'ambiente di test garantisce l'assenza di richieste concorrenti generate dallo stesso processo durante l'intervallo del trial.
* ***NOTA PRATICA***: Per poter dire "questo pacchetto di rete e' al 100% quello giusto", il sistema richiede 4 prove schiaccianti: 1) Hai salvato il file; 2) Il testo dentro il file ha l'impronta digitale identica a quello che hai scritto; 3) Il codice identificativo della risposta combacia con quello della domanda; 4) Nessun altro programma stava usando quella connessione in quel momento.

---

### 3.6 Tassonomia a 6 Stati di Rilevamento del Canale (SOP Sez. 3.2)

```text
+--------------------------------------------------------------------------------+
|                 I 6 STATI DI RILEVAMENTO DEL CANALE (SOP v2.3)                 |
|                                                                                |
|  1. PRESENT      ──> Dato/codepoint fisicamente rilevato nel layer             |
|  2. NOT DETECTED ──> Assente nel layer osservato (ma non dimostra inesistenza) |
|  3. NOT OBSERVED ──> Layer strutturalmente inaccessibile alla misura (es. S)   |
|  4. UNDECODABLE  ──> Traffico intercettato ma cifrato/binario proprietario     |
|  5. INVALID      ──> Misura annullata da anomalie esterne documentate          |
|  6. AMBIGUOUS    ──> Richieste concorrenti senza Correlation ID univoco        |
+--------------------------------------------------------------------------------+
```

* **TERMINE / SIMBOLO**: `Tassonomia di Rilevamento del Canale` | `PRESENT` | `NOT DETECTED` | `NOT OBSERVED` | `UNDECODABLE` | `INVALID` | `AMBIGUOUS`
* **DEFINIZIONE METROLOGICA**: Set esaustivo e mutuamente disgiunto dei sei stati metrologici discreti assegnabili a un codepoint, token, struttura o segnale target lungo uno specifico confine di misura:
  * `PRESENT`: L'entita' target e' fisicamente rilevata nello specifico layer strumentato, in conformita' al criterio di confronto `M` dichiarato.
  * `NOT DETECTED`: L'entita' non e' presente nello specifico layer osservato entro la soglia di sensibilita' dello strumento (in virtu' del postulato `not(Obs(X)) /=> not(X)`, non costituisce prova di assenza nei layer successivi).
  * `NOT OBSERVED`: Il layer e' strutturalmente inaccessibile alla misura nella configurazione corrente (es. il Server Context `S` o i tensori `M_raw` su cloud proprietario).
  * `UNDECODABLE`: Traffico intercettato ma payload cifrato in modo proprietario, compresso con codec non documentato o binario non parsabile (Classificazione `V3-X`).
  * `INVALID`: Misurazione compromessa da anomalie ambientali o di stimolo documentate (`INVALID-STIMULUS`, `INVALID-ENVIRONMENT`).
  * `AMBIGUOUS`: Rilevazione di molteplici richieste concorrenti prive di un Correlation ID univoco che consenta l'attribuzione deterministica.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Sensibilita' Strumentale*: Il limite quantitativo minimo al di sotto del quale la sonda di misura non e' in grado di discriminare il segnale dal rumore di fondo.
  * *Stato Disgiunto*: Proprieta' tassonomica per cui a ciascun evento sul confine puo' essere associata una e una sola delle 6 etichette.
* ***NOTA PRATICA***: Nei referti SOTU non si usano mai espressioni vaghe come "forse non e' arrivato" o "sembra scomparso". Ogni elemento viene classificato con una di queste 6 etichette esatte: cosi' chi legge il verbale sa immediatamente se il dato c'era (`PRESENT`), se non e' stato visto (`NOT DETECTED`), se era impossibile vederlo (`NOT OBSERVED`) o se il pacchetto era illeggibile (`UNDECODABLE`).

---

## SEZIONE 4: LO SPAZIO DELLE IPOTESI CONCORRENTI (H1 - H5)

```text
+------------------------------------------------------------------------------------------+
|                LOCALIZZAZIONE TOPOLOGICA DELLE IPOTESI (H1 - H5)                         |
|                                                                                          |
|       (H1)               (H2)               (H3)             (H4)      (H5)              |
|      Client             Server            Tokenizer          Core    Render              |
|  [U] ───> [C_req] ─────────────────> [S] ───────────> [Tokens] ───> [M] ───> [O] |
+------------------------------------------------------------------------------------------+
```

---

### 4.1 Spazio delle Ipotesi H1 - H5

* **TERMINE / SIMBOLO**: `Spazio delle Ipotesi Concorrenti` | `Classi H1 - H5`
* **DEFINIZIONE METROLOGICA**: Partizione esaustiva e mutamente disgiunta di tutte le possibili spiegazioni architetturali responsabili di una mutazione, divergenza o soppressione rilevata tra l'input intenzionale `U` e l'output finale `O`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Partizione Esaustiva*: Insieme di categorie che copre l'intero dominio delle possibilita' fisiche e logiche della catena di trasmissione.
* ***NOTA PRATICA***: Quando qualcosa cambia tra la tua domanda e la risposta del modello, la causa DEVE trovarsi obbligatoriamente in uno di questi 5 posti: 1) Nel tuo browser/client (H1); 2) Nel server prima del modello (H2); 3) Nel modo in cui le parole diventano numeri (H3); 4) Nei calcoli matematici del modello (H4); 5) Nei filtri finali o nella grafica (H5).

---

### 4.2 H1: Trasformazioni Client-Side

* **TERMINE / SIMBOLO**: `H1` | `H1a` | `H1b`
* **DEFINIZIONE METROLOGICA**: Modifiche, sanitizzazioni o alterazioni apportate dal codice o dall'ambiente di esecuzione client prima o durante la trasmissione in rete.
  * `H1a`: Mutazione testuale localizzata nel tragitto `U_intended -> C_req` (direttamente osservabile ed escludibile in Modalita' A tramite Layer V3).
  * `H1b`: Alterazione del buffer DOM dell'interfaccia client (`U_buffer`) durante l'input o prima del submit.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Sanitizzazione Client*: Script JavaScript o funzioni di interfaccia che rimuovono spazi, tag o caratteri speciali prima dell'invio.
* ***NOTA PRATICA***: E' l'ipotesi che la colpa sia del tuo computer o del tuo browser. Ad esempio, se digiti due a-capo e la pagina web ne cancella uno prima ancora di spedire il messaggio in rete, siamo nel caso H1.

---

### 4.3 H2: Trasformazioni Server-Side Pre-Context

* **TERMINE / SIMBOLO**: `H2` | `H2a` | `H2b`
* **DEFINIZIONE METROLOGICA**: Modifiche strutturali o testuali introdotte dall'infrastruttura di rete o di backend del fornitore a monte della costruzione del contesto `S`.
  * `H2a`: Sanitizzazione o filtraggio applicato da API Gateway, Web Application Firewall (WAF), load balancer o proxy intermedi.
  * `H2b`: Formattazione, iniezione di template di chat, wrapper o System Prompt occulti da parte del context builder backend.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *WAF (Web Application Firewall)*: Sistema di sicurezza di rete che analizza il traffico HTTP per bloccare attacchi o stringhe ritenute pericolose prima che raggiungano l'applicazione.
  * *Chat Template*: Schema di formattazione che avvolge i messaggi dell'utente con tag speciali (es. `<|im_start|>user\n...<|im_end|>`).
* ***NOTA PRATICA***: E' l'ipotesi che il server del provider abbia alterato il testo prima ancora di farlo vedere alla rete neurale. Puo' essere un firewall che cancella caratteri sospetti (H2a) oppure il sistema che appiccica istruzioni segrete attorno alla tua domanda (H2b).

---

### 4.4 H3: Condizionamento da Tokenizzazione e Discretizzazione

* **TERMINE / SIMBOLO**: `H3`
* **DEFINIZIONE METROLOGICA**: Alterazione fenomenologica determinata dalla funzione di discretizzazione del vocabolario `T = tokenize(U)`. Include la frammentazione anomala di sequenze di byte, il collasso di caratteri fuori vocabolario (OOV), l'ambiguita' dei confini di sotto-parola (subword split) o discrepanze tra tokenizer dichiarati e tokenizer di esecuzione. L'attribuzione causale ad `H3` e' considerata formalmente valida solo se verificata tramite interventi controllati sui confini di partizione (`T_split`).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Subword Split*: La modalita' specifica con cui una stringa viene frazionata in blocchi (es. la stringa "invisibile" che puo' diventare `["in", "visibile"]` oppure `["inv", "is", "ibile"]`).
  * *OOV (Out-Of-Vocabulary)*: Caratteri o sequenze non presenti nella tabella di tokenizzazione che vengono mappati su un token generico di fallback (es. `<unk>`) o convertiti in singoli byte esadecimali.
* ***NOTA PRATICA***: E' l'ipotesi che il modello sbagli perche' la parola e' stata spezzettata male in numeri. Se inserisci un carattere raro, il tokenizer potrebbe spezzarlo in 4 frammenti senza senso, rendendo impossibile per il modello capire la parola originale.

---

### 4.5 H4: Dinamica Computazionale del Modello

* **TERMINE / SIMBOLO**: `H4`
* **DEFINIZIONE METROLOGICA**: Elaborazione del segnale all'interno dei tensori e dei blocchi di attenzione del modello neurale (`M_raw = LLM_Core(Token_IDs)`). Include la convergenza su prior semantici dominanti, fenomeni di distrazione attentiva nel contesto lungo, interferenze nei layer di feed-forward o bias indotti dal campionamento stocastico. Rimane non identificabile direttamente in assenza di strumentazione `Layer V5`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Prior Semantico*: La tendenza intrinseca della rete neurale, consolidata durante il pre-training, a privilegiare parole frequenti o completamenti naturali rispetto a sequenze casuali o non convenzionali.
  * *Distrazione Attentiva*: Il decadimento della precisione con cui i meccanismi di Self-Attention focalizzano l'informazione corretta all'aumentare della distanza o del rumore nel prompt.
* ***NOTA PRATICA***: E' l'ipotesi che il modello vero e proprio (la rete neurale) abbia "pensato e risposto" in quel modo. Non ci sono filtri o errori di rete: semplicemente i pesi matematici del modello hanno preferito emettere una parola diversa perche' la consideravano statisticamente piu' probabile.

---

### 4.6 H5: Trasformazioni Post-Generazione e Rendering

* **TERMINE / SIMBOLO**: `H5` | `H5a` | `H5b`
* **DEFINIZIONE METROLOGICA**: Alterazioni dello stimolo successive alla generazione dello stato grezzo `M_raw`.
  * `H5a`: Intercettazione, censura o troncamento dello stream di risposta da parte di safety guardrails asincroni a valle del modello neurale.
  * `H5b`: Sanitizzazione distruttiva, soppressione di tag o trasformazioni di formattazione operate dai motori di rendering Markdown/HTML o dall'albero DOM del client.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Safety Guardrail Asincrono*: Modulo di sicurezza indipendente che analizza i token in uscita in tempo reale e tronca la connessione se rileva contenuti non conformi.
  * *DOM Sanitizer*: Funzione del browser che rimuove tag pericolosi (come `<script>` o `<iframe>`) o caratteri non stampabili prima di mostrarli all'utente.
* ***NOTA PRATICA***: E' l'ipotesi che il modello avesse generato la risposta corretta, ma qualcosa l'ha cancellata o rovinata subito dopo. Puo' essere un censore aziendale che stacca la spina mentre il modello parla (H5a) o il tuo browser che cancella del codice HTML credendolo pericoloso (H5b).

---

## SEZIONE 5: TASSONOMIA DEI CRITERI DI CONFRONTO DELL'OUTPUT (CLASSE M)

```text
+------------------------------------------------------------------------------+
|                     CRITERI DI CONFRONTO DELL'OUTPUT (CLASSE M)              |
|                                                                              |
|  [ M1  ] ──> Exact Identity        : Uguaglianza 1:1 (Byte / Scalari)        |
|  [ M2a ] ──> Normalization-Eq.     : Forme Canoniche UAX #15 (NFC, NFD, ecc.)|
|  [ M2b ] ──> Segmentation-Eq.      : Cluster di Grafemi UAX #29 (EGC)        |
|  [ M3  ] ──> Deterministic Render  : Identita' di Pixel vincolata (Phi)      |
|  [ M4  ] ──> Distance & Metric     : Funzioni di costo (Levenshtein, ecc.)   |
|  [ M5  ] ──> Semantic Concordance  : NLI bidirezionale / Valutazione Cieca   |
+------------------------------------------------------------------------------+
```

---

### 5.1 Panoramica Criteri di Confronto Classe M

* **TERMINE / SIMBOLO**: `Classe M` | `Criteri di Confronto dell'Output`
* **DEFINIZIONE METROLOGICA**: Tassonomia formale e rigorosa dei predicati matematici e delle procedure empiriche ammesse per determinare se l'output `O` sia conforme, equivalente o divergente rispetto all'input `U`. E' fatto esplicito divieto di utilizzare il termine generico "uguale" o "equivalente" senza dichiarare l'istanza specifica della classe `M` utilizzata.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Relazione di Equivalenza*: Relazione binaria matematica che soddisfa contemporaneamente le proprieta' di riflessivita' (`a ~ a`), simmetria (`a ~ b ==> b ~ a`) e transitivita' (`a ~ b AND b ~ c ==> a ~ c`).
* ***NOTA PRATICA***: Nel linguaggio comune diciamo "queste due frasi sono uguali". In metrologia questo non ha senso: sono uguali nei byte? Sono uguali nel significato? Sono uguali come pixel a schermo? La Classe M ti costringe a dichiarare esattamente che tipo di lente di ingrandimento stai usando per confrontare i testi.

---

### 5.2 M1: Exact Identity (M1-byte e M1-scalar)

* **TERMINE / SIMBOLO**: `M1` | `M1-byte (I_byte)` | `M1-scalar (I_scalar)`
* **DEFINIZIONE METROLOGICA**:
  * `M1-byte (I_byte)`: Predicato di uguaglianza esatta 1:1 della sequenza binaria di byte UTF-8:
    ```text
    I_byte(x, y) <===> Bytes(x) == Bytes(y)
    ```
  * `M1-scalar (I_scalar)`: Predicato di uguaglianza esatta 1:1 della sequenza di Unicode Scalar Values:
    ```text
    I_scalar(x, y) <===> Scalars(x) == Scalars(y)
    ```
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Identita' Scalare vs Binaria*: Due stringhe possono essere identiche nei codepoint scalari ma differire nei byte se codificate con standard differenti (es. UTF-8 vs UTF-16).
* ***NOTA PRATICA***: E' il criterio piu' severo e rigido possibile. `M1-byte` richiede che ogni singolo zero e uno del file sia identico al 100%. Se cambia anche solo un byte invisibile, il test fallisce.

---

### 5.3 M2a: Normalization-Based Equivalence (Unicode UAX #15)

* **TERMINE / SIMBOLO**: `M2a` | `E_NFC` | `E_NFD` | `E_NFKC` | `E_NFKD`
* **DEFINIZIONE METROLOGICA**: Relazione di equivalenza formale per partizione basata sullo standard Unicode Annex #15:
  ```text
  x ~_Norm y <===> Norm(x) == Norm(y)   con Norm in { NFC, NFD, NFKC, NFKD }
  ```
  * `NFC`: Normalizzazione Canonica per Composizione (precompone i caratteri con accenti).
  * `NFD`: Normalizzazione Canonica per Decomposizione (separa i caratteri base dagli accenti combinatori).
  * `NFKC / NFKD`: Normalizzazioni di Compatibilita' (collassano legature tipografiche come "fi" in caratteri distinti "f"+"i" ed esponenti in numeri standard).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Equivalenza Canonica*: Proprieta' di due sequenze di codepoint che rappresentano esattamente lo stesso concetto tipografico e devono essere visualizzate in modo identico.
  * *Equivalenza di Compatibilita'*: Proprieta' di sequenze che rappresentano lo stesso testo semantico ma con distinzioni di formattazione grafica o funzionale originaria.
* ***NOTA PRATICA***: La lettera "e" con l'accento acuto puo' essere scritta al computer in due modi: con un solo carattere ("e' precomposta") o con due caratteri ("e" normale seguita dal segno dell'accento). Per un essere umano sono identiche; per il computer (in M1) sono diverse. Il criterio M2a riconosce che sono la stessa identica cosa sotto le regole Unicode.

---

### 5.4 M2b: Segmentation Sequence Equivalence (Unicode UAX #29)

* **TERMINE / SIMBOLO**: `M2b` | `E_EGC` | `UNAVAILABLE_IN_STDLIB_MODE`
* **DEFINIZIONE METROLOGICA**: Relazione di equivalenza deterministica definita sull'identita' della tupla ordinata dei segmenti di testo calcolati applicando l'algoritmo di partizione Extended Grapheme Clusters (UAX #29):
  ```text
  x ~_EGC y <===> Seg_UAX29(x) == Seg_UAX29(y)
  ```
  Nel software di laboratorio operante in modalita' standard library pura (senza pacchetti terzi C/Rust compilati), questo criterio e' formalmente registrato come `UNAVAILABLE_IN_STDLIB_MODE`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Extended Grapheme Cluster (EGC)*: La sequenza minima di codepoint Unicode che compone una singola unita' grafica percepita dall'utente umano.
  * *Standard Library Mode*: Esecuzione di codice che utilizza esclusivamente le librerie di base native del linguaggio Python, garantendo portabilita' assoluta su Termux/Android.
* ***NOTA PRATICA***: Un'emoji complessa (es. un pompiere donna con la pelle scura) puo' essere formata da 4 o 5 caratteri Unicode fusi insieme da ponti invisibili. Il criterio M2b verifica se il testo e' spezzato negli stessi "grafemi visivi" visti dall'utente. Se lo script non ha tabelle speciali installate, dichiara onestamente di non poter calcolare questo criterio.

---

### 5.5 M3: Deterministic Rendering Criteria (RasterDiff | Phi)

* **TERMINE / SIMBOLO**: `M3` | `R_render | Phi` | `RasterDiff`
* **DEFINIZIONE METROLOGICA**: Predicato di identita' grafica raster condizionato al congelamento esplicito del vettore di configurazione ambientale `Phi`:
  ```text
  Phi = < Engine, OS, Rasterizer, Font_Family, Font_Size, Antialiasing, DPR, Viewport >
  R_render(O_1, O_2 | Phi) <===> RasterDiff( O_1, O_2 | Phi ) == 0
  ```
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *RasterDiff*: Funzione matematica che calcola la distanza assoluta (es. scarto quadratico medio o differenza pixel a pixel) tra due matrici bidimensionali di pixel renderizzati.
  * *DPR (Device Pixel Ratio)*: Il rapporto tra pixel fisici del display e pixel logici della risoluzione CSS.
* ***NOTA PRATICA***: M3 confronta l'immagine reale stampata a schermo. Ti dice se due testi generano una schermata pixel per pixel assolutamente identica. E' valido solo se specifichi su che computer, con quale font, risoluzione e scheda video hai fatto la foto allo schermo.

---

### 5.6 M4: Distance & Metric Functions

* **TERMINE / SIMBOLO**: `M4` | `Distanza di Levenshtein` | `Token Overlap`
* **DEFINIZIONE METROLOGICA**: Funzioni quantitative pseudometriche non binarie che restituiscono un valore scalare continuo `d in [0, +infinito)` rappresentante il costo di trasformazione o la divergenza statistica tra due sequenze di testo o variabili di latenza.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Distanza di Levenshtein*: Il numero minimo di operazioni elementari (inserimento, cancellazione, sostituzione di un carattere) necessarie per trasformare la stringa `A` nella stringa `B`.
  * *Pseudometrica*: Funzione di distanza che soddisfa le proprieta' di non-negativita', simmetria e disuguaglianza triangolare, ma in cui due elementi distinti possono avere distanza zero.
* ***NOTA PRATICA***: Invece di dire solo "SI/NO", i criteri M4 ti dicono quanto due testi sono diversi (es. "questo testo differisce solo per 2 lettere dal testo originale" oppure "i due testi condividono l'85% delle parole").

---

### 5.7 M5: Semantic Concordance Protocol (P_sem)

* **TERMINE / SIMBOLO**: `M5` | `P_sem` | `Entailment NLI` | `Kappa di Cohen`
* **DEFINIZIONE METROLOGICA**: Protocollo convenzionale empirico di concordanza semantica specificato dalla tupla:
  ```text
  P_sem = < Valutatore, Metrica, Soglia_tau >
  ```
  * *Istanza Automatica (NLI)*: Modello di Natural Language Inference con soglia di implicazione bidirezionale:
    ```text
    P(Entail(O, U)) >= tau_NLI  AND  P(Entail(U, O)) >= tau_NLI
    ```
  * *Istanza Umana (Blind Rubric)*: Protocollo a doppio cieco standardizzato con calcolo formale dell'accordo inter-osservatore (`kappa >= 0.85`).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *NLI (Natural Language Inference)*: Ramo del machine learning in cui un modello determina se una frase implica logicamente, contraddice o e' neutra rispetto a un'altra.
  * *Kappa di Cohen*: Coefficiente statistico che misura il grado di accordo tra due giudici umani al netto dell'accordo puramente casuale.
* ***NOTA PRATICA***: E' il criterio che valuta se due frasi dicono la stessa cosa, anche se usano parole del tutto differenti. Richiede o un secondo modello di intelligenza artificiale calibrato o due valutatori umani indipendenti.

---

## SEZIONE 6: IL VETTORE DI EVIDENZA `E = < O_x, C_x, R_x, S_x >`

```text
+================================================================================+
|                       IL VETTORE DI EVIDENZA ESTESO                            |
|                                                                                |
|               E  =  <  O_x  ,   C_x  ,   R_x  ,   S_x  >                       |
|                         │        │        │        │                          |
|      ┌───────────────┘        │        │        └───────────────┐      |
|      ▼                           ▼        ▼                           ▼     |
|  [ ASSE O ]                  [ ASSE C ] [ ASSE R ]                [ ASSE S ]   |
|  Observability               Causality  Replication               Scope        |
|  O0: Nessun confine          C0: Assoc. R0: N=1                   S0: Solo U   |
|  O1: Solo output U->O        C1: OFAT   R1: Pilota [5,10]         S1: U->O     |
|  O2: Ispezione DOM           C2: Interv.R2: Parametrico CI        S2: U->DOM   |
|  O3: Rete (U->C_req)         C3: DAG    R3: Multi-System Vendor   S3: U->C_req |
|  O4: Server Log Gateway      C4: Meccan.                          S4: Rete     |
|  O5: Variabili V5                                                 S5: C_req->O |
|                                                                   S6: End-End  |
+================================================================================+
```

---

### 6.1 Vettore di Evidenza E

* **TERMINE / SIMBOLO**: `Vettore di Evidenza E` | `E = < O_x, C_x, R_x, S_x >`
* **DEFINIZIONE METROLOGICA**: Tupla formale a quattro coordinate ortogonali e indipendenti che qualifica in modo univoco, trasparente e standardizzato la postura epistemica, la robustezza statistica e l'estensione topologica di qualsiasi risultato sperimentale nel framework CDP v2.3.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Coordinate Ortogonali*: Dimensioni di valutazione indipendenti (il miglioramento su un asse non compensa la mancanza di osservabilita' su un altro asse).
* ***NOTA PRATICA***: E' il "passaporto scientifico" di ogni test. Quando leggi una stringa come `E = < O3, C1, R1, S3 >`, capisci all'istante: dove hai guardato (O3: pacchetti di rete), come hai isolato le variabili (C1: test controllato passo-passo), quante volte hai ripetuto la prova (R1: 5 prove pilota) e su quale pezzo di strada hai fatto la misura (S3: dal browser alla rete).

---

### 6.2 Asse O (Observability Boundary: O0 - O5)

* **TERMINE / SIMBOLO**: `Asse O` | `O0` | `O1` | `O2` | `O3` | `O4` | `O5`
* **DEFINIZIONE METROLOGICA**: Dimensione vettoriale che specifica il confine fisico o logico massimo direttamente strumentato durante l'esperimento:
  * `O0`: Nessun confine strumentato (valutazione aneddotica).
  * `O1`: Strumentazione limitata all'output finale `U -> O` (Black-box terminale).
  * `O2`: Ispezione del DOM e dei buffer client (`U_buffer`, `O_dom`).
  * `O3`: Ispezione dello stack di trasporto di rete client/server (`C_req`, `C_resp`).
  * `O4`: Accesso a log verificabili di API Gateway o middleware server-side.
  * `O5`: Accesso diretto alle variabili interne del modello (`V5[V]`) su runtime locale.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Risoluzione Strumentale*: La profondita' analitica con cui il ricercatore puo' osservare gli stati intermedi del canale.
* ***NOTA PRATICA***: Indica fin dove sono arrivate le tue sonde. O1 significa che eri seduto davanti allo schermo; O3 significa che stavi registrando il traffico di rete; O5 significa che avevi il controllo totale della memoria RAM e della scheda video dove gira il modello.

---

### 6.3 Asse C (Scala di Evidenza Causale CDP: C0 - C4)

* **TERMINE / SIMBOLO**: `Asse C` | `C_CDP` | `C0` | `C1` | `C2` | `C3` | `C4`
* **DEFINIZIONE METROLOGICA**: Tassonomia proprietaria per la classificazione del livello di inferenza causale raggiunto dalla procedura di test:
  * `C0 [Associazione Osservazionale Pura]`: Correlazione statistica passiva `P(O | U)` priva di controllo dei confondenti.
  * `C1 [Contrasto Differenziale Comparativo]`: Isolamento dei fattori tramite variazioni controllate One-Factor-At-A-Time (OFAT).
  * `C2 [Intervento Sperimentale Diretto]`: Manipolazione attiva `P(O | do(X=x))` su parametri esposti del SUT (es. temperatura, flag) a parita' di ambiente.
  * `C3 [Identificazione Causale Strutturale]`: Effetto isolato sotto un Grafo Causale Diretto Acomplesso (DAG) che soddisfa formali criteri di backdoor o frontdoor adjustment.
  * `C4 [Validazione Meccanicistica Locale]`: Evidenza empirica causale derivata dalla manipolazione diretta di pesi, token o attivazioni interne.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Confondente*: Una variabile non controllata o nascosta che influenza contemporaneamente la causa ipotizzata e l'effetto osservato, creando una falsa associazione.
  * *DAG (Directed Acyclic Graph)*: Modello grafico matematico a nodi e frecce orientate prive di cicli che formalizza le relazioni causa-effetto tra variabili.
* ***NOTA PRATICA***: Misura quanto sei sicuro di aver trovato la vera causa di un comportamento. C0 e' una semplice coincidenza; C1 e' un test in cui hai cambiato una sola lettera alla volta per vedere cosa succedeva; C4 e' la prova scientifica ottenuta modificando direttamente un neurone del modello.

---

### 6.4 Asse R (Replication Scope: R0 - R3)

* **TERMINE / SIMBOLO**: `Asse R` | `R0` | `R1` | `R2` | `R3`
* **DEFINIZIONE METROLOGICA**: Dimensione vettoriale che esprime l'estensione, la potenza campionaria e l'eterogeneita' del protocollo di replicazione:
  * `R0`: Singola osservazione non replicata (`N = 1`).
  * `R1 [Studio Pilota a Bassa Precisione]`: Dimensione campionaria `N in [5, 10]`. Per `N = 5, k = 5`, l'intervallo esatto di Clopper-Pearson al 95% e' `[0.478, 1.000]`.
  * `R2 [Stima Parametrica Vincolata]`: Dimensione campionaria dimensionata a priori sul semintervallo del margine di errore (es. `MOE <= 0.05` con potenza `1 - beta >= 0.80`).
  * `R3 [Replicazione Multi-Ambiente Cross-System]`: Protocollo replicato su molteplici vendor, runtime e sistemi operativi differenti.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Potenza Statistica (1 - beta)*: La probabilita' che un test statistico rilevi correttamente un effetto reale quando questo esiste.
  * *MOE (Margin of Error)*: Il semintervallo dell'intervallo di confidenza calcolato attorno alla stima campionaria.
* ***NOTA PRATICA***: Indica quanto e' solida la tua statistica. R0 e' un aneddoto visto una sola volta; R1 e' un test pilota veloce su 5 prove; R2 e' uno studio statistico calcolato con decine di prove per avere la certezza matematica; R3 e' un test confermato su diversi computer e sistemi operativi.

---

### 6.5 Asse S (Evidence Scope: S0 - S6)

* **TERMINE / SIMBOLO**: `Asse S` | `S0` | `S1` | `S2` | `S3` | `S4` | `S5` | `S6`
* **DEFINIZIONE METROLOGICA**: Dimensione vettoriale che delimita il perimetro topologico esatto del canale coperto dal claim:
  * `S0`: Circoscritto esclusivamente allo stimolo di input `U`.
  * `S1`: Relazione comportamentale diretta terminale `U -> O`.
  * `S2`: Segmento di interfaccia client `U -> O_dom`.
  * `S3`: Confine di trasporto client/rete `U -> C_req`.
  * `S4`: Confine di trasporto bidirezionale di rete `C_req -> C_resp`.
  * `S5`: Tragitto dalla rete all'output finale `C_req -> O`.
  * `S6`: Catena composita end-to-end interamente osservata su tutti i segmenti (applicabile solo con Layer O5 attivo).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Perimetro Topologico*: La porzione esatta dell'architettura client-server compresa tra la variabile di partenza e la variabile di arrivo della misurazione.
* ***NOTA PRATICA***: Ti dice su quale "tratto di strada" si applica la tua conclusione. S3 significa che stai parlando solo del viaggio dal tuo browser fino al router di casa; S5 riguarda il viaggio dal server di arrivo fino al tuo schermo; S6 copre l'intera autostrada dall'inizio alla fine.

---

## SEZIONE 7: MENSURANDI, METROLOGIA STATISTICA E INCERTEZZA

***NOTA PRATICA***: *Mensurandi* (sing. Mensurando), significa semplicemente:
*L'elenco preciso delle grandezze e dei parametri che abbiamo deciso di quantificare con un numero e con un margine di errore*

```text
+-------------------------------------------------------------------------------+
|                     CATENA METROLOGICA A 4 STADI (O->M->B->H)                 |
|                                                                               |
|  [ O_raw ]        ──> Dato grezzo non interpretato (byte, timestamp, status)  |
|       │                                                                       |
|       ▼                                                                      |
|  [ M_measured ]   ──> Grandezza quantitativa e incertezza (ORR_b, CI 95%)     |
|       │                                                                       |
|       ▼                                                                      |
|  [ B_behavioral ] ──> Inferenza stimolo-risposta sotto criterio M (SUPPORTED) |
|       │                                                                       |
|       ▼                                                                      |
|  [ H_mechanistic ]──> Modello architetturale interno (UNDERDETERMINED)        |
+-------------------------------------------------------------------------------+
```

---

### 7.1 Catena Metrologica a 4 Stadi (O -> M -> B -> H)

* **TERMINE / SIMBOLO**: `Catena Metrologica Operativa` | `O_raw` | `M_measured` | `B_behavioral` | `H_mechanistic`
* **DEFINIZIONE METROLOGICA**: Procedura standardizzata per la trasformazione progressiva dei dati di laboratorio in conclusioni scientifiche:
  1. `O_raw`: Acquisizione del dato primario non interpretato dallo strumento di misura (byte UTF-8, timestamp unix in millisecondi, codici frame WebSocket).
  2. `M_measured`: Applicazione dell'algoritmo di misura quantitativo, calcolo dello stimatore puntuale e della relativa incertezza statistica (CI al 95%).
  3. `B_behavioral`: Formulazione dell'inferenza empirica stimolo-risposta limitata alla relazione `U -> O` sotto il criterio `M` dichiarato.
  4. `H_mechanistic`: Valutazione delle ipotesi sui componenti interni (`H1 - H5`), mantenute rigorosamente separate dal comportamento:
     ```text
     H_mechanistic != B_behavioral
     ```
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Mensurando*: La grandezza fisica o logica specifica sottoposta a misurazione.
  * *Incertezza di Misura*: Parametro non negativo che caratterizza la dispersione dei valori ragionevolmente attribuibili al mensurando.
* ***NOTA PRATICA***: E' il metodo in 4 passi per non prendere abbagli: 1) Registra i numeri crudi (O); 2) Calcola le medie e gli intervalli di errore (M); 3) Descrivi come ha risposto il sistema (B); 4) Valuta se e quali ipotesi sul motore interno sono rimaste in piedi (H).

---

### 7.2 Observed Replication Rate (ORR_b) e Gestione Run Invalidi

* **TERMINE / SIMBOLO**: `ORR_b` | `N_valid` | `INVALID-STIMULUS` | `INVALID-ENVIRONMENT` | `INVALID_FOR_EXACT_TRANSPORT`
* **DEFINIZIONE METROLOGICA**: Indice di conformita' empirica calcolato esclusivamente sui trial formalmente validi:
  ```text
  ORR_b = k / N_valid      con N_valid = N_attempts - N_invalid
  ```
  La policy di gestione delle anomalie distingue categoricamente:
  * `INVALID-STIMULUS`: Disallineamento accertato tra `U_intended` e `U_buffer` prima del submit (trial totalmente nullo).
  * `INVALID-ENVIRONMENT`: Caduta di connettivita', crash del browser o riavvio del nodo remoto (trial totalmente nullo).
  * `INVALID_FOR_EXACT_TRANSPORT`: Sonda di rete V3 non attiva o cattura fallita ma risposta terminale `O` presente (declassamento a Modalita' B, valido solo per claim comportamentale `S1: U -> O`).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * `k`: Numero di prove in cui la risposta ha soddisfatto il criterio di confronto `M` nominale.
  * `N_valid`: Numero totale di tentativi depurato da tutti i trial invalidati da fattori esterni al SUT.
* ***NOTA PRATICA***: E' la percentuale di successo delle prove. Se fai 10 prove, ma in 2 salta la connessione internet di casa, non hai avuto un tasso di successo dell'80%: quelle 2 prove non esistono, e il tuo tasso e' calcolato su 8 prove valide. Se il browser ha mandato una stringa sbagliata, la prova e' invalidata e non conta come errore del modello.

---

### 7.3 Intervallo di Confidenza Esatto di Clopper-Pearson al 95%

```text
+--------------------------------------------------------------------------------+
|             INTERVALLO DI CLOPPER-PEARSON AL 95% (PILOTA N=5, k=5)             |
|                                                                                |
|  Stima Puntuale (ORR_b = 1.0) : [========================================] 1.0 |
|  Intervallo Reale al 95%      :                   [----------------------]     |
|                                 0.0               0.478                  1.0   |
|                                                                                |
|  * NOTA: Non esclude un tasso di errore reale della popolazione fino al 52.2%  |
+--------------------------------------------------------------------------------+
```

* **TERMINE / SIMBOLO**: `CI_95%(ORR_b)` | `Clopper-Pearson Exact CI` | `Distribuzione Beta`
* **DEFINIZIONE METROLOGICA**: Metodo non parametrico esatto per determinare l'intervallo di confidenza di una proporzione binomiale, basato sull'inversione della distribuzione cumulativa Beta incompleta regolarizzata `I_x(a, b)`:
  * Per `k = 0`: `L = 0`, `U = 1 - (alpha / 2)^(1 / N)`
  * Per `k = N`: `L = (alpha / 2)^(1 / N)`, `U = 1`
  * Per `0 < k < N`: `L` e' la radice `x` di `I_x(k, N - k + 1) == alpha / 2`, `U` e' la radice `x` di `I_x(k + 1, N - k) == 1 - (alpha / 2)`.
  Per un campione pilota con `k = 5` successi su `N = 5` prove (`alpha = 0.05`):
  ```text
  CI_95%(ORR_b) = [0.478, 1.000]
  ```
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Distribuzione Beta Incompleta*: Funzione speciale della teoria delle probabilita' utilizzata per calcolare le probabilita' esatte di variabili casuali binomiali.
  * *Livello di Confidenza (1 - alpha)*: La probabilita' a lungo termine che l'intervallo calcolato contenga il vero valore del parametro della popolazione (standard fissato a 0.95, con `alpha = 0.05`).
* ***NOTA PRATICA***: Se fai 5 test su 5 e tutti hanno successo, l'intuito ti direbbe che il sistema funziona al 100%. La matematica metrologica di Clopper-Pearson ti ricorda che, avendo fatto solo 5 prove, c'e' una confidenza del 95% che il sistema nella realta' possa avere un tasso di successo che scende fino al 47.8% (e quindi fallire piu' di una volta su due). Serve a evitare facili entusiasmi con campioni piccoli.

---

### 7.4 Analisi Appaiata delle Differenze di Latenza (TTFT Profiling)

* **TERMINE / SIMBOLO**: `TTFT_observed_e2e` | `D_i` | `bar_D` | `s_D` | `CI_95%(bar_D)` | `Paired Bootstrap`
* **DEFINIZIONE METROLOGICA**: Procedura metrologica per quantificare la variazione temporale del Time-To-First-Token tra due condizioni sperimentali (A vs B) tramite un disegno a blocchi appaiati (ABAB / BABA):
  * Mensurando differenziale:
    ```text
    D_i = TTFT_(B, i) - TTFT_(A, i)
    bar_D = (1 / N) * sum(i=1 to N, D_i)
    s_D = sqrt( (1 / (N - 1)) * sum(i=1 to N, (D_i - bar_D)^2) )
    ```
  * Intervallo di Confidenza Primario (t-Student a `N-1` gradi di liberta'):
    ```text
    CI_95%(bar_D) = [ bar_D - t_crit * (s_D / sqrt(N)), bar_D + t_crit * (s_D / sqrt(N)) ]
    ```
  * Analisi Secondaria di Robustezza: Paired Bootstrap non parametrico a 10.000 repliche.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Time-To-First-Token (TTFT)*: Il tempo intercorso in millisecondi tra l'invio dell'ultimo byte della richiesta sul socket e la ricezione del primo byte del primo chunk di risposta.
  * *Disegno Appaiato (Paired Design)*: Tecnica sperimentale che somministra la condizione A e la condizione B a coppie ravvicinate nel tempo per annullare gli effetti del traffico di rete e del carico server.
  * *Bootstrap Non Parametrico*: Metodo di ricampionamento computazionale con reimmissione per stimare l'intervallo di confidenza senza assumere una distribuzione Gaussiana.
* ***NOTA PRATICA***: Quando misuri se un prompt e' piu' lento di un altro, non puoi confrontare un test fatto alle 10:00 del mattino con uno fatto alle 15:00 del pomeriggio. Devi alternare i prompt a coppie (A, B, A, B...) a pochi secondi di distanza. `bar_D` e' la differenza media di tempo tra le coppie, e l'intervallo ti dice se quella differenza e' reale o solo rumore casuale di rete.

---

### 7.5 Minima Differenza Rilevante (MDE / Delta_min) e Rilevanza Pratica

* **TERMINE / SIMBOLO**: `MDE` | `Delta_min` | `Rilevanza Ingegneristica vs Significativita' Statistica`
* **DEFINIZIONE METROLOGICA**: Soglia quantitativa minima stabilita *a priori* nel disegno preregistrato al di sotto della quale una variazione misurata, pur risultando statisticamente significativa (`0 not in CI_95%(bar_D)`), e' dichiarata priva di rilevanza ingegneristica o applicativa. La condizione di rilevanza pratica e' formalmente definita:
  ```text
  is_practically_relevant <===> ( 0 not in CI_95%(bar_D) ) AND ( abs(bar_D) >= Delta_min )
  ```
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Significativita' Statistica*: Evidenza che una differenza osservata non e' attribuibile al semplice caso (l'intervallo esclude lo zero).
  * *Rilevanza Ingegneristica (MDE)*: L'entita' minima dell'effetto affinche' esso comporti un impatto misurabile o un'alterazione tangibile nell'architettura del sistema (es. una differenza di latenza di 2 millisecondi su un canale con 50 ms di jitter e' insignificante).
* ***NOTA PRATICA***: Se fai 100.000 test, potresti scoprire che un carattere speciale fa rallentare il server di 0.0001 millisecondi in modo statisticamente innegabile. Ma l'MDE stabilisce prima dell'esperimento la soglia minima di interesse (es. "ci interessa solo se la differenza supera i 100 millisecondi"). Se non supera la soglia, il fenomeno e' un rumore trascurabile.

---

### 7.6 Power Analysis A Priori per Regime R2 (N_calc)

* **TERMINE / SIMBOLO**: `Power Analysis A Priori` | `N_calc`
* **DEFINIZIONE METROLOGICA**: Determinazione rigorosa della dimensione campionaria minima `N_calc` necessaria per raggiungere una probabilita' predefinita di respingere l'ipotesi nulla (`Potenza = 1 - beta >= 0.80`) a un livello di significativita' `alpha = 0.05`, in funzione della minima differenza rilevante `Delta_min` e della deviazione standard stimata nello studio pilota `s_(D, pilot)`:
  ```text
  N_calc >= ( (z_(alpha / 2) + z_beta)^2 * (s_(D, pilot))^2 ) / (Delta_min^2)
  ```
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * `z_(alpha / 2)`: Valore critico della distribuzione normale standard corrispondente a un test a due code con confidenza 95% (pari a 1.96).
  * `z_beta`: Valore critico corrispondente alla potenza statistica desiderata (pari a 0.84 per potenza dell'80%).
* ***NOTA PRATICA***: E' la formula matematica che ti dice esattamente quanti test devi fare prima di iniziare l'esperimento. Ti impedisce di tirare a indovinare sul numero di prove (es. fare 30 test "a sensazione") e ti garantisce che, se un effetto esiste, avrai l'80% di probabilita' di dimostrarlo con successo.

---

## SEZIONE 8: STATI DI VALUTAZIONE E MATRICE DI DIAGNOSI DIFFERENZIALE

```text
+================================================================================+
|                 LE DUE DIMENSIONI ORTOGONALI DI VALUTAZIONE                    |
|                                                                                |
|   DIMENSIONE 1: EVIDENZA COMPORTAMENTALE (Evidence Status)                     |
|   ├── SUPPORTED    : I dati confermano la predizione preregistrata            |
|   ├── NOT SUPPORTED: Dati insufficienti a supportare la predizione            |
|   └── DISCONFIRMED : I dati contraddicono formalmente la predizione           |
|                                                                                |
|   DIMENSIONE 2: IDENTIFICAZIONE CAUSALE / MECCANICA (Identification Status)    |
|   ├── IDENTIFIED-DIRECT      : Meccanismo/Layer osservato direttamente (V5/V3)|
|   ├── IDENTIFIED-CONDITIONAL : Identificato sotto assunzioni/DAG esplicito    |
|   ├── NOT IDENTIFIED         : Effetto presente ma causa interna ignota       |
|   └── UNDERDETERMINED        : Molteplici spiegazioni interne compatibili     |
+================================================================================+
```

---

### 8.1 Stati di Evidenza Comportamentale (Evidence Status)

* **TERMINE / SIMBOLO**: `SUPPORTED` | `NOT SUPPORTED` | `DISCONFIRMED`
* **DEFINIZIONE METROLOGICA**: Qualificatori formali della relazione stimolo-risposta esteriore `U -> O`:
  * `SUPPORTED`: Il comportamento osservato sul confine terminale soddisfa pienamente e in modo statisticamente valido le predizioni del protocollo sotto il criterio `M` preregistrato.
  * `NOT SUPPORTED`: I dati empirici raccolti mostrano varianza o ampiezza di intervallo tale da non consentire la conferma della predizione.
  * `DISCONFIRMED`: I dati empirici raccolti violano in modo riproducibile e formale una condizione necessaria e vincolante dell'ipotesi indagata.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Comportamentismo Metrologico*: Valutazione basata unicamente sull'evidenza delle uscite in relazione agli ingressi, senza speculazioni sullo stato interno della macchina.
* ***NOTA PRATICA***: Riguarda solo quello che fa la scatola nera visto da fuori. Se avevi previsto che il modello avrebbe restituito il testo intatto e il modello lo fa, scrivi `SUPPORTED`. Se il modello sbaglia o cancella lettere, scrivi `DISCONFIRMED`.

---

### 8.2 Stati di Identificazione Causale (Identification Status)

* **TERMINE / SIMBOLO**: `IDENTIFIED-DIRECT` | `IDENTIFIED-CONDITIONAL` | `NOT IDENTIFIED` | `UNDERDETERMINED`
* **DEFINIZIONE METROLOGICA**: Qualificatori formali dell'attribuzione della causa o del componente interno responsabile del fenomeno:
  * `IDENTIFIED-DIRECT` (o `IDENTIFIED_WITHIN_OBSERVED_BOUNDARY`): La trasformazione e' avvenuta all'interno di un segmento direttamente strumentato e verificato (es. alterazione riscontrata in `C_req` con `V3-3`).
  * `IDENTIFIED-CONDITIONAL`: Il meccanismo e' identificato subordinatamente alla validita' di un modello causale/DAG esplicito e sotto assunzioni di non-confondimento formalizzate.
  * `NOT IDENTIFIED`: L'effetto fenomenologico e' presente, ma e' strutturalmente impossibile localizzare il componente interno che l'ha prodotto.
  * `UNDERDETERMINED`: I dati osservati sono contemporaneamente e perfettamente compatibili con due o piu' spiegazioni architetturali concorrenti (es. indistinguibilita' tra H2, H3, H4, H5).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Sottodeterminazione Teorica*: Condizione epistemica in cui l'evidenza empirica disponibile e' insufficiente a decretare la superiorita' di una teoria scientifica rispetto a teorie rivali.
* ***NOTA PRATICA***: Ti dice se hai scoperto *chi e' il colpevole*. Se hai beccato il browser che alterava i pacchetti prima di spedirli, scrivi `IDENTIFIED-DIRECT`. Se il testo e' arrivato perfetto al server ma la risposta e' sbagliata, devi scrivere onestamente `UNDERDETERMINED`: non puoi sapere se ha sbagliato il firewall, il tokenizer, la rete neurale o il filtro finale.

---

### 8.3 Stratificazione della Provenienza dell'Output (Output Provenance)

* **TERMINE / SIMBOLO**: `VERIFIED` | `ATTRIBUTED` | `UNKNOWN`
* **DEFINIZIONE METROLOGICA**: Gerarchia di certezza metrologica che lega la risposta `O` al processo generativo del SUT:
  * `Claim(SUT_produced(O)) <= VERIFIED`: L'output `O` e' associato al SUT tramite catena di custodia crittografica completa e tracciamento `V3-3`.
  * `Claim(Invocation_returned(O)) <= ATTRIBUTED`: L'output `O` e' stato restituito dall'adapter di invocazione locale senza conferma crittografica di rete.
  * `Output Provenance <= UNKNOWN`: L'output e' orfano o non associabile deterministicamente al trial (comporta l'annullamento del trial per qualsiasi inferenza causale sul SUT).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Catena di Custodia*: La traccia documentale e crittografica continua e ininterrotta che attesta la provenienza, l'integrita' e l'identita' del dato sperimentale.
* ***NOTA PRATICA***: E' il certificato di autenticita' della risposta. `VERIFIED` significa che hai le prove digitali che quella specifica risposta e' stata generata dal modello interrogato. `UNKNOWN` significa che c'e' stato un pasticcio di rete o di file e non sei sicuro al 100% da dove sia saltata fuori quella risposta.

---

### 8.4 Matrice di Diagnosi Differenziale Fondazionale

```text
+======================================================================================================+
|                               MATRICE DI DIAGNOSI DIFFERENZIALE FONDAZIONALE                         |
+------------+------------+----------+-----------------------+-----------------------------------------+
| U_intended | C_req (V3) | O        | Stabilita' & CI       | Inferenza Formale e Confine di Evidenza |
+------------+------------+----------+-----------------------+-----------------------------------------+
| Integro    | Integro    | Conforme | ORR_b == 1.00         | Nessuna alterazione nei confini         |
|            |            | (sotto M)| [0.478, 1.000]        | osservati. Integrita' preservata.       |
|            |            |          |                       | Vettore: E = < O3, C1, R1, S1 >         |
+------------+------------+----------+-----------------------+-----------------------------------------+
| Integro    | Alterato   | Alterato | ORR_b == 1.00         | Trasformazione Client-Side:             |
|            |            |          | [0.478, 1.000]        | Avvenuta nel percorso U -> C_req.       |
|            |            |          |                       | H1a SUPPORTED / IDENTIFIED-DIRECT.      |
|            |            |          |                       | Vettore: E = < O3, C1, R1, S3 >         |
+------------+------------+----------+-----------------------+-----------------------------------------+
| Integro    | Integro    | Alterato | ORR_b == 1.00         | Trasformazione Post-Client:             |
|            |            |          | [0.478, 1.000]        | Avvenuta a valle di C_req.              |
|            |            |          |                       | Causa tra H2, H3, H4, H5: UNDERDETERM.  |
|            |            |          |                       | Vettore: E = < O3, C1, R1, S5 >         |
+------------+------------+----------+-----------------------+-----------------------------------------+
| Integro    | Integro    | Alterato | ORR_b < 1.00          | Varianza di Canale o Generativa:        |
|            |            |          | (Varianza osservata)  | Fenomeno stocastico; compatibile con    |
|            |            |          |                       | sampling (T > 0) o instabilita' routing.|
+------------+------------+----------+-----------------------+-----------------------------------------+
| Integro    | NO-CAPTURE | Alterato | ORR_b == 1.00         | Discrepanza End-to-End (Modalita' B):   |
|            | (V3-0a)    |          | [0.478, 1.000]        | Impossibile localizzare la causa.       |
|            |            |          |                       | Vettore: E = < O1, C0, R1, S1 >         |
+======================================================================================================+
```

* **TERMINE / SIMBOLO**: `Matrice di Diagnosi Differenziale`
* **DEFINIZIONE METROLOGICA**: Tavola di verita' esaustiva compilata dal Decision Engine che incrocia lo stato di integrita' dell'input `U`, del payload di rete `C_req`, dell'output `O` e della stabilita' statistica per emettere deterministicamente lo stato di identificazione e il Vettore di Evidenza `E`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Diagnosi Differenziale*: Metodo di analisi sistematica che identifica la causa esatta di un fenomeno escludendo una per una tutte le spiegazioni alternative incompatibili con i dati.
* ***NOTA PRATICA***: E' la tabella di guida automatica per l'investigatore. Leggendo la riga corrispondente ai tuoi dati (cosa e' entrato, cosa e' passato in rete, cosa e' uscito), la tabella ti dice esattamente quale conclusione puoi scrivere senza rischiare di commettere errori logici.

---

#### MATRICE DEGLI ESITI DEI TRIAL DELL'HARNESS (Blueprint Sez. 6.2)

```text
+---------------------+-------------------+-------------------+--------------------------------------------+
| TRANSPORT_OBSERVED  | OUTPUT_OBSERVED   | OUTPUT_PROVENANCE | CLASSIFICAZIONE DEL TRIAL                  |
+---------------------+-------------------+-------------------+--------------------------------------------+
| TRUE (V3-3)         | TRUE              | VERIFIED          | VALID_TRIAL (Full Modalita A)              |
| TRUE (V3-3)         | FALSE             | N/A               | CORRUPT_STREAM (Invalido Trasporto)        |
| FALSE (V3-0a)       | TRUE              | VERIFIED          | BEHAVIORAL_ONLY_TRIAL (Modalita B SUT-Ver.)|
| FALSE (V3-0a)       | TRUE              | ATTRIBUTED        | BEHAVIORAL_ONLY_TRIAL (Modalita B Invoc.)  |
| FALSE (V3-0a)       | TRUE              | UNKNOWN           | OUTPUT_OBSERVED_UNATTRIBUTED (Trial Nullo) |
| FALSE (V3-0a)       | FALSE             | N/A               | FAILED_TRIAL (Trial Nullo / Errore Host)   |
+---------------------+-------------------+-------------------+--------------------------------------------+
```

* **TERMINE / SIMBOLO**: `Classificazione Esiti Trial` | `VALID_TRIAL` | `CORRUPT_STREAM` | `BEHAVIORAL_ONLY_TRIAL` | `OUTPUT_OBSERVED_UNATTRIBUTED` | `FAILED_TRIAL`
* **DEFINIZIONE METROLOGICA**: Tassonomia dello stato di esecuzione emessa dal Decision Engine dell'harness per ciascuna prova sperimentale:
  * `VALID_TRIAL`: Prova completa eseguita in Modalità A con verifica congiunta di `C_req`, `C_resp` e `O`.
  * `CORRUPT_STREAM`: Chiamata di rete tracciata ma stream interrotto o payload JSON troncato prima del completamento.
  * `BEHAVIORAL_ONLY_TRIAL`: Prova valida limitatamente alla relazione terminale `U -> O` (Modalità B).
  * `OUTPUT_OBSERVED_UNATTRIBUTED`: Risposta presente ma non riconducibile deterministicamente alla sessione attiva (trial nullo per inferenze sul SUT).
  * `FAILED_TRIAL`: Prova fallita per crash del processo locale, timeout o errore di connettività host.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Decision Engine*: Motore software a regole logiche compilate che categorizza l'esito della prova escludendo qualsiasi intervento dell'LLM dal processo di classificazione.
* ***NOTA PRATICA***: Dice al ricercatore se la singola prova può essere utilizzata per trarre conclusioni complete (`VALID_TRIAL`), se può essere usata solo come osservazione esterna (`BEHAVIORAL_ONLY_TRIAL`) o se deve essere cestinata (`OUTPUT_OBSERVED_UNATTRIBUTED` / `FAILED_TRIAL`).

---

## SEZIONE 9: THE QUADRUPLET RULE E REFERTAZIONE SOTU v2.3

```text
+------------------------------------------------------------------------------+
|                         THE QUADRUPLET RULE (SOTU v2.3)                      |
|                                                                              |
|  [ 1. OSSERVAZIONE ]    ──> I puri fatti misurati (Byte, Digest SHA-256)     |
|                                                                              |
|  [ 2. INFERENZA ]       ──> Ipotesi residue compatibili sotto il criterio M  |
|                                                                              |
|  [ 3. CONCLUSIONE ]     ──> Ipotesi formalmente ESCLUSE e Vettore E          |
|                                                                              |
|  [ 4. NON DETERMINATO ] ──> Dichiarazione onesta dei layer inaccessibili     |
|  ─────────────────────────────────────────────────────────────  |
|  [ ADDENDUM METODOLOGICO ] Assunzioni degli strumenti & Condizioni di Disconf|
+------------------------------------------------------------------------------+
```

---

### 9.1 The Quadruplet Rule e Architettura del Report SOTU

* **TERMINE / SIMBOLO**: `The Quadruplet Rule` | `SOTU v2.3 Master Template`
* **DEFINIZIONE METROLOGICA**: Standard normativo strutturale obbligatorio per la redazione di qualsiasi verbale o referto conclusivo di prova SOTU (State Of The Unit). Impone che ogni report finale sia imperativamente articolato sui quattro pilastri analitici (`OSSERVAZIONE`, `INFERENZA`, `CONCLUSIONE`, `NON DETERMINATO`) e corredato dall'Addendum Metodologico.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Referto SOTU*: Il documento ufficiale di sintesi metrologica emesso al termine di una sessione di test conforme al protocollo CDP v2.3.
* ***NOTA PRATICA***: E' la struttura fissa e intoccabile del verbale di laboratorio. Nessun ricercatore puo' scrivere conclusioni a forma di saggio o opinione libera: ogni referto deve contenere esattamente queste 4 sezioni separate per garantire la totale trasparenza scientifica.

---

### 9.2 Pilastro 1: OSSERVAZIONE

* **TERMINE / SIMBOLO**: `Pilastro 1: OSSERVAZIONE`
* **DEFINIZIONE METROLOGICA**: Sezione descrittiva del referto che riporta esclusivamente i dati empirici e metrologici grezzi acquisiti dagli strumenti di misura sui confini intercettati: sequenze scalari esatte, byte esadecimali, digest SHA-256 canonici UTF-8, conteggi dei campioni `N`, numero di successi `k` e intervalli di confidenza calcolati. E' rigorosamente vietato inserire interpretazioni o ipotesi in questo pilastro.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Digest Canonico SHA-256*: L'impronta crittografica calcolata esclusivamente previa serializzazione dei caratteri in byte conformi a UTF-8 standard.
* ***NOTA PRATICA***: Qui scrivi solo cio' che le macchine hanno registrato. Esempio: "Inviata la stringa X con hash ABC; ricevuta la stringa Y con hash DEF in 5 prove su 5". Nient'altro: solo fatti, byte e numeri.

---

### 9.3 Pilastro 2: INFERENZA

* **TERMINE / SIMBOLO**: `Pilastro 2: INFERENZA`
* **DEFINIZIONE METROLOGICA**: Sezione analitica del referto che definisce e argomenta lo spazio di tutte le ipotesi teoriche residue (`H1 - H5`) che rimangono compatibili con i dati registrati nel Pilastro 1, qualificate e vincolate sotto lo specifico criterio di confronto `M` (es. `M1-scalar`, `M2a`, `M5`) formalmente adottato nel disegno preregistrato.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Spazio di Compatibilita'*: L'insieme di tutte le spiegazioni logiche che non sono state rese impossibili dai dati osservati.
* ***NOTA PRATICA***: Qui spieghi cosa potrebbero significare quei numeri. Esempio: "Dato che il pacchetto di rete era corretto ma la risposta e' sbagliata sotto il criterio M1, il problema potrebbe risiedere nel firewall del server (H2a), nel tokenizer (H3) o nei pesi del modello (H4)".

---

### 9.4 Pilastro 3: CONCLUSIONE

* **TERMINE / SIMBOLO**: `Pilastro 3: CONCLUSIONE`
* **DEFINIZIONE METROLOGICA**: Sezione decisionale del referto che dichiara formalmente le ipotesi che risultano **escluse con certezza** dai dati empirici sotto le assunzioni dichiarate, assegna lo stato di evidenza (`SUPPORTED`, `DISCONFIRMED`), lo stato di identificazione e certifica il Vettore di Evidenza formale `E = < O_x, C_x, R_x, S_x >` in ottemperanza alla regola `Strength(Claim) <= Strength(Evidence)`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Esclusione Formale*: Dimostrazione logica e metrologica che un'ipotesi prediceva un dato empirico incompatibile con quanto rilevato.
* ***NOTA PRATICA***: E' la sentenza definitiva dell'esperimento. Esempio: "1. Si esclude con certezza che il browser abbia alterato il testo (H1a DISCONFIRMED); 2. L'identificazione del componente server colpevole e' NOT IDENTIFIED; 3. Vettore di Evidenza certificato: E = < O3, C1, R1, S5 >".

---

### 9.5 Pilastro 4: NON DETERMINATO

* **TERMINE / SIMBOLO**: `Pilastro 4: NON DETERMINATO`
* **DEFINIZIONE METROLOGICA**: Sezione di dichiarazione epistemica obbligatoria che elenca categoricamente tutti i layer fisici o logici del sistema rimasti inaccessibili alla misurazione (`Layer S`, `Token IDs`, `M_raw`), richiamando formalmente l'applicazione del postulato `not(Obs(X)) /=> not(X)`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Clausola di Trasparenza sui Limiti*: Riconoscimento esplicito dei confini oltre i quali la strumentazione adottata non puo' fornire alcuna informazione certa.
* ***NOTA PRATICA***: E' il bagno di umilta' scientifica. Qui scrivi chiaramente tutto cio' che NON hai potuto vedere. Esempio: "I layer interni del server (contesto assemblato e pesi neurali) non sono stati intercettati. La mancata visualizzazione del carattere a schermo non dimostra che il modello non l'abbia elaborato internamente".

---

### 9.6 Addendum Metodologico Obbligatorio

* **TERMINE / SIMBOLO**: `Addendum Metodologico` | `Assunzioni Strumentali` | `Condizioni di Disconferma`
* **DEFINIZIONE METROLOGICA**: Sezione integrativa vincolante del verbale SOTU composta da due elementi:
  1. *Assunzioni Strumentali*: Le ipotesi tecniche assunte come vere circa la fedelta' degli strumenti di misura (es. "si assume che la libreria cURL non alteri i byte durante la scrittura sul socket TLS").
  2. *Condizioni di Disconferma*: Il criterio empirico univoco e quantitativo che, qualora si fosse verificato durante la prova, avrebbe falsificato categoricamente la conclusione raggiunta.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Criterio di Falsificabilita'*: Condizione logica senza la quale un esperimento cessa di essere scientifico e diventa un'asserzione dogmatica.
* ***NOTA PRATICA***: Per essere trasparente al 100%, devi dichiarare: 1) Di quali strumenti ti sei fidato (es. "mi fido che Wireshark registri i pacchetti reali"); 2) Cosa avrebbe dovuto succedere per farti ammettere di aver torto (es. "se anche solo 1 prova su 5 avesse mostrato un carattere diverso, l'ipotesi sarebbe stata respinta").

---

### 9.7 Fenomenologia di Terminazione Canali Streaming

```text
+------------------------------------------------------------------------------+
|                  PROFILI DI CHIUSURA DEL CANALE DI STREAMING                 |
|                                                                              |
|  [ WebSocket RFC 6455 ]                                                      |
|  ├── 1000 : Normal Closure (Chiusura ordinaria con successo)                 |
|  ├── 1001 : Going Away (Server in riavvio o navigazione dismessa)            |
|  ├── 1008 : Policy Violation (Chiusura per violazione filtri/sicurezza)      |
|  ├── 1011 : Internal Error (Eccezione/crash non gestito sul backend)         |
|  └── 1006 : Abnormal Closure [LOCALE] (Mancata ricezione frame di chiusura)  |
|                                                                              |
|  [ Server-Sent Events / HTTP Chunked ]                                       |
|  ├── data: [DONE]              : Sentinella applicativa standard di fine     |
|  └── finish_reason: stop       : Generazione naturale completata             |
|      finish_reason: length     : Raggiunto limite max_tokens                 |
|      finish_reason: content_filter : Intervento guardrail di sicurezza       |
+------------------------------------------------------------------------------+
```

* **TERMINE / SIMBOLO**: `Fenomenologia di Terminazione` | `WS 1000` | `WS 1001` | `WS 1008` | `WS 1011` | `WS 1006 Locale` | `finish_reason`
* **DEFINIZIONE METROLOGICA**: Caratterizzazione sistematica degli eventi discreti di chiusura del canale di trasporto e applicativo. La SOP v2.3 impone la distinzione categorica tra frame di chiusura effettivamente trasmessi dal server remoto e codici di errore sintetizzati localmente dallo stack del browser/client:
  * *Codici WebSocket Ricevuti*: `1000` (Successo ordinario), `1001` (Disconnessione ordinata), `1008` (Violazione di policy / safety trigger), `1011` (Errore interno del server).
  * *Codice Sintetizzato Locale*: `1006 (Abnormal Closure)` attesta esclusivamente che la connessione TCP si e' interrotta senza la ricezione di un frame di Close conforme. **E' formalmente vietato registrare il 1006 come messaggio inviato dal server**.
  * *Sentinelle Applicative*: Stringhe JSON del tipo `finish_reason: "stop"` (termine naturale), `"length"` (saturazione contesto) o `"content_filter"` (blocco per filtri).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *RFC 6455*: Lo standard internazionale che regolamenta il protocollo WebSocket e la semantica dei codici numerici di chiusura della connessione.
  * *Browser-Synthesized Error*: Codice di stato generato internamente dal motore di rete del browser quando la connessione sottostante svanisce improvvisamente senza un messaggio di arrivederci dal server.
* ***NOTA PRATICA***: Quando lo streaming di parole si interrompe, devi capire *come* e *chi* ha chiuso la conversazione. Se leggi `1008` o `content_filter`, il server ti ha detto esplicitamente "ti blocco perche' hai violato le regole". Se leggi `1006`, internet e' caduto all'improvviso e il server non ha fatto in tempo a dirti perche'. Sapere la differenza evita di confondere un semplice problema di Wi-Fi con una censura del modello.

---

## SEZIONE 10: CATALOGO DELLE SUITE DI TEST (RUN 0, T01 - T14, CDP-FZ)

```text
+------------------------------------------------------------------------------+
|                     MAPPA DELLE BATTERIE DI TEST (SOP v2.3)                  |
|                                                                              |
|  [ CALIBRAZIONE ] ──> RUN 0 : Validazione V3-3 su U_ref (CANARY#7F3A91#OMEGA)|
|                                                                              |
|  [ CONFERMATORIA] ──> T01 : Transport Integrity & Canary Preservation        |
|  (T01 - T04)          T02 : Whitespace & Control Boundary Preservation       |
|                       T03 : Unicode Normalization (NFC/NFD/NFKC/NFKD)        |
|                       T04 : Invisible & Format Characters (ZWSP/ZWNJ/BOM)    |
|                                                                              |
|  [ ESPLORATIVA  ] ──> T05 : Cross-Turn Context Recall Probe                  |
|  (T05 - T10)          T06 : Cross-Session Persistence Phenotype              |
|                       T07 : Markup & System Role Simulation                  |
|                       T08 : Escape Sequences & DOM Sanitization              |
|                       T09 : Streaming Termination Characterization           |
|                       T10 : Cross-System Replicated Phenotype                |
|                                                                              |
|  [ DIAGNOSTICA  ] ──> T11 : Token Accounting Discrepancy (Delta_doc)         |
|  (T11 - T14)          T12 : Paired Latency & TTFT Observed (bar_D)           |
|                       T13 : Declared Prefix Caching Probe                    |
|                       T14 : Long-Context Retrieval Degradation (L, D)        |
|                                                                              |
|  [ APPENDICE A  ] ──> CDP-FZ : Binary Socket Fuzzing (FZ-01 .. FZ-05)        |
+------------------------------------------------------------------------------+
```

---

### 10.1 RUN 0 — V3 Observability Calibration

* **TERMINE / SIMBOLO**: `RUN 0` | `U_ref` | `Calibrazione V3`
* **DEFINIZIONE METROLOGICA**: Procedura preliminare obbligatoria di qualificazione della catena di misura eseguita con lo stimolo standard `U_ref = CANARY#7F3A91#OMEGA` (19 scalari ASCII, SHA-256: `dd4019696497ad7e1ca011fe83f57a7354edf66f62fd84f7eb03bbb49134c4e9`). Verifica i 4 predicati di custodia per assegnare la classificazione `V3-3` e stabilire se il laboratorio opera in `Modalita' A` o `Modalita' B`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Verifica di Calibrazione*: Controllo metrologico preventivo volto a escludere disallineamenti dello strumento prima di intraprendere la raccolta dei dati sperimentali.
* ***NOTA PRATICA***: E' il "collaudo iniziale". Prima di fare sul serio, invii una stringa fissa e controlli che i DevTools e gli script leggano tutto alla perfezione. Se il RUN 0 fallisce, l'intero laboratorio si ferma.

---

### 10.2 Suite Confermatoria (Test T01 – T04)

* **TERMINE / SIMBOLO**: `Suite Confermatoria` | `T01` | `T02` | `T03` | `T04`
* **DEFINIZIONE METROLOGICA**: Batteria di prove formali ad alta precisione volte a verificare l'integrita' di base del canale di trasporto e rendering:
  * `T01`: Ladder OFAT a 5 gradini per la preservazione del canary sotto criterio `M1-scalar`.
  * `T02`: Matrice a 5 rami per la verifica del trattamento degli spazi multipli, tabulazioni e newline interni vs confini.
  * `T03`: Matrice differenziale a 4 rami per l'analisi delle forme di normalizzazione Unicode UAX #15 (`NFC`, `NFD`, `NFKC`, `NFKD`).
  * `T04`: Matrice differenziale per caratteri invisibili e di formato a larghezza zero (`ZWSP`, `ZWNJ`, `ZWNBSP`).
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Test Confermatorio*: Esperimento progettato per falsificare rigorosamente specifiche ipotesi strutturali di sanitizzazione del canale.
* ***NOTA PRATICA***: Sono i 4 test fondamentali di base. Controllano se il sistema rispetta i testi lettera per lettera, se taglia gli spazi vuoti, se altera le lettere accentate o se cancella i caratteri invisibili.

---

### 10.3 Suite Esplorativa (Test T05 – T10)

* **TERMINE / SIMBOLO**: `Suite Esplorativa` | `T05` | `T06` | `T07` | `T08` | `T09` | `T10`
* **DEFINIZIONE METROLOGICA**: Batteria di prove comportamentali per la caratterizzazione fenomenologica del sistema in scenari complessi:
  * `T05`: Recupero del canary al Turno 3 dopo compito distrattore al Turno 2 (Cross-Turn Recall).
  * `T06`: Verifica del passaggio di informazioni tra sessioni disgiunte A e B con controlli negativi (Cross-Session Persistence).
  * `T07`: Valutazione della reazione a strutture di controllo simulate (JSON, Markdown, tag XML di sistema).
  * `T08`: Trattamento comparato di sequenze di escape letterali (`\r\n`, `\x00`), entita' HTML e tag DOM.
  * `T09`: Caratterizzazione dei codici di terminazione dello streaming (WebSocket Close codes e sentinelle SSE).
  * `T10`: Replicazione fenomenologica su matrice eterogenea di modelli e runtime differenti.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Studio Esplorativo*: Ricerca empirica mirata a mappare il perimetro operativo e le risposte del sistema su dimensioni dinamiche.
* ***NOTA PRATICA***: Sono i test avanzati. Esplorano la memoria della conversazione (T05), la memoria a lungo termine tra chat diverse (T06), come il modello reagisce a comandi finti (T07) e come si comporta quando la connessione si chiude (T09).

---

### 10.4 Suite Diagnostica (Test T11 – T14)

* **TERMINE / SIMBOLO**: `Suite Diagnostica` | `T11` | `T12` | `T13` | `T14`
* **DEFINIZIONE METROLOGICA**: Batteria di probe quantitativi per l'analisi differenziale e metrologica avanzata:
  * `T11 (Token Discrepancy)`: Misura dello scarto `Delta_doc = N_api - N_ref_doc` tra token contabili dichiarati e token teorici calcolati da chat template documentato.
  * `T12 (Paired Latency)`: Misura differenziale del TTFT appaiato (`bar_D`) tra due classi di stimoli tramite disegno a blocchi (ABAB).
  * `T13 (Declared Caching)`: Rilevazione dell'attributo dichiarato `usage.prompt_tokens_details.cached_tokens > 0` senza inferire KV-cache GPU fisica.
  * `T14 (Context Retrieval)`: Mappatura della funzione di recupero `Retrieval_Rate(L, D)` su matrice bidimensionale di lunghezza contesto `L` e profondita' `D`.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Probe Diagnostico*: Misurazione metrica mirata a quantificare variabili di costo o latenza senza salti inferenziali sul meccanismo interno.
* ***NOTA PRATICA***: Sono i test "da laboratorio con il bilancino". Misurano quanti token ti vengono addebitati (T11), quanti millisecondi di ritardo provoca un prompt complesso (T12), se il server usa scorciatoie di cache (T13) e se il modello perde la memoria quando il testo diventa lunghissimo (T14).

---

### 10.5 Protocollo di Fuzzing di Trasporto (Appendice A: CDP-FZ v1.1)

* **TERMINE / SIMBOLO**: `CDP-FZ` | `Matrice FZ-01 .. FZ-05`
* **DEFINIZIONE METROLOGICA**: Suite di iniezione a basso livello su socket binari autorizzati:
  * `FZ-01`: RAW Null Byte (`0x00`) in frame WebSocket UTF-8 (attesa: `1002 Protocol Error`).
  * `FZ-02`: Sequenze non-UTF-8 invalide o overlong (attesa: `1007 Invalid Payload`).
  * `FZ-03`: Frame WebSocket non mascherati da client (attesa: `1002 Protocol Error`).
  * `FZ-04`: Stream JSON con payload troncato a meta' chiave (attesa: `HTTP 400 Bad Request`).
  * `FZ-05`: Frame di reset prematuro `RST_STREAM` su connessione HTTP/3.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Payload Overlong*: Codifica UTF-8 non valida e non sicura che utilizza piu' byte del necessario per rappresentare un carattere ASCII.
* ***NOTA PRATICA***: E' il banco di prova per testare se i sistemi di trasporto vanno in crash quando ricevono byte corrotti o attacchi a livello di rete.

---

## SEZIONE 11: STATI DEL SISTEMA, GRAFO DI ESECUZIONE ED ECOSISTEMA RUNTIME

```text
+------------------------------------------------------------------------------+
|                     GRAFO DI ESECUZIONE DELLA SESSIONE                       |
|                                                                              |
|  [ SA.Q0, e_0 ] ──(Iniezione Canary)──> [ SA.Q1, e_0 ] ──> [ SA.Q_closed ]  |
|                                                                    │         |
|  [ SB.Q0, e_0 ] <──(Apertura Nuova Sessione B Disgiunta)───────────┘      |
|        │                                                                     |
|        ▼ (Recall Probe)                                                     |
|  [ SB.Q_probe ] ──(Risposta Verificata)──> [ SB.Q_terminal ]                |
+------------------------------------------------------------------------------+
```

---

### 11.1 Sistema a Stati Composti (e_0 vs e_1)

* **TERMINE / SIMBOLO**: `S_state` | `e_0 (Pure Ephemeral)` | `e_1 (Persistent Account)`
* **DEFINIZIONE METROLOGICA**: Formalizzazione dello stato dell'ambiente sperimentale come prodotto cartesiano tra lo stato della conversazione e la configurazione ambientale:
  ```text
  S_state = < q_session, e_env >   in   Q_session x E_env
  ```
  * `e_0 [Pure Ephemeral State]`: Ambiente privo di memoria cross-chat, custom instructions o persistenza account (stateless).
  * `e_1 [Persistent Account State]`: Ambiente con memorie globali utente attive, RAG persistente o cronologia sincronizzata.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Stateless*: Condizione in cui ogni sessione e' totalmente isolata e non conserva traccia delle interazioni precedenti.
* ***NOTA PRATICA***: Distingue se stai testando il modello in modalita' "navigazione in incognito / API pura" (`e_0`) oppure se sei loggato con un account personale che si ricorda chi sei e cosa hai scritto nei giorni scorsi (`e_1`).

---

### 11.2 Grafo di Esecuzione Deterministico Preregistrato (G_protocol)

* **TERMINE / SIMBOLO**: `G_protocol` | `Grafo di Esecuzione Preregistrato`
* **DEFINIZIONE METROLOGICA**: Macchina a stati finiti deterministica che descrive la successione invariante dei turni di dialogo:
  ```text
  G_protocol = < Q_prereg, Sigma_actions, delta_transitions, q_init, F_terminal > x E_env
  ```
  La *Regola di Fedelta' Sperimentale* vieta di alterare retroattivamente la sequenza degli stati (`SA.Q0 -> SA.Q1 -> SA.Q2 -> ...`) per fini estetici o esplicativi.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Congelamento Topologico*: L'impossibilita' di inserire domande intermedie non previste nel piano di prova registrato prima del lancio.
* ***NOTA PRATICA***: E' il binario ferroviario del test. Se il protocollo prevede che al Turno 1 inietti il canary, al Turno 2 fai una moltiplicazione matematica e al Turno 3 chiedi il canary, devi seguire esattamente questo percorso senza inventare domande a meta' strada.

---

### 11.3 bash4llm Adapter & Termux Shell Metrology Setup

* **TERMINE / SIMBOLO**: `bash4llm Adapter` | `Termux Harness Environment` | `DEBUG_PRESERVE`
* **DEFINIZIONE METROLOGICA**: Modulo di invocazione e wrapping locale (bash4llm v2.8.5.3) integrato nell'harness Android/Termux:
  * Opera in ambiente con variabili forzate `LC_ALL=C.UTF-8`, `LANG=C.UTF-8` e permessi restrittivi `umask 077` (file `0600`, directory `0700`).
  * Con `DEBUG_PRESERVE=1` cattura e salva su disco i file materializzati prima del cleanup:
    * `raw_artifacts/C_req_app.bin`: Payload JSON di richiesta esatto.
    * `raw_artifacts/C_resp_app.json`: Payload JSON di risposta integrale.
    * `raw_artifacts/cURL.log`: Traccia degli header e status code HTTP.
* **SCOMPOSIZIONE TERMINI INTERNI**:
  * *Harness di Misura*: L'infrastruttura software che orchestra le chiamate, garantisce l'isolamento dei processi e raccoglie gli artefatti grezzi per l'analisi metrologica.
* ***NOTA PRATICA***: E' l'attrezzatura di laboratorio installata sul tuo smartphone/Termux. Si assicura che il testo non venga rovinato dal sistema operativo, cattura i file di rete prima che si cancellino e garantisce che nessun'altra app disturbi la misurazione.

---
