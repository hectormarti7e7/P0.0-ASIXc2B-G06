#!/usr/bin/env python3
"""Carrega el CSV d'equipaments d'educació (Open Data BCN) a MySQL.

S'executa dins del contenidor B-N06 (vegeu docs/05-carrega-csv.md):
    docker exec B-N06 python3 /opt/load_csv.py

Descarrega CSV_URL; si falla, fa servir el fitxer local CSV_FILE. Les columnes
es creen a partir de la capçalera, així no depèn d'un esquema fix. La càrrega
es pot repetir: la taula es torna a crear cada vegada.
"""
import csv
import io
import os
import re
import sys
import time
import unicodedata
import urllib.request

import pymysql

DEFAULT_URL = ("https://opendata-ajuntament.barcelona.cat/data/dataset/"
               "f36b60f2-9541-4d08-b0f9-b0a9313fab3d/resource/"
               "29d9ff10-6892-4f16-9012-d5c4997857e7/download")

URL = os.environ.get("CSV_URL", DEFAULT_URL)
LOCAL = os.environ.get("CSV_FILE", "/data/equipaments.csv")
TABLE = os.environ.get("DB_TABLE", "equipaments_educacio")


def get_csv_bytes():
    """Retorna el CSV descarregat o, si no es pot, el fitxer local."""
    if URL:
        try:
            req = urllib.request.Request(URL, headers={"User-Agent": "Mozilla/5.0 (P0.0 loader)"})
            with urllib.request.urlopen(req, timeout=60) as r:
                data = r.read()
            print(f"[loader] descarregats {len(data)} bytes de la URL")
            return data
        except Exception as e:  # noqa: BLE001
            print(f"[loader] no s'ha pogut descarregar ({e})")
    if os.path.isfile(LOCAL):
        print(f"[loader] fent servir el fitxer local {LOCAL}")
        with open(LOCAL, "rb") as f:
            return f.read()
    sys.exit(f"[loader] ERROR: ni descàrrega ni fitxer local. Copia el CSV a {LOCAL}")


def decode_text(raw):
    """Descodifica UTF-16, UTF-8 (amb o sense BOM) o, si no és UTF-8 vàlid, Windows-1252.

    El CSV d'Open Data BCN no sempre ve en UTF-8. Si es descodifica com a UTF-8 amb
    errors="replace", les lletres amb accent es perden (apareixen com a «�»).
    """
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        print("[loader] codificació detectada: UTF-16")
        return raw.decode("utf-16", errors="replace")
    if b"\x00" in raw[:4096]:
        enc = "utf-16-le" if raw[1:2] == b"\x00" else "utf-16-be"
        print(f"[loader] codificació detectada: {enc}")
        return raw.decode(enc, errors="replace")
    try:
        text = raw.decode("utf-8-sig")
        print("[loader] codificació detectada: UTF-8")
        return text
    except UnicodeDecodeError:
        print("[loader] codificació detectada: Windows-1252 (no és UTF-8 vàlid)")
        return raw.decode("cp1252", errors="replace")


def clean(name, used):
    """Converteix un nom de columna del CSV en un nom SQL segur i únic."""
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
    """Es connecta a MySQL, esperant que estigui a punt."""
    for _ in range(60):
        try:
            return pymysql.connect(host=os.environ.get("DB_HOST", "127.0.0.1"),
                                   user=os.environ["DB_USER"],
                                   password=os.environ["DB_PASS"],
                                   database=os.environ["DB_NAME"],
                                   charset="utf8mb4", autocommit=False)
        except pymysql.err.OperationalError as e:
            print(f"[loader] esperant la BBDD ({e.args[0]})...")
            time.sleep(3)
    sys.exit("[loader] ERROR: no es pot connectar a la BBDD")


def main():
    # Es treuen els bytes nuls i els BOM (U+FEFF) que el CSV porta dins de les dades:
    # sense això el primer camp de cada fila (register_id) comença amb un caràcter invisible
    text = decode_text(get_csv_bytes()).replace("\x00", "").replace(chr(0xFEFF), "")
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
    sql = (f"INSERT INTO `{TABLE}` ({', '.join('`' + c + '`' for c in cols)}) "
           f"VALUES ({', '.join(['%s'] * len(cols))})")
    batch, total = [], 0
    for row in reader:
        if not any(row):
            continue
        row = (row + [""] * len(cols))[:len(cols)]
        batch.append(row)
        if len(batch) >= 500:
            cur.executemany(sql, batch)
            total += len(batch)
            batch = []
    if batch:
        cur.executemany(sql, batch)
        total += len(batch)
    db.commit()
    print(f"[loader] taula {TABLE}: {len(cols)} columnes, {total} files carregades")


if __name__ == "__main__":
    main()
