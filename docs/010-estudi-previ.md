| | |
|---|---|
| **Projecte** | P0.0 «Desplegament d'infraestructura» — G06 (NCC = N06) |
| **Autor** | Hèctor Marti (MH) |
| **Data** | 26/10/2026 |
 
# Estudi previ de tecnologies i empreses del mercat
 
## 0. Resum executiu
 
| Capa | Decisió al prototip | Alternativa estudiada | Motiu principal | Risc identificat |
|---|---|---|---|---|
| Servidor web (W-N06) | **nginx** davant de gunicorn | Apache HTTP Server | Fa de proxy invers i terminació TLS lleuger, i encaixa amb un contenidor per servei | Propietari corporatiu únic (F5) i quota en descens lent |
| Monitor (MON-N06) | **Uptime Kuma v1** | Zabbix | Cobreix la disponibilitat (RA2) amb un sol contenidor i cost zero | La v1 ja té successora (v2) i no mesura recursos de sistema |
| Tallafocs (R-N06) | **iptables** | nftables | És el *backend* per defecte de Docker i el que usa el repositori | iptables és l'opció «legacy» de Netfilter i les distribucions la van deixant |
 
**Conclusió en una línia:** les tres decisions es poden justificar amb dades actuals (octubre de 2026), però cadascuna té una *via d'evolució* clara, documentada a l'apartat 5.
 
---
 
## 1. Metodologia i criteris
 
### 1.1 Com s'han triat els criteris
Els criteris de comparació es deriven de tres fonts:
 
- Els requisits de l'enunciat i de la rúbrica P0.0: seguretat, virtualització, xarxes, rendiment i disponibilitat.
- El que necessita realment el prototip: un contenidor per servei, tot en una sola VM i desplegament amb `./deploy.sh up`.
- Criteris estratègics habituals en una selecció de tecnologia: llicència, govern del projecte, cicle de vida, quota de mercat i risc de dependència d'un proveïdor.
### 1.2 Necessitats del projecte i oportunitats
 
**Necessitats que condicionen l'elecció:**
 
- Protegir l'aplicació (TLS, autenticació, segmentació de xarxes) amb una configuració curta i versionable a Git.
- Poder mesurar disponibilitat i temps de recuperació de manera objectiva (RA2).
- Mantenir un cost de llicència i d'operació mínims, amb un desplegament reproduïble en un sol ordre.
- Tenir una política de tallafocs fàcil de mostrar i defensar amb captures.
**Oportunitats que ofereix el mercat:**
 
- La llicència BSD de nginx permet *forks* (Angie, freenginx), cosa que redueix el risc de dependència d'un sol proveïdor.
- Uptime Kuma 2.0 afegeix MariaDB i imatges *rootless*, i obre una ruta de millora sense canviar d'eina.
- Zabbix 7.0 LTS (suport fins al 2029) és una opció de creixement si calen mètriques de recursos.
- Docker Engine v29 incorpora un *backend* nftables experimental, que facilita una migració gradual des d'iptables.
### 1.3 Com es llegeixen les afirmacions
Les dades numèriques i els fets verificables (quotes, dates, llicències, versions) provenen de les fonts de l'apartat 6, classificades per fiabilitat (A = primària, B = secundària, C = bloc/premsa). Les valoracions tècniques sense font concreta són **coneixement general** i s'han d'entendre com a criteri d'enginyeria, no com a prova. Les limitacions de cada bloc indiquen què queda per verificar.
 
---
 
## 2. Servidor web: nginx vs Apache HTTP Server
 
### 2.1 Context al projecte
`W-N06` (10.213.1.10, DMZ) serveix una aplicació **Flask executada per gunicorn**, amb **nginx** al davant fent HTTPS autofirmat i autenticació bàsica. La pregunta d'enginyeria és: podria fer-ho igualment Apache, i per què hem triat nginx?
 
### 2.2 Comparativa per criteris
 
| Criteri | nginx | Apache HTTP Server |
|---|---|---|
| **Origen** | Creat per Igor Sysoev (2004) per al portal rus Rambler | Projecte iniciat el 1995 a partir de NCSA HTTPd |
| **Qui el governa** | Empresa NGINX Inc., adquirida per **F5** el març de 2019 per uns **670 M$** | **Apache Software Foundation** (comunitat de desenvolupadors) |
| **Llicència** | BSD de 2 clàusules (versió oberta); *NGINX Plus* és propietari | Apache License 2.0 |
| **Versió estable de referència** | Pendent de verificar al contenidor (`docker exec W-N06 nginx -v`) | 2.4.69 (1/10/2026) |
| **Quota de mercat (oct. 2026)** | **30,3 %** dels llocs amb servidor conegut | **21,4 %** |
| **Model d'execució** | Orientat a esdeveniments, amb pocs processos | Diversos MPM: asíncron (*event*), amb fils (*worker*) i per processos (*prefork*) |
| **Configuració** | Arbre de fitxers central; no hi ha `.htaccess` | Admet `.htaccess` per directori, útil en allotjament compartit |
| **Contingut dinàmic** | No incrusta intèrprets: delega a una aplicació externa via `proxy_pass`/FastCGI | Pot incrustar mòduls (p. ex. `mod_wsgi`) o fer de proxy |
| **Encaix amb Flask + gunicorn** | gunicorn no s'ha d'exposar directament a Internet; nginx fa de proxy invers, serveix estàtics i acaba TLS | Possible amb `mod_proxy`; funcionalment equivalent, però més pesat en un contenidor |
| **Cost de llicència** | 0 € (versió oberta) | 0 € |
| **Autenticació bàsica + HTTPS** | Sí (usat al prototip i validat per `tests/check.sh`) | Sí |
 
### 2.3 Empreses i projectes darrere de cada tecnologia
 
| Tecnologia | Empresa / entitat | Model de negoci | Dades rellevants |
|---|---|---|---|
| nginx | **F5, Inc.** (EUA, NASDAQ: FFIV) | Ven *NGINX Plus* i serveis d'entrega d'aplicacions; el nucli és obert | Compra anunciada l'11/03/2019, valor d'empresa ≈ 670 M$; F5 es va comprometre a augmentar la inversió en el projecte obert |
| Apache httpd | **Apache Software Foundation** | Fundació sense ànim de lucre, finançada per patrocini | Llicència Apache 2.0 des del 2004 |
| Alternatives presents al mercat | **Cloudflare**, **LiteSpeed Technologies**, **Caddy** | Servei de CDN/proxy (Cloudflare), servidor comercial i obert (LiteSpeed), servidor obert (Caddy) | Quotes: Cloudflare Server 32,5 %, LiteSpeed 14,0 %, Caddy 1,1 % |
 
### 2.4 Quota de mercat i tendència (dades reals, W3Techs)
 
| Data de la mesura | Quota de nginx |
|---|---|
| 21/09/2025 | 33,3 % |
| 28/12/2025 | 33,2 % |
| 16/02/2026 | 32,8 % |
| **19/10/2026** | **30,3 %** |
 
Apache està al **21,4 %** el 19/10/2026. Com a context històric, el 2010 Apache tenia el 71,5 % i el 2017 va caure per sota del 50 %. El 22/09/2026 W3Techs va destacar que el «Cloudflare Server» ha passat nginx com a servidor més usat.
 
**Lectura:** nginx i Apache van perdent quota davant de serveis gestionats (CDN i proxies de núvol). Això no afecta el nostre cas, perquè el prototip és **autoallotjat**, però indica que la quota no és un criteri decisiu per si sol. W3Techs només mesura llocs web públics i un lloc pot usar més d'un servidor.
 
### 2.5 Anàlisi estratègica
 
| Dimensió | nginx | Apache |
|---|---|---|
| **Risc de govern** | Depèn d'un proveïdor (F5). La llicència BSD permet *forks*: existeixen Angie i *freenginx* | Govern per fundació; baix risc de canvi unilateral |
| **Risc de llicència** | Baix en la versió oberta | Baix |
| **Maduresa** | Molt alta; referència en proxies inversos | La més alta; present des de 1995 |
| **Cost total de propietat** | Mínim: una imatge base i un paquet | Mínim, lleugerament superior en memòria |
 
### 2.6 Conclusió justificada
**Es manté nginx.** Les raons, ordenades per pes:
 
1. **Funció al prototip:** el que necessitem no és «servir fitxers» sinó **protegir gunicorn** (TLS, autenticació bàsica, redirecció 80→443). nginx fa exactament aquest paper de proxy invers amb menys configuració.
2. **Encaix amb l'arquitectura de contenidors:** un procés lleuger per contenidor i configuració en un sol fitxer versionat a Git (`services/web/nginx.conf`).
3. **Dades de mercat:** continua sent un dels servidors més usats (30,3 %) i el que més pesa en alt trànsit històricament.
4. **Cost i llicència:** igual que Apache (0 €), amb llicència permissiva.
**Quan triaria Apache:** si calgués `.htaccess` per a aplicacions de tercers (p. ex. un CMS en allotjament compartit) o integració amb mòduls específics. No és el cas.
 
### 2.7 Limitacions de l'estudi
- No s'han mesurat rendiments propis (peticions/s). Es farà amb `ab` al sprint 2, dins els criteris de rendiment (RA2).
- Les afirmacions de rendiment relatiu entre nginx i Apache són criteri general, no un resultat.
- La versió de nginx del contenidor no s'ha verificat en aquesta redacció.
---
 
## 3. Monitoratge: Uptime Kuma vs Zabbix
 
### 3.1 Context al projecte
`MON-N06` (10.213.2.20, Intranet) executa **Uptime Kuma v1**, accessible a `http://localhost:3001`. Les sondes es configuren **per IP** perquè el monitor no resolia noms (problema documentat a l'informe de context, §8). Al sprint 2 hi ha d'haver sondes i mètriques de disponibilitat (RA2).
 
### 3.2 Comparativa per criteris
 
| Criteri | Uptime Kuma | Zabbix |
|---|---|---|
| **Enfocament** | **Disponibilitat d'extrem a extrem** (*uptime*), a l'estil de serveis SaaS com Uptime Robot | **Monitoratge d'infraestructura complet**: agents, SNMP, activadors (*triggers*) i plantilles |
| **Tipus de sonda** | HTTP(S), TCP, paraula clau HTTP, ping, registre DNS i *push* | Elements amb agent o sense (sistema, xarxa, aplicacions, VMware, etc.) |
| **Alertes** | Webhook, Telegram, Discord, Slack, Pushover, correu SMTP i més via Apprise | Accions i escalats configurables per activador |
| **Arquitectura** | Aplicació Node.js d'un sol procés; base de dades SQLite (v1) | Servidor, base de dades relacional, frontal web i agents; *proxies* des de la 5.0 |
| **Alta disponibilitat** | No nativa | Clúster HA del servidor des de la 6.0 |
| **Escalabilitat** | SQLite pot ser coll d'ampolla amb molta freqüència de comprovacions; la v2 afegeix MariaDB | Pensat per a grans desplegaments |
| **Llicència** | **MIT** | **AGPLv3** des de la 7.0 (juny 2024); abans GPLv2 |
| **Cicle de vida** | v2.0 publicada el 2025 (imatges Docker *rootless*, MariaDB) | **7.0 LTS**: suport complet fins al 30/06/2027 i limitat fins al 30/06/2029 |
| **Comunitat** | ≈ 85.000 estrelles a GitHub (13/04/2026) | Projecte històric (GPL des del 2001) |
| **Desplegament en contenidor** | Una imatge i un volum: `louislam/uptime-kuma:1` | Diversos components (servidor, BD, web, agent) |
| **Cobertura de Windows** | Sondes remotes (no cal agent) | Agent disponible per a Windows |
| **Pes al projecte (estimació)** | Un contenidor | Entre 3 i 4 contenidors addicionals (no mesurat) |
 
### 3.3 Empreses i projectes darrere de cada tecnologia
 
| Tecnologia | Responsable | Model | Dades rellevants |
|---|---|---|---|
| Uptime Kuma | Projecte comunitari amb un mantenidor principal (Louis Lam); finançament per *sponsors* | Codi obert (MIT); **no hi ha versió gestionada oficial** | MIT i ≈ 85.194 estrelles el 13/04/2026; sense oferta cloud pròpia |
| Zabbix | **Zabbix LLC (SIA Zabbix)**, Riga (Letònia) | Programari lliure; ingressos per **suport, formació i serveis**; hi ha *Zabbix Cloud* (SaaS) | AGPLv3 des del 7.0 |
| Alternatives al mercat | **Datadog**, **Grafana Labs/Prometheus**, **Paessler (PRTG)**, **Nagios** | SaaS de pagament (Datadog); observabilitat oberta (Grafana/Prometheus); llicència comercial (PRTG); híbrid (Nagios) | Vegeu `13-analisi-mercat.md` |
 
### 3.4 Anàlisi estratègica
 
| Dimensió | Uptime Kuma | Zabbix |
|---|---|---|
| **Risc de govern** | Dependència d'un projecte petit; mitigat per la llicència MIT, que permet fer *fork* | Empresa estable; **canvi de llicència a AGPLv3** (juny 2024) que cal conèixer si s'ofereix com a servei |
| **Risc de versió** | Hem desplegat la v1 mentre ja existeix la v2, amb canvis incompatibles (insígnies, còpies, correu); cal ruta de migració | Versió 8.0 LTS planificada per al 3T 2026; **cal verificar si ja ha sortit** |
| **Corba d'aprenentatge** | Baixa: interfície web i assistents | Mitjana-alta: plantilles, macros i activadors |
| **Mètriques de sistema (CPU, RAM, disc)** | No les cobreix; per a això s'usa `docker stats` | Sí, amb agent |
 
### 3.5 Conclusió justificada
**Es manté Uptime Kuma per a P0.0**, per quatre raons:
 
1. **Encaix amb RA2:** el criteri de rendiment i disponibilitat s'ha de definir amb **mètriques mesurables**; *uptime* i temps de resposta per sonda són justament el que mesura Kuma. El temps de recuperació després de `docker kill` es llegirà directament dels seus gràfics.
2. **Cost operatiu mínim:** un sol contenidor amb un volum, coherent amb el principi «un contenidor per servei» i amb `./deploy.sh up`.
3. **Llicència sense restriccions:** MIT.
4. **Proporcionalitat:** muntar Zabbix per vigilar 9 contenidors seria sobredimensionar el projecte (valoració no mesurada).
**Via d'evolució:** si al sprint 3 es vol mesurar consum per servei i generar alertes per llindars de recursos, **Zabbix 7.0 LTS** és el candidat natural (agent per a Linux i Windows, suport fins al 2029). A curt termini, Kuma cobreix la disponibilitat i `docker stats` el consum.
 
### 3.6 Limitacions de l'estudi
- La versió 2 de Kuma **no s'ha provat** en aquest entorn; les dades provenen de premsa tècnica i s'hauran de verificar al repositori oficial.
- La data de publicació de la v2.0 apareix diferent segons la font (2024 en un bloc, 2025 en la premsa); es prenen les dades de la premsa tècnica (vegeu `12-recopilacio-informacio.md`, §6).
- No s'ha mesurat el consum de memòria de Zabbix; la comparació de pes és una estimació.
---
 
## 4. Tallafocs: iptables vs nftables
 
### 4.1 Context al projecte
`R-N06` és un **contenidor Linux** amb `ip_forward` i **iptables**, connectat a les tres xarxes (NAT, DMZ i Intranet). La política és `FORWARD DROP` amb excepcions explícites:
 
- Intranet → DMZ/Internet.
- DMZ → BBDD només per TCP 3306.
- DMZ → DNS (53).
- DNAT cap a web, FTP i SSH.
- `MASQUERADE` a la xarxa NAT.
Les regles són a `services/router/init.sh`.
 
### 4.2 Comparativa per criteris
 
| Criteri | iptables | nftables |
|---|---|---|
| **Projecte** | Component històric de **Netfilter** | Successor dins de Netfilter |
| **Entrada al nucli Linux** | Dècades d'ús | Nucli 3.13 (19/01/2014) |
| **Eines** | `iptables`, `ip6tables`, `arptables`, `ebtables` (una per família) | **Una sola eina `nft`** per a totes les famílies |
| **Compatibilitat** | — | `iptables-translate` converteix regles antigues |
| **Sintaxi** | Una ordre per regla, amb repetició per protocol | Conjunts i mapes, regles agrupades |
| **Estat a les distribucions** | Encara disponible; a **RHEL 9 el *framework* iptables està obsolet**, i el *backend* iptables de firewalld també | Opció recomanada; Ubuntu 24.04 inclou nftables 1.0.9 |
| **Suport de proveïdor** | Red Hat el manté **sense funcions noves** i no el recomana per a desplegaments nous | Recomanat per Red Hat per migrar |
| **Docker (Engine ≤ 28)** | **Backend per defecte** | — |
| **Docker (v29+)** | Segueix per defecte | **Suport experimental** (`--firewall-backend=nftables`); previst com a predeterminat en una versió futura |
| **Contenidor `R-N06`** | Les regles de `init.sh` són d'iptables | Caldria reescriure-les |
 
### 4.3 Empreses i projectes darrere
 
| Actor | Paper |
|---|---|
| **Netfilter Core Team** | Desenvolupa tant iptables com nftables; nftables es va presentar al *Netfilter Workshop 2008* i Pablo Neira Ayuso el va proposar per al nucli el 2012 |
| **Red Hat** | Ha declarat obsolet el *framework* iptables a RHEL 9 |
| **Docker, Inc. / projecte Moby** | Docker Engine v29 afegeix un *backend* nftables experimental i anuncia que serà el predeterminat «en una versió futura» |
| **Canonical** | Distribueix nftables a Ubuntu 24.04 (*noble*) |
 
### 4.4 Anàlisi estratègica
 
| Risc | Impacte | Mitigació |
|---|---|---|
| iptables passa a ser «legacy» a distribucions i a Docker | A mitjà termini caldria reescriure `init.sh` | Eina `iptables-translate` i migració per fases; mantenir les regles aïllades en un sol fitxer |
| Barreja de *backends* al mateix equip | Paquets descartats inesperadament: si Docker usa nftables i hi ha un `FORWARD DROP` d'iptables, aquest descarta paquets que Docker ha acceptat | No barrejar; decidir un únic *backend* per màquina |
| Docker + nftables encara experimental | No és apte per a producció segons la documentació de Docker | No activar-lo al servidor del projecte |
| Canvi de comportament: amb nftables Docker **no activa el reenviament IP** ni crea política de descart per defecte | El router hauria d'activar `ip_forward` per si mateix | El nostre `init.sh` ja ho fa (`sysctl net.ipv4.ip_forward`) |
 
### 4.5 Conclusió justificada
**Es manté iptables a `R-N06` per a P0.0.**
 
1. **Coherència amb Docker:** el *backend* per defecte de Docker és iptables i la documentació oficial està escrita per a ell; en canviar, Docker mateix avisa que el suport nftables és experimental i pot canviar.
2. **Risc controlat:** el router és un contenidor aïllat i la política és curta i llegible, de manera que la reescriptura és factible.
3. **Visibilitat per a la defensa:** les ordres `iptables -S FORWARD` i `iptables -t nat -S` són fàcils d'ensenyar en captures.
4. **Honestedat tècnica:** cal reconèixer que **nftables és la direcció estratègica** (RHEL 9, Docker v29, Ubuntu) i que iptables té un horitzó limitat.
**Pas següent recomanat (fora d'abast de P0.0):** provar la traducció de les regles amb `iptables-translate` en una branca de prova, sense tocar `main`.
 
### 4.6 Limitacions de l'estudi
- No s'ha verificat dins del contenidor si `iptables` usa el *backend* legacy o `nf_tables` (`docker exec R-N06 iptables -V`). Queda com a prova a `12-recopilacio-informacio.md`, §8.
- No s'han comparat rendiments entre tots dos, ja que no és rellevant per al volum de trànsit del projecte.
---
 
## 5. Vies d'evolució
 
| Capa | Ara (P0.0) | Proper pas | Condició per fer-lo |
|---|---|---|---|
| Servidor web | nginx | Mantenir; valorar *forks* (Angie, freenginx) només si F5 canvia les condicions de la versió oberta | Canvi de llicència o de govern |
| Monitoratge | Uptime Kuma v1 | Migrar a Kuma v2 i, si cal, afegir Zabbix 7.0 LTS per a mètriques de recursos | Necessitat de mesurar consum per servei (sprint 3) |
| Tallafocs | iptables | Provar `iptables-translate` en una branca i avaluar nftables | Que el *backend* nftables de Docker deixi de ser experimental |
 
---
 
## 6. Fonts
 
Nivell de fiabilitat: **A** = primària, **B** = secundària, **C** = bloc/premsa. Totes consultades el 21/10/2026. La numeració és compartida amb els documents 12 i 13.
 
### Servidors web
 
- **[1]** W3Techs. *Usage statistics and market share of web servers* (mesura del 19/10/2026). https://w3techs.com/technologies/overview/web_server — **B**
- **[2]** W3Techs. *Usage statistics of Nginx* (mesura del 21/09/2025). https://w3techs.com/technologies/details/ws-nginx — **B**
- **[3]** W3Techs. *Comparison of the usage statistics of Nginx* (28/12/2025). https://w3techs.com/technologies/comparison/ws-nginx — **B**
- **[4]** W3Techs. *Usage statistics of Nginx Version 1* (16/02/2026). https://w3techs.com/technologies/details/ws-nginx/1 — **B**
- **[5]** F5 Networks. *Form 8-K, Exhibit 99.1: F5 acquires NGINX* (11/03/2019). https://www.sec.gov/Archives/edgar/data/1048695/000119312519070884/d713823dex991.htm — **A**
- **[6]** Wikipedia. *Nginx*. https://en.wikipedia.org/wiki/Nginx — **B** (llicència i adquisició; contrastat amb [5])
- **[7]** Wikipedia. *Apache HTTP Server*. https://en.wikipedia.org/wiki/Apache_HTTP_Server — **B** (versió 2.4.69 i llicència; **[VERIFICAR a httpd.apache.org]**)
- **[36]** W3Techs. *Nginx reaches 33.3% web server market share while Apache falls below 50%* (10/04/2017). https://w3techs.com/blog/entry/nginx_reaches_33_3_percent_web_server_market_share_while_apache_falls_below_50_percent — **B**
- **[37]** W3Techs. *Highlights of web technology surveys, September 2010*. https://w3techs.com/blog/entry/highlights_of_web_technology_surveys_september_2010 — **B**
### Monitoratge
 
- **[8]** oosmetrics. *louislam/uptime-kuma* (dades del 13/04/2026). https://oosmetrics.com/repo/louislam/uptime-kuma — **B**
- **[9]** DEV.co. *uptime-kuma* (anàlisi de límits i llicència). https://dev.co/devops/open-source/uptime-kuma — **C**
- **[10]** heise online. *Uptime Kuma 2.0: monitoring tool now with MariaDB support*. https://www.heise.de/en/news/Uptime-Kuma-2-0-Monitoring-tool-now-with-MariaDB-support-10793657.html?view=print — **B**
- **[11]** Linuxiac. *Uptime Kuma 2.0 arrives with MariaDB support, modern UI refresh*. https://linuxiac.com/uptime-kuma-2-0-arrives-with-mariadb-support-modern-ui-refresh/ — **C**
- **[12]** Zabbix. *Life cycle and release policy*. https://www.zabbix.com/life_cycle_and_release_policy — **A**
- **[13]** Zabbix. *True open source* (llicència). https://www.zabbix.com/de/true_open_source — **A**
- **[14]** Wikipedia. *Zabbix*. https://en.wikipedia.org/wiki/Zabbix — **B**
- **[15]** Tecnoblog. *Zabbix prepara lançamento de versão 8.0…* (contingut patrocinat). https://tecnoblog.net/publieditoriais/zabbix-prepara-lancamento-de-versao-8-0-aplicativo-para-celular-e-marketplace/ — **C**
- **[38]** README d'Uptime Kuma (v1), consultat a còpies del repositori original: https://github.com/nunnsby/uptime-kuma i https://github.com/omarx3/uptime-kuma — **C** (**[VERIFICAR a github.com/louislam/uptime-kuma]**)
### Tallafocs
 
- **[16]** Wikipedia. *nftables*. https://en.wikipedia.org/wiki/Nftables — **B**
- **[17]** Launchpad (Ubuntu). *nftables 1.0.9-1build1 source package in Ubuntu*. https://blueprints.launchpad.net/ubuntu/+source/nftables/1.0.9-1build1 — **A**
- **[18]** Red Hat. *RHEL 9 Release Notes — Deprecated functionality*. https://docs.redhat.com/en/documentation/Red_Hat_Enterprise_Linux/9/html/9.0_release_notes/deprecated_functionality — **A**
- **[19]** Red Hat. *The ipset and iptables-nft packages have been deprecated* (KB 6739041). https://access.redhat.com/solutions/6739041 — **A**
- **[20]** Docker Docs. *Docker with nftables*. https://docs.docker.com/engine/network/firewall-nftables/ — **A**
- **[21]** Docker Docs. *Packet filtering and firewalls*. https://docs.docker.com/network/iptables/ — **A**
- **[22]** Docker Blog. *Docker Engine v29: Foundational Updates for the Future*. https://www.docker.com/blog/docker-engine-version-29/ — **A**
