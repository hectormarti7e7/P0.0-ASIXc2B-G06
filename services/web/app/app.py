"""Aplicació web (W-N06): mostra les taules de la base de dades `equipaments` (B-N06).

Només fa consultes de lectura. Els noms de taula i de columna no vénen mai de l'usuari
sense validar: es comproven contra el que diu la base de dades. Els valors de cerca
sempre s'envien com a paràmetres.
"""
import hmac
import os

import pymysql
from flask import Flask, Response, abort, render_template_string, request
from markupsafe import escape
from werkzeug.exceptions import HTTPException

app = Flask(__name__)

DB = dict(
    host=os.environ.get("DB_HOST", "10.213.2.10"),
    user=os.environ.get("DB_USER", "bchecker"),
    password=os.environ.get("DB_PASS", "bchecker121"),
    database=os.environ.get("DB_NAME", "equipaments"),
    charset="utf8mb4",
    connect_timeout=5,
)
PER_PAGINA = 50

# Autenticació HTTP Basic: sense credencials vàlides, 401. Les credencials vénen del compose.
APP_USER = os.environ.get("APP_USER", "bchecker")
APP_PASS = os.environ.get("APP_PASS", "bchecker121")
RUTES_LLIURES = {"/health"}     # no mostra dades; la fa servir el healthcheck del contenidor


@app.before_request
def demana_credencials():
    if request.path in RUTES_LLIURES:
        return None
    auth = request.authorization
    # compare_digest evita deduir la contrasenya pel temps de resposta
    if auth and auth.type == "basic" \
            and hmac.compare_digest((auth.username or "").encode(), APP_USER.encode()) \
            and hmac.compare_digest((auth.password or "").encode(), APP_PASS.encode()):
        return None
    return Response("Cal autenticar-se\n", 401,
                    {"WWW-Authenticate": 'Basic realm="P0.0 N06", charset="UTF-8"'})

PLANTILLA = """<!doctype html>
<html lang="ca"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{ titol }} · P0.0 N06</title>
<style>
 body{font-family:system-ui,sans-serif;margin:0;color:#1f2933;background:#f5f7fa}
 header{background:#243b53;color:#fff;padding:14px 24px}
 header a{color:#fff;text-decoration:none;font-weight:600}
 main{padding:24px;max-width:1400px;margin:auto}
 table{border-collapse:collapse;width:100%;background:#fff;font-size:14px}
 th,td{border:1px solid #d9e2ec;padding:6px 10px;text-align:left;vertical-align:top}
 th{background:#e4ebf2;position:sticky;top:0}
 .tau{overflow-x:auto}
 form{margin:0 0 16px}
 input[type=text]{padding:6px 10px;width:260px}
 button{padding:6px 14px}
 .nav{margin:16px 0}.nav a{margin-right:12px}
 .error{background:#fde8e8;border:1px solid #f5b5b5;padding:12px;border-radius:4px}
</style></head><body>
<header><a href="/">P0.0 · Equipaments</a></header>
<main>
{% if error %}<p class="error">{{ error }}</p>{% else %}{{ cos|safe }}{% endif %}
</main></body></html>"""


def connexio():
    return pymysql.connect(**DB)


def taules(cur):
    cur.execute("SHOW TABLES")
    return [f[0] for f in cur.fetchall()]


def pagina(titol, cos="", error=None, codi=200):
    return render_template_string(PLANTILLA, titol=titol, cos=cos, error=error), codi


def esc(text):
    """Escapa text per posar-lo dins l'HTML que construïm a mà."""
    return str(escape("" if text is None else text))


@app.route("/health")
def health():
    try:
        with connexio() as c, c.cursor() as cur:
            cur.execute("SELECT 1")
        return "ok\n"
    except Exception:
        return "sense connexió amb la base de dades\n", 503


@app.route("/")
def index():
    try:
        with connexio() as c, c.cursor() as cur:
            files = []
            for t in taules(cur):
                cur.execute("SELECT COUNT(*) FROM `%s`" % t.replace("`", "``"))
                files.append((t, cur.fetchone()[0]))
    except Exception as e:
        return pagina("Error", error="No es pot consultar la base de dades: %s" % e, codi=503)
    cos = "<h1>Taules de la base de dades</h1><table><tr><th>Taula</th><th>Files</th></tr>"
    for t, n in files:
        cos += '<tr><td><a href="/taula/%s">%s</a></td><td>%d</td></tr>' % (esc(t), esc(t), n)
    cos += "</table>"
    return pagina("Taules", cos)


@app.route("/taula/<nom>")
def taula(nom):
    q = request.args.get("q", "").strip()
    try:
        pag = max(1, int(request.args.get("p", "1")))
    except ValueError:
        pag = 1
    try:
        with connexio() as c, c.cursor() as cur:
            if nom not in taules(cur):          # el nom només és vàlid si existeix
                abort(404)
            tq = "`%s`" % nom.replace("`", "``")
            cur.execute("SHOW COLUMNS FROM " + tq)
            cols = [f[0] for f in cur.fetchall()]
            onsql, params = "", []
            if q:
                expr = "CONCAT_WS(' ', %s)" % ", ".join("`%s`" % x.replace("`", "``") for x in cols)
                onsql, params = " WHERE " + expr + " LIKE %s", ["%" + q + "%"]
            cur.execute("SELECT COUNT(*) FROM " + tq + onsql, params)
            total = cur.fetchone()[0]
            cur.execute("SELECT * FROM " + tq + onsql + " LIMIT %s OFFSET %s",
                        params + [PER_PAGINA, (pag - 1) * PER_PAGINA])
            files = cur.fetchall()
    except HTTPException:
        raise
    except Exception as e:
        return pagina("Error", error="No es pot consultar la base de dades: %s" % e, codi=503)

    pagines = max(1, -(-total // PER_PAGINA))
    cos = "<h1>%s</h1>" % esc(nom)
    cos += ('<form method="get"><input type="text" name="q" value="%s" placeholder="Cerca...">'
            ' <button>Cerca</button></form>' % esc(q))
    cos += "<p>%d files%s · pàgina %d de %d</p>" % (total, " coincidents" if q else "", pag, pagines)
    cos += '<div class="tau"><table><tr>' + "".join("<th>%s</th>" % esc(x) for x in cols) + "</tr>"
    for f in files:
        cos += "<tr>" + "".join("<td>%s</td>" % esc(v) for v in f) + "</tr>"
    cos += "</table></div>"

    def enllac(p, text):
        return '<a href="/taula/%s?p=%d&q=%s">%s</a>' % (esc(nom), p, esc(q), text)

    cos += '<p class="nav">'
    if pag > 1:
        cos += enllac(pag - 1, "← Anterior")
    if pag < pagines:
        cos += enllac(pag + 1, "Següent →")
    cos += "</p>"
    return pagina(nom, cos)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
