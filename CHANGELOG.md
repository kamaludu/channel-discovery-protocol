# Changelog

Tutte le modifiche rilevanti a questo progetto sono tracciate in questo file.
Formato basato su [Keep a Changelog](https://keepachangelog.com/) e [Semantic Versioning](https://semver.org/).

## [2.3.0] - 2026-08-22

### Aggiunto
- **cdp.sh**: Master CLI Gateway unificato per l'orchestrazione rapida e la diagnostica del workspace.
- **cdp_run.sh**: Runner master di esecuzione della suite metrologica (MOD-01).
- **core/**: Moduli di telemetria host, adapter per SUT e builder delle matrici OFAT (MOD-02..MOD-04).
- **metrology/**: Motori di normalizzazione Unicode UAX, calcolo statistico esatto (Clopper-Pearson) e decision DAG deterministico (MOD-05..MOD-07).
- **reporters/**: Compilatore dei referti ufficiali SOTU e generatore della dashboard di campagna (MOD-08, MOD-09).
- **docs/CDP_Theory.md**: Specifiche teoriche formali ed epistemologiche del protocollo CDP v2.3.
- **docs/SOP_Manual.md**: Manuale operativo di laboratorio, procedure e suite di test T01–T14.
- **docs/GLOSSAR.md**: Glossario metrologico integrato (11 sezioni, pure ASCII).
- **docs/BLUEPRINT.md**: Specifiche tecniche di architettura software, contratti JSON e decision DAG.
- **docs/help.txt**: Guida interattiva di consultazione per la CLI master `cdp`.
