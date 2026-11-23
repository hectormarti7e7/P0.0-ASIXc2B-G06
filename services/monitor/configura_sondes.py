"""Configura Uptime Kuma (MON-N06): crea l'administrador i les sondes dels serveis.

Es pot executar més d'una vegada: només crea el que no existeix. S'executa des d'un
contenidor temporal (vegeu docs/26-monitoritzacio.md); necessita `uptime-kuma-api`.
"""
import os

from uptime_kuma_api import AuthMethod, MonitorType, UptimeKumaApi

URL = os.environ.get("KUMA_URL", "http://10.213.2.20:3001")
USUARI = os.environ.get("KUMA_USER", "bchecker")
CLAU = os.environ.get("KUMA_PASS", "bchecker121")

# Interval curt (20 s) i un sol reintent: una caiguda es detecta en menys d'un minut
COMU = dict(interval=20, retryInterval=20, maxretries=1)

SONDES = [
    dict(name="Web W-N06 (HTTPS)", type=MonitorType.HTTP, url="https://10.213.1.10/",
         ignoreTls=True, authMethod=AuthMethod.HTTP_BASIC,
         basic_auth_user=USUARI, basic_auth_pass=CLAU, **COMU),
    dict(name="FTP F-N06 (port 21)", type=MonitorType.PORT,
         hostname="10.213.1.11", port=21, **COMU),
    dict(name="SSH S-N06 (port 2222)", type=MonitorType.PORT,
         hostname="10.213.1.12", port=2222, **COMU),
    dict(name="MySQL B-N06 (consulta)", type=MonitorType.MYSQL,
         databaseConnectionString="mysql://bchecker:bchecker121@10.213.2.10:3306/equipaments",
         databaseQuery="SELECT COUNT(*) FROM equipaments_educacio", **COMU),
    dict(name="DNS DNS-N06 (b-n06.asix.local)", type=MonitorType.DNS,
         hostname="b-n06.asix.local", dns_resolve_server="10.213.2.53",
         dns_resolve_type="A", port=53, **COMU),
]


def main():
    api = UptimeKumaApi(URL)
    try:
        api.setup(USUARI, CLAU)            # només la primera vegada
        print("Administrador creat:", USUARI)
    except Exception as e:                 # ja existeix: continuem amb el login
        print("L'administrador ja existia (%s)" % type(e).__name__)
    api.login(USUARI, CLAU)

    existents = {m["name"] for m in api.get_monitors()}
    for s in SONDES:
        if s["name"] in existents:
            print("Ja existeix:", s["name"])
            continue
        api.add_monitor(**s)
        print("Creada:", s["name"])
    api.disconnect()


if __name__ == "__main__":
    main()
