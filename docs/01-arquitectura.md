# 1. Arquitectura

Aplicació multicapa (Web, Monitor, SSH, BBDD, DHCP, DNS i FTP) desplegada amb **contenidors Docker** en lloc d'una màquina virtual per servei. El router és un contenidor Linux amb `ip_forward` i `iptables`, connectat a tres xarxes: DMZ, Intranet i NAT. Tot el trànsit entre xarxes passa pel router.

![Arquitectura de la infraestructura](img/arquitectura-N06.svg)

## Xarxes
- **NAT (10.213.3.0/24):** sortida a Internet i entrada pel port-forwarding del router.
- **DMZ (10.213.1.0/24):** serveis exposats a Internet (web, FTP i SSH).
- **Intranet (10.213.2.0/24):** serveis interns (BBDD, DNS, DHCP, monitor i clients).

## Principi de disseny
Els serveis exposats a Internet viuen a la DMZ i només poden iniciar connexions cap a la BBDD i el DNS. La resta de la intranet queda protegida per les regles del router.
