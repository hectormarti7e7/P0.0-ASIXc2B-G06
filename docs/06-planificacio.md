# 6. Planificació (ProofHub)

Projecte ProofHub: `P0.0-ASIXc2gC-Gnn`. 6 setmanes (fins 18/11), 3 sprints quinzenals de 10 h per persona.

## Sprint 1 — Fonaments (setmanes 1-2)
- [ ] Crear projecte ProofHub, backlog i repositori GitHub amb clau SSH
- [ ] Diagrama d'arquitectura i taula d'adreçament
- [ ] Imatge base Docker (sshd + bchecker) i `docker-compose.yml` amb les 3 xarxes
- [ ] Router R-NCC: forwarding, NAT i firewall
- [ ] DNS (R-NCC i R) i DHCP

## Sprint 2 — Serveis (setmanes 3-4)
- [ ] BBDD MySQL + usuari bchecker
- [ ] Script de càrrega del CSV d'equipaments d'educació
- [ ] Web W-NCC (nginx + Flask) que mostra les taules
- [ ] FTP F-NCC i SSH
- [ ] Monitor de xarxes (Uptime Kuma) amb sondes a tots els serveis
- [ ] Client Linux i client Windows

## Sprint 3 — Proves i documentació (setmanes 5-6)
- [ ] `deploy.sh` i `tests/check.sh`
- [ ] Joc de proves complet i evidències (captures)
- [ ] Documentació Markdown (client i administrador)
- [ ] Control de versions documentat (add/commit/push/pull/clone)
- [ ] Revisió creuada entre companys, correccions
- [ ] Preparar la defensa
- [ ] (Opcional) Propostes de millora, veure `07-millores.md`
