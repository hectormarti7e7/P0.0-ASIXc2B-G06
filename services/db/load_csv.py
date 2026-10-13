#!/usr/bin/env python3
"""Carrega el CSV d'equipaments d'educació (Open Data BCN) a MySQL.

Descarrega CSV_URL; si falla, fa servir CSV_FILE. Les columnes es creen
automàticament a partir de la capçalera, així no depèn d'un esquema fix.
"""
import csv, io, os, re, sys, time, unicodedata, urllib.request
import pymysql

URL = os.environ.get("CSV_URL", "")
LOCAL = os.environ.get("CSV_FILE", "/data/equipaments.csv")
TABLE = os.environ.get("DB_TABLE", "equipaments_educacio")


def get_csv_bytes():
    if URL:
        try:
            req = urllib.request.Request(URL, headers={"User-Agent": "Mozilla/5.0 (P0.0 loader)"})
            with urllib.request.urlopen(req, timeout=60) as r:
                data = r.read()
            print(f"[loader] descarregat {len(data)} bytes de {URL}")
            return data
        except Exception as e:  # noqa: BLE001
            print(f"[loader] no s'ha pogut descarregar ({e})")
    if os.path.isfile(LOCAL):
        print(f"[loader] fent servir fitxer local {LOCAL}")
        with open(LOCAL, "rb") as f:
            return f.read()
    sys.exit("[loader] ERROR: ni descàrrega ni fitxer local. Copia el CSV a ./data/equipaments.csv")


def clean(name, used):
    n = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    n = re.sub(r"[^a-z0-9]+", "_", n.lower()).strip("_") or "col"
    if n[0].isdigit():
        n = "c_" + n
    base, i = n[:60], 2
    n = base
    while n in used:
        n = f"{base}_{i}"
        i += 1
    used.add(n)
    return n


def connect():
    for i in range(60):
        try:
            return pymysql.connect(host=os.environ["DB_HOST"], user=os.environ["DB_USER"],
                                   password=os.environ["DB_PASS"], database=os.environ["DB_NAME"],
                                   charset="utf8mb4", autocommit=False)
        except pymysql.err.OperationalError as e:
            print(f"[loader] esperant la BBDD ({e.args[0]})...")
            time.sleep(3)
    sys.exit("[loader] ERROR: no es pot connectar a la BBDD")


def main():
    text = get_csv_bytes().decode("utf-8-sig", errors="replace")
    try:
        dialect = csv.Sniffer().sniff(text[:8192], delimiters=",;\t|")
    except csv.Error:
        dialect = csv.excel
    reader = csv.reader(io.StringIO(text), dialect)
    header = next(reader)
    used = set()
    cols = [clean(h, used) for h in header]

    db = connect()
    cur = db.cursor()
    cur.execute(f"DROP TABLE IF EXISTS `{TABLE}`")
    ddl = ", ".join(f"`{c}` TEXT" for c in cols)
    cur.execute(f"CREATE TABLE `{TABLE}` (id INT AUTO_INCREMENT PRIMARY KEY, {ddl}) "
                "DEFAULT CHARSET=utf8mb4")
    sql = f"INSERT INTO `{TABLE}` ({', '.join('`'+c+'`' for c in cols)}) VALUES ({', '.join(['%s']*len(cols))})"
    batch, total = [], 0
    for row in reader:
        if not any(row):
            continue
        row = (row + [""] * len(cols))[:len(cols)]
        batch.append(row)
        if len(batch) >= 500:
            cur.executemany(sql, batch); total += len(batch); batch = []
    if batch:
        cur.executemany(sql, batch); total += len(batch)
    db.commit()
    print(f"[loader] taula {TABLE}: {len(cols)} columnes, {total} files carregades")


if __name__ == "__main__":
    main()
