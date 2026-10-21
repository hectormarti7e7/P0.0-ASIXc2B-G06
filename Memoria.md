| **Projecte** | P0.0 «Desplegament d'infraestructura» — G06 (NCC = N06) |
| **Autor** | Hèctor Marti (MH) |
| **Data** | 26/10/2026 |


## 0. Resum executiu

| Capa | Decisió al prototip | Alternativa estudiada | Motiu principal | Risc identificat |
|---|---|---|---|---|
| Servidor web (W-N06) | **nginx** davant de gunicorn | Apache HTTP Server | Fa de proxy invers i terminació TLS lleuger, encaixa amb un contenidor per servei | Propietari corporatiu únic (F5) i quota en descens lent |
| Monitor (MON-N06) | **Uptime Kuma v1** | Zabbix | Cobreix la disponibilitat (RA2) amb un sol contenidor i cost zero | La v1 ja té successora (v2); no mesura recursos de sistema |
| Tallafocs (R-N06) | **iptables** | nftables | És el *backend* per defecte de Docker i el que usa el repositori | iptables és l'opció «legacy» de Netfilter i les distribucions la van deixant |

**Conclusió en una línia:** les tres decisions es poden justificar amb dades actuals (octubre de 2026), però cadascuna té una *via d'evolució* clara que queda documentada (apartat 6).

---

## 1. Metodologia i criteris

### 1.1 Com s'han triat els criteris
Els criteris de comparació es deriven de **tres fonts**: (a) els requisits de l'enunciat i de la rúbrica P0.0 (seguretat, virtualització, xarxes, rendiment i disponibilitat); (b) el que necessita realment el prototip (un contenidor per servei, tot a una sola VM, desplegament amb `./deploy.sh up`); i (c) criteris estratègics habituals en una selecció de tecnologia (llicència, govern del projecte, cicle de vida, quota de mercat, risc de dependència d'un proveïdor).

### 1.2 Marca de «coneixement general»
**(CG)** = *coneixement general, no verificat en una font concreta*. Es posa a qualsevol afirmació que no he pogut contrastar amb una font de la llista. Hauria de poder-se defensar oralment, però no s'ha d'usar com a prova.

---

## 2. Servidor web: nginx vs Apache HTTP Server

### 2.1 Context al projecte
`W-N06` (10.213.1.10, DMZ) serveix una aplicació **Flask executada per gunicorn**, amb **nginx** al davant fent HTTPS autofirmat i autenticació bàsica. La pregunta d'enginyeria és: podria fer-ho igualment Apache, i per què hem triat nginx?*

### 2.2 Taula comparativa per criteris

| Criteri | nginx | Apache HTTP Server | Font |
|---|---|---|---|
| **Origen** | Creat per Igor Sysoev (2004) per al portal rus Rambler | Projecte iniciat el 1995 a partir de NCSA HTTPd | [37] [7] |
| **Qui el governa** | Empresa NGINX Inc., adquirida per **F5** el març de 2019 per uns **670 M$** | Projecte de l'**Apache Software Foundation** (comunitat de desenvolupadors) | [5] [7] |
| **Llicència** | BSD de 2 clàusules (versió oberta); *NGINX Plus* és propietari | Apache License 2.0 | [6] [7] |
| **Versió estable de referència** | Verificar al contenidor: `docker exec W-N06 nginx -v` | 2.4.69 (1/10/2026) | [7] |
| **Quota de mercat (oct. 2026)** | **30,3 %** dels llocs amb servidor conegut | **21,4 %** | [1] |
| **Model d'execució** | Arquitectura orientada a esdeveniments, poques processes (CG) | Diversos MPM: asíncron (*event*), amb fils (*worker*) i per processos (*prefork*) | [7] |
| **Configuració** | Un únic arbre de fitxers central; no hi ha `.htaccess` (CG) | Admet `.htaccess` per directori, útil en allotjament compartit (CG) | — |
| **Contingut dinàmic** | No incrusta intèrprets: delega a una aplicació externa via `proxy_pass`/FastCGI (CG) | Pot incrustar mòduls (p. ex. `mod_wsgi`) o fer de proxy (CG) | — |
| **Encaix amb Flask + gunicorn** | gunicorn és un servidor WSGI i no s'ha d'exposar directament a Internet; nginx fa de proxy invers, serveix estàtics i acaba TLS (CG) | Possible amb `mod_proxy`; funcionalment equivalent però més pesat en un contenidor (CG) | — |
| **Cost de llicència** | 0 € (versió oberta) | 0 € | [6] [7] |
| **Autenticació bàsica + HTTPS** | Sí (usat al prototip, validat per `tests/check.sh`) | Sí | Informe de context §3 |

### 2.3 Empreses i projectes darrere de cada tecnologia

| Tecnologia | Empresa / entitat | Model de negoci | Dades verificades |
|---|---|---|---|
| nginx | **F5, Inc.** (EUA, NASDAQ: FFIV) | Ven *NGINX Plus* i serveis d'entrega d'aplicacions; el nucli és obert | Compra anunciada l'11/03/2019, valor d'empresa ≈ 670 M$; F5 es va comprometre a augmentar la inversió en el projecte obert [5] |
| Apache httpd | **Apache Software Foundation** | Fundació sense ànim de lucre; finançament per patrocini (CG) | Llicència Apache 2.0 des del 2004 [7] |
| Alternatives presents al mercat | **Cloudflare**, **LiteSpeed Technologies**, **Caddy** | Servei de CDN/proxy (Cloudflare), servidor comercial i obert (LiteSpeed), servidor obert (Caddy) | Quotes al [1]: Cloudflare Server 32,5 %, LiteSpeed 14,0 %, Caddy 1,1 % |

### 2.4 Quota de mercat i tendència (dades reals, W3Techs)

| Data de la mesura | Quota de nginx | Font |
|---|---|---|
| 21/09/2025 | 33,3 % | [2] |
| 28/12/2025 | 33,2 % | [3] |
| 16/02/2026 | 32,8 % | [4] |
| **19/10/2026** | **30,3 %** | [1] |

Apache està al **21,4 %** el 19/10/2026 [1]. Per context històric, el 2010 Apache tenia el 71,5 % i el 2017 va caure per sota del 50 % [36]. El 22/09/2026 W3Techs va destacar que el «Cloudflare Server» ha passat nginx com a servidor més usat [1].

**Lectura:** nginx i Apache van perdent quota davant de serveis gestionats (CDN i proxies de núvol). Això no afecta el nostre cas, perquè el prototip és **autoallotjat**; indica, però, que la «quota» no és un criteri decisiu per si sol. *Nota metodològica: W3Techs només mesura llocs web públics i un lloc pot usar més d'un servidor [1].*

### 2.5 Anàlisi estratègica

| Dimensió | nginx | Apache |
|---|---|---|
| **Risc de govern** | Depèn d'un proveïdor (F5). La llicència BSD permet *forks*: existeix Angie (llistat per W3Techs) [1] i *freenginx* (CG) | Govern per fundació; baix risc de canvi unilateral (CG) |
| **Risc de llicència** | Baix en la versió oberta [6] | Baix [7] |
| **Maduresa** | Molt alta; referència en proxies inversos (CG) | La més alta; present des de 1995 [7] |
| **Cost total de propietat al projecte** | Mínim: una imatge base + un paquet | Mínim, lleugerament superior en memòria (CG) |

### 2.6 Conclusió justificada
**Es manté nginx.** Les raons, ordenades per pes:
1. **Funció al prototip:** el que necessitem no és «servir fitxers» sinó **protegir gunicorn** (TLS, autenticació bàsica, redirecció 80→443). nginx fa exactament aquest paper de proxy invers amb menys configuració (CG).
2. **Encaix amb l'arquitectura de contenidors:** un procés lleuger per contenidor, configuració en un sol fitxer versionat a Git (`services/web/nginx.conf`).
3. **Dades de mercat:** continua sent el segon servidor més usat (30,3 %) i el que més pesa en alt trànsit històricament [1] [36].
4. **Cost i llicència:** igual que Apache (0 €), amb llicència permissiva [6].

**Quan triaria Apache:** si calgués `.htaccess` per aplicacions de tercers (p. ex. un CMS en allotjament compartit) o integració amb mòduls específics (CG). No és el cas.

### 2.7 Limitacions de l'estudi
- No s'han mesurat rendiments propis (peticions/s). Es farà amb `ab` al sprint 2 dins els criteris de rendiment (RA2).
- Les afirmacions de rendiment relatiu entre nginx i Apache són (CG); no es presenten com a resultat.
- La versió de nginx del contenidor no s'ha verificat en aquesta redacció.

---

## 3. Monitoratge: Uptime Kuma vs Zabbix

### 3.1 Context al projecte
`MON-N06` (10.213.2.20, Intranet) executa **Uptime Kuma v1**, accessible a `http://localhost:3001`. Les sondes es configuren **per IP** perquè el monitor no resolia noms (problema documentat a l'informe de context, §8). Al sprint 2 hi ha d'haver sondes i mètriques de disponibilitat (RA2).

### 3.2 Taula comparativa per criteris

| Criteri | Uptime Kuma | Zabbix | Font |
|---|---|---|---|
| **Enfocament** | **Disponibilitat d'extrem a extrem** (*uptime*), a l'estil de serveis SaaS com Uptime Robot | **Monitoratge d'infraestructura complet**: agents, SNMP, activadors (*triggers*), plantilles | [38] [14] |
| **Tipus de sonda** | HTTP(S), TCP, paraula clau HTTP, ping, registre DNS, *push* | Elements amb agent o sense (sistema, xarxa, aplicacions, VMware, etc.) | [38] [14] |
| **Alertes** | Webhook, Telegram, Discord, Slack, Pushover, correu SMTP i més via Apprise | Accions i escalats configurables per activador | [38] [14] |
| **Arquitectura** | Aplicació Node.js d'un sol procés; base de dades SQLite (v1) | Servidor + base de dades relacional + frontal web + agents; *proxies* des de la 5.0 | [8] [14] |
| **Alta disponibilitat** | No nativa | Clúster HA del servidor des de la 6.0 | [14] |
| **Escalabilitat** | SQLite pot ser coll d'ampolla amb molta freqüència de comprovacions; la v2 afegeix MariaDB | Pensat per a grans desplegaments | [9] [10] |
| **Llicència** | **MIT** | **AGPLv3** des de la 7.0 (juny 2024); abans GPLv2 | [8] [13] |
| **Cicle de vida** | v2.0 publicada el 2025 (imatges Docker *rootless*, MariaDB) | **7.0 LTS**: suport complet fins al 30/06/2027, limitat fins al 30/06/2029 | [10] [11] [12] |
| **Comunitat** | ≈ 85.000 estrelles a GitHub (13/04/2026) | Projecte històric (GPL des del 2001) | [8] [13] |
| **Desplegament en contenidor** | Una imatge i un volum: `louislam/uptime-kuma:1` | Diversos components (servidor, BD, web, agent) | [38] [14] |
| **Cobertura de Windows** | Sondes remotes (no cal agent) | Agent disponible per a Windows | [14] |
| **Pes al projecte (estimació)** | Un contenidor | Entre 3 i 4 contenidors addicionals (CG, no mesurat) | — |

### 3.3 Empreses i projectes darrere de cada tecnologia

| Tecnologia | Responsable | Model | Dades verificades |
|---|---|---|---|
| Uptime Kuma | Projecte comunitari amb un mantenidor principal (Louis Lam, CG); finançament per *sponsors* | Codi obert (MIT); **no hi ha versió gestionada oficial** | MIT i ≈ 85.194 estrelles el 13/04/2026 [8]; sense oferta cloud pròpia [9] |
| Zabbix | **Zabbix LLC (SIA Zabbix)**, Riga (Letònia) | Programari lliure; ingressos per **suport, formació i serveis**; hi ha *Zabbix Cloud* (SaaS) | AGPLv3 des del 7.0 [13] [14]; SaaS mencionat en contingut patrocinat [15] |
| Alternatives al mercat | **Datadog**, **Grafana Labs/Prometheus**, **Paessler (PRTG)**, **Nagios** | SaaS de pagament (Datadog); observabilitat oberta (Grafana/Prometheus); llicència comercial (PRTG); híbrid (Nagios) | Vegeu `13-analisi-mercat.md` |

### 3.4 Anàlisi estratègica

| Dimensió | Uptime Kuma | Zabbix |
|---|---|---|
| **Risc de govern** | Dependència d'un projecte petit; mitigat per llicència MIT que permet fer *fork* (CG) | Empresa estable; **canvi de llicència a AGPLv3** (juny 2024) que cal conèixer si s'ofereix com a servei [13] |
| **Risc de versió** | Hem desplegat la v1 mentre ja existeix la v2 amb canvis incompatibles (insígnies, còpies, correu); cal ruta de migració [10] [11] | Versió 8.0 LTS planificada per al 3T 2026; **cal verificar si ja ha sortit** [12] [15] |
| **Corba d'aprenentatge** | Baixa: interfície web, assistents | Mitjana-alta: plantilles, macros, activadors (CG) |
| **Mètriques de sistema (CPU, RAM, disc)** | No les cobreix; per a això s'usa `docker stats` | Sí, amb agent (CG) |

### 3.5 Conclusió justificada
**Es manté Uptime Kuma per a P0.0**, per quatre raons:
1. **Encaix amb RA2:** el criteri de rendiment i disponibilitat s'ha de definir amb **mètriques mesurables**; *uptime* i temps de resposta per sonda són justament el que mesura Kuma. El temps de recuperació després de `docker kill` es llegirà directament dels seus gràfics.
2. **Cost operatiu mínim:** un sol contenidor amb un volum, coherent amb el principi «un contenidor per servei» i amb `./deploy.sh up`.
3. **Llicència sense restriccions:** MIT [8].
4. **Proporcionalitat:** muntar Zabbix per vigilar 9 contenidors seria sobredimensionar el projecte (CG, no mesurat).

**Via d'evolució:** si al sprint 3 es vol mesurar consum per servei i generar alertes per llindars de recursos, **Zabbix 7.0 LTS** és el candidat natural (agent per a Linux i Windows, cicle de suport fins al 2029) [12] [14]. A curt termini, Kuma cobreix la disponibilitat i `docker stats` el consum.

### 3.6 Limitacions de l'estudi
- La versió 2 de Kuma **no s'ha provat** en aquest entorn; les dades provenen de premsa tècnica [10] [11] i hauran de verificar-se al repositori oficial.
- La data de publicació de la v2.0 apareix diferent segons la font (2024 en un bloc; 2025 en la premsa); es prenen les dades de la premsa tècnica (veure `12-recopilacio-informacio.md`, §6).
- No s'ha mesurat el consum de memòria de Zabbix; la comparació de pes és una estimació.

---

## 4. Tallafocs: iptables vs nftables

### 4.1 Context al projecte
`R-N06` és un **contenidor Linux** amb `ip_forward` i **iptables**, connectat a les tres xarxes (NAT, DMZ, Intranet). Política: `FORWARD DROP` amb excepcions explícites (Intranet→DMZ/Internet; DMZ→BBDD només TCP 3306; DMZ→DNS 53; DNAT cap a web, FTP i SSH; `MASQUERADE` a la xarxa NAT). Les regles són a `services/router/init.sh`.

### 4.2 Taula comparativa per criteris

| Criteri | iptables | nftables | Font |
|---|---|---|---|
| **Projecte** | Component històric de **Netfilter** | Successor dins de Netfilter | [16] |
| **Entrada al nucli Linux** | Dècades d'ús | Nucli 3.13 (19/01/2014) | [16] |
| **Eines** | `iptables`, `ip6tables`, `arptables`, `ebtables` (una per família) | **Una sola eina `nft`** per a totes les famílies | [16] [17] |
| **Compatibilitat** | — | `iptables-translate` converteix regles antigues | [16] |
| **Sintaxi** | Una ordre per regla, repetició per protocol | Conjunts i mapes, regles agrupades (CG) | — |
| **Estat a les distribucions** | Encara disponible; a **RHEL 9 l'*framework* iptables està obsolet**, i el *backend* iptables de firewalld també | Recomanada com a opció nova; Ubuntu 24.04 inclou nftables 1.0.9 | [18] [17] |
| **Suport de proveïdor** | Red Hat el manté però **sense funcions noves** i sense recomanar-lo per a desplegaments nous | Recomanat per Red Hat per migrar | [19] |
| **Docker (Engine ≤ 28)** | **Backend per defecte** | — | [21] |
| **Docker (v29+)** | Segueix per defecte | **Suport experimental** (`--firewall-backend=nftables`); previst fer-lo per defecte en una versió futura | [20] [22] |
| **Contenidor `R-N06`** | Les regles de `init.sh` són d'iptables | Reescriptura necessària | Informe de context §3 |

### 4.3 Empreses i projectes darrere

| Actor | Paper | Dades |
|---|---|---|
| **Netfilter Core Team** | Desenvolupa tant iptables com nftables; nftables va ser presentat públicament al *Netfilter Workshop 2008* i proposat per a l'inclusió al nucli el 2012 per Pablo Neira Ayuso | [16] |
| **Red Hat** | Ha declarat obsolet el *framework* iptables a RHEL 9 | [18] [19] |
| **Docker, Inc. / projecte Moby** | Docker Engine v29 afegeix un *backend* nftables experimental, i anuncia que «en una versió futura» serà el predeterminat | [20] [22] |
| **Canonical** | Distribueix nftables a Ubuntu 24.04 (*noble*) | [17] |

### 4.4 Anàlisi estratègica

| Risc | Impacte | Mitigació |
|---|---|---|
| iptables passa a ser «legacy» a distribucions i a Docker | A mitjà termini caldria reescriure `init.sh` | Eina `iptables-translate` i migració per fases [16]; mantenir les regles aïllades a un sol fitxer |
| Barreja de *backends* al mateix equip | Paquets descartats inesperadament: si Docker usa nftables i hi ha un `FORWARD DROP` d'iptables, aquest descarta paquets que Docker ha acceptat [20] | No barrejar; decidir un únic *backend* per màquina |
| Docker + nftables encara experimental | No és apte per a producció segons la pròpia documentació [20] | No activar-lo al servidor del projecte |
| Canvi de comportament: amb nftables Docker **no activa el reenviament IP** ni crea política de descart per defecte [20] | El router hauria d'activar `ip_forward` per si mateix | El nostre `init.sh` ja ho fa (`sysctl net.ipv4.ip_forward`) |

### 4.5 Conclusió justificada
**Es manté iptables a `R-N06` per a P0.0.**
1. **Coherència amb Docker:** el *backend* per defecte de Docker és iptables i la documentació oficial està escrita per a ell [21]; en canviar, Docker mateix avisa que el suport nftables és experimental i que pot canviar [20].
2. **Risc controlat:** el nostre router és un contenidor aïllat i la seva política és curta i llegible; la reescriptura és factible (CG).
3. **Visibilitat per a la defensa:** les regles `iptables -S FORWARD` i `iptables -t nat -S` són fàcils d'ensenyar en captures.
4. **Honestedat tècnica:** cal reconèixer que **nftables és la direcció estratègica** (RHEL 9, Docker v29, Ubuntu inclou el paquet) [18] [20] [17] i que iptables té un horitzó limitat.

**Pas següent recomanat (fora d'abast de P0.0):** provar la traducció de les regles amb `iptables-translate` en una rama de prova, sense tocar `main`.

### 4.6 Limitacions de l'estudi
- No s'ha verificat dins del contenidor si `iptables` usa el *backend* legacy o `nf_tables` (`docker exec R-N06 iptables -V`). Queda com a prova a `12-recopilacio-informacio.md`, §8.
- No s'han comparat rendiments entre tots dos (no és rellevant per al volum de trànsit del projecte).

---

## 5. Fonts

> **Numeració compartida amb els documents 12 i 13.** Aquí només es llisten les fonts usades en aquest document. Nivell de fiabilitat: A = primària, B = secundària, C = bloc/premsa. Totes consultades el **21/10/2026**.

**Servidors web**

- **[1]** W3Techs. *Usage statistics and market share of web servers* (mesura del 19/10/2026). https://w3techs.com/technologies/overview/web_server — **B**
- **[2]** W3Techs. *Usage statistics of Nginx* (mesura del 21/09/2025). https://w3techs.com/technologies/details/ws-nginx — **B**
- **[3]** W3Techs. *Comparison of the usage statistics of Nginx* (28/12/2025). https://w3techs.com/technologies/comparison/ws-nginx — **B**
- **[4]** W3Techs. *Usage statistics of Nginx Version 1* (16/02/2026). https://w3techs.com/technologies/details/ws-nginx/1 — **B**
- **[5]** F5 Networks. *Form 8-K, Exhibit 99.1: F5 acquires NGINX* (11/03/2019). https://www.sec.gov/Archives/edgar/data/1048695/000119312519070884/d713823dex991.htm — **A**
- **[6]** Wikipedia. *Nginx*. https://en.wikipedia.org/wiki/Nginx — **B** (llicència i adquisició; contrastat amb [5])
- **[7]** Wikipedia. *Apache HTTP Server*. https://en.wikipedia.org/wiki/Apache_HTTP_Server — **B** (versió 2.4.69 i llicència; **[VERIFICAR a httpd.apache.org]**)
- **[36]** W3Techs. *Nginx reaches 33.3% web server market share while Apache falls below 50%* (10/04/2017). https://w3techs.com/blog/entry/nginx_reaches_33_3_percent_web_server_market_share_while_apache_falls_below_50_percent — **B**
- **[37]** W3Techs. *Highlights of web technology surveys, September 2010*. https://w3techs.com/blog/entry/highlights_of_web_technology_surveys_september_2010 — **B**

**Monitoratge**

- **[8]** oosmetrics. *louislam/uptime-kuma* (dades del 13/04/2026). https://oosmetrics.com/repo/louislam/uptime-kuma — **B**
- **[9]** DEV.co. *uptime-kuma* (anàlisi de límits i llicència). https://dev.co/devops/open-source/uptime-kuma — **C**
- **[10]** heise online. *Uptime Kuma 2.0: monitoring tool now with MariaDB support*. https://www.heise.de/en/news/Uptime-Kuma-2-0-Monitoring-tool-now-with-MariaDB-support-10793657.html?view=print — **B**
- **[11]** Linuxiac. *Uptime Kuma 2.0 arrives with MariaDB support, modern UI refresh*. https://linuxiac.com/uptime-kuma-2-0-arrives-with-mariadb-support-modern-ui-refresh/ — **C**
- **[12]** Zabbix. *Life cycle and release policy*. https://www.zabbix.com/life_cycle_and_release_policy — **A**
- **[13]** Zabbix. *True open source* (llicència). https://www.zabbix.com/de/true_open_source — **A**
- **[14]** Wikipedia. *Zabbix*. https://en.wikipedia.org/wiki/Zabbix — **B**
- **[15]** Tecnoblog. *Zabbix prepara lançamento de versão 8.0…* (contingut patrocinat). https://tecnoblog.net/publieditoriais/zabbix-prepara-lancamento-de-versao-8-0-aplicativo-para-celular-e-marketplace/ — **C**
- **[38]** README d'Uptime Kuma (v1), consultat a còpies del repositori original: https://github.com/nunnsby/uptime-kuma i https://github.com/omarx3/uptime-kuma — **C** (**[VERIFICAR a github.com/louislam/uptime-kuma]**)

**Tallafocs**

- **[16]** Wikipedia. *nftables*. https://en.wikipedia.org/wiki/Nftables — **B**
- **[17]** Launchpad (Ubuntu). *nftables 1.0.9-1build1 source package in Ubuntu*. https://blueprints.launchpad.net/ubuntu/+source/nftables/1.0.9-1build1 — **A**
- **[18]** Red Hat. *RHEL 9 Release Notes — Deprecated functionality*. https://docs.redhat.com/en/documentation/Red_Hat_Enterprise_Linux/9/html/9.0_release_notes/deprecated_functionality — **A**
- **[19]** Red Hat. *The ipset and iptables-nft packages have been deprecated* (KB 6739041). https://access.redhat.com/solutions/6739041 — **A**
- **[20]** Docker Docs. *Docker with nftables*. https://docs.docker.com/engine/network/firewall-nftables/ — **A**
- **[21]** Docker Docs. *Packet filtering and firewalls*. https://docs.docker.com/network/iptables/ — **A**
- **[22]** Docker Blog. *Docker Engine v29: Foundational Updates for the Future*. https://www.docker.com/blog/docker-engine-version-29/ — **A**

