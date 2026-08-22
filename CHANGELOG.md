# Changelog

Tutte le modifiche rilevanti a questo progetto sono tracciate in questo file.
Formato basato su [Keep a Changelog](https://keepachangelog.com/) e [Semantic Versioning](https://semver.org/).

## [2.3.0] - 2026-08-22

### Aggiunto
- **cdp.sh**: Master CLI Gateway unificato per l'orchestrazione rapida e la diagnostica del workspace.
- **docs/CDP_Theory.md**: Specifiche teoriche formali ed epistemologiche del protocollo CDP v2.3.
- **docs/SOP_Manual.md**: Manuale operativo di laboratorio, procedure metrologiche e suite di test T01–T14.
- **docs/GLOSSARIO.md**: Glossario metrologico integrato (11 sezioni, pure ASCII).
- **docs/BLUEPRINT.md**: Specifiche tecniche di architettura software, contratti JSON e decision DAG dell'harness.
- **docs/help.txt**: Guida di consultazione per la CLI master `cdp`.
- **harness/**: Suite metrologica autonoma completa (MOD-01..MOD-09) con zero dipendenze pip: sonde ambientali, builder OFAT, motori statistici UAX/Clopper-Pearson, decision DAG deterministico e generatori di report SOTU e dashboard.
