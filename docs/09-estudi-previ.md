# 9. Estudi previ de tecnologies

Tasca ProofHub 2 · Responsable: Josep · Data: 16/10/2026 · RA1

## 9.1 Objectiu i abast

Decidir amb criteris quines tecnologies fem servir per desplegar la infraestructura multicapa de la P0.0
(router, web, BBDD, DNS, DHCP, FTP, SSH i monitor). Es comparen dues decisions:

1. Contenidors o màquines virtuals.
2. MySQL o MariaDB per a la base de dades.

Criteris comuns: complexitat per a un equip de dos estudiants, temps disponible (uns 10 h per persona i sprint),
cost, mida de la comunitat i encaix amb els requisits de l'enunciat.

## 9.2 Contenidors o màquines virtuals

| Criteri | Màquina virtual | Contenidor (Docker) |
| --- | --- | --- |
| Què és | Un sistema operatiu complet amb el seu propi kernel, controladors, programes i aplicacions [1] | Un procés aïllat amb tots els fitxers que necessita per executar-se [1] |
| Kernel | Un per màquina | Compartit entre contenidors [1] |
| Sobrecàrrega | Alta si s'aïlla una sola aplicació [1] | Permet executar més aplicacions amb menys infraestructura [1] |
| Configuració | Es fa dins de cada màquina | Es descriu en fitxers (`Dockerfile`, `docker-compose.yml`) i es versiona amb Git |
| Aïllament | Més fort (cada màquina té el seu kernel) | Més feble (comparteixen kernel) |

L'última fila és coneixement general, no ve de la font [1].

**Conclusió.** Usem contenidors per a tots els serveis. Un contenidor per servei és reproduïble
(`./deploy.sh up`) i la configuració queda al repositori. La pròpia documentació de Docker indica que és habitual
combinar-los: una VM que executa un runtime de contenidors [1]. Aplica al nostre cas: el client Windows no es pot
executar com a contenidor Linux, així que serà una màquina virtual.

Per descriure i arrencar tots els contenidors junts fem servir Docker Compose, que ve amb Docker i no necessita cap eina addicional.

## 9.3 MySQL o MariaDB

| Criteri | MySQL | MariaDB |
| --- | --- | --- |
| Propietari i llicència | Oracle, llicència dual; les funcions de pagament afegeixen thread pool, audit, TDE i firewall [2] | GPLv2; la MariaDB Foundation governa el servidor de codi obert [2] |
| Relació | Original | Dissenyat originalment com a substitut directe de MySQL, amb compatibilitat alta en protocol, fitxers i APIs [3] |
| JSON | Tipus binari natiu [2] | Àlies de `LONGTEXT` amb restriccions `CHECK` [2][3] |
| Autenticació | MySQL 8.4 prefereix `caching_sha2_password` i desactiva `mysql_native_password` per defecte [3] | Admet i sovint usa `mysql_native_password` o `unix_socket` [3] |
| Clúster | Group Replication / InnoDB Cluster [2] | Galera integrat des de la 10.1 [2] |
| Rendiment | Cap és categòricament més ràpid; depèn de càrrega, versió i configuració [2] | Igual; té un thread pool integrat [2] |

**Conclusió.** Usem **MySQL 8.0** (el paquet `mysql-server` d'Ubuntu 22.04; es comprova amb `mysqld --version`). L'enunciat demana MySQL i el protocol
és compatible amb MariaDB, per tant el canvi seria possible més endavant. Un detall real del projecte: com que
l'aplicació Flask es connecta amb PyMySQL sense llibreries addicionals, els usuaris es creen amb
`mysql_native_password`. A MySQL 8.4 aquest mètode està desactivat per defecte [3], així que una actualització
obligaria a revisar-ho.

## 9.4 Empreses i projectes darrere de cada tecnologia

| Tecnologia | Qui hi ha darrere |
| --- | --- |
| Docker Engine i Compose | Docker |
| MySQL | Oracle [2] |
| MariaDB | MariaDB Foundation (servidor) i MariaDB plc (subscripció Enterprise) [2] |

## 9.5 Decisions per al projecte

| Decisió | Triada | Motiu principal |
| --- | --- | --- |
| Virtualització | Contenidors Docker (+ una VM per al client Windows) | Reproduïble, lleuger, configuració versionada |
| Orquestració | Docker Compose | Simple, ve amb Docker i cobreix l'enunciat |
| Base de dades | MySQL 8.0 | Requisit de l'enunciat |

## 9.6 Limitacions d'aquest estudi

- No s'han fet proves de rendiment pròpies; les comparacions de rendiment es basen en les fonts.
- No s'ha comparat nginx, Uptime Kuma ni iptables: això correspon a l'estudi d'Hèctor.

## 9.7 Fonts

1. Docker, «What is a container?» — https://docs.docker.com/get-started/docker-concepts/the-basics/what-is-a-container/
2. MedhaCloud, «MySQL vs MariaDB» — https://medhacloud.com/blog/mysql-vs-mariadb
3. MariaDB, «MySQL to MariaDB compatibility matrix» — https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/migrating-to-mariadb/moving-from-mysql/mysql-to-mariadb-compatibility-matrix

Consultades el 16/10/2026.
