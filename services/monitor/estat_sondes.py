"""Mostra l'últim estat de cada sonda d'Uptime Kuma (MON-N06). Només lectura."""
import os
from datetime import datetime

from uptime_kuma_api import UptimeKumaApi

URL = os.environ.get("KUMA_URL", "http://10.213.2.20:3001")
USUARI = os.environ.get("KUMA_USER", "bchecker")
CLAU = os.environ.get("KUMA_PASS", "bchecker121")
ESTATS = {0: "CAIGUDA (DOWN)", 1: "ACTIU (UP)", 2: "PENDENT", 3: "MANTENIMENT"}


def main():
    api = UptimeKumaApi(URL)
    api.login(USUARI, CLAU)
    print(datetime.now().strftime("%H:%M:%S"), "estat de les sondes")
    for m in api.get_monitors():
        beats = api.get_monitor_beats(m["id"], 1)
        if not beats:
            print("  %-34s sense dades encara" % m["name"])
            continue
        ultim = beats[-1]
        estat = ESTATS.get(int(ultim["status"].value if hasattr(ultim["status"], "value")
                               else ultim["status"]), "?")
        print("  %-34s %-16s %s" % (m["name"], estat, (ultim.get("msg") or "")[:60]))
    api.disconnect()


if __name__ == "__main__":
    main()
