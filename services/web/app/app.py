"""Aplicació de prova: mostra el contingut de les taules carregades a la BBDD."""
import os
import pymysql
from flask import Flask, Response, abort, jsonify, render_template_string, request

app = Flask(__name__)
PAGE = 50

AUTH = os.environ.get("APP_AUTH", "true").lower() == "true"
AUTH_USER = os.environ.get("APP_USER", "bchecker")
AUTH_PASS = os.environ.get("APP_PASS", "bchecker121")


def db():
    return pymysql.connect(
        host=os.environ.get("DB_HOST", "B-N01"), user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"], database=os.environ["DB_NAME"],
        charset="utf8mb4", cursorclass=pymysql.cursors.DictCursor, connect_timeout=5)


def table_names(cur):
    cur.execute("SHOW TABLES")
    return [list(r.values())[0] for r in cur.fetchall()]


@app.before_request
def require_auth():
    if not AUTH or request.path == "/health":
        return None
    a = request.authorization
    if a and a.username == AUTH_USER and a.password == AUTH_PASS:
        return None
    return Response("Cal autenticar-se", 401, {"WWW-Authenticate": 'Basic realm="P0.0"'})


@app.route("/health")
def health():
    try:
        with db() as c, c.cursor() as cur:
            cur.execute("SELECT 1")
        return jsonify(status="ok", db="ok")
    except Exception as e:  # noqa: BLE001
        return jsonify(status="error", detail=str(e)), 503


INDEX = """<!doctype html><meta charset=utf-8><title>P0.0 - {{host}}</title>
<style>body{font:15px system-ui;margin:2rem auto;max-width:60rem;padding:0 1rem}
table{border-collapse:collapse;width:100%}td,th{border:1px solid #ccc;padding:4px 8px;text-align:left}
th{background:#f3f3f3}</style>
<h1>Taules a la BBDD <small>(servit per {{host}})</small></h1>
<ul>{% for t,n in tables %}<li><a href="/t/{{t}}">{{t}}</a> — {{n}} files · <a href="/api/{{t}}">JSON</a></li>{% endfor %}</ul>"""

TABLE = """<!doctype html><meta charset=utf-8><title>{{name}}</title>
<style>body{font:14px system-ui;margin:1.5rem}table{border-collapse:collapse}
td,th{border:1px solid #ccc;padding:3px 6px;text-align:left;max-width:22rem;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
th{background:#f3f3f3;position:sticky;top:0}</style>
<h1><a href="/">&larr;</a> {{name}} <small>({{total}} files)</small></h1>
<p>{% if page>0 %}<a href="?page={{page-1}}">&laquo; anterior</a>{% endif %}
 pàgina {{page+1}} {% if (page+1)*size < total %}<a href="?page={{page+1}}">següent &raquo;</a>{% endif %}</p>
<table><tr>{% for c in cols %}<th>{{c}}</th>{% endfor %}</tr>
{% for r in rows %}<tr>{% for c in cols %}<td>{{r[c]}}</td>{% endfor %}</tr>{% endfor %}</table>"""


@app.route("/")
def index():
    with db() as conn, conn.cursor() as cur:
        out = []
        for t in table_names(cur):
            cur.execute(f"SELECT COUNT(*) AS n FROM `{t}`")
            out.append((t, cur.fetchone()["n"]))
    return render_template_string(INDEX, tables=out, host=os.uname().nodename)


def fetch(name, limit, offset):
    with db() as conn, conn.cursor() as cur:
        if name not in table_names(cur):      # llista blanca: evita SQL injection
            abort(404)
        cur.execute(f"SELECT COUNT(*) AS n FROM `{name}`")
        total = cur.fetchone()["n"]
        cur.execute(f"SELECT * FROM `{name}` ORDER BY 1 LIMIT %s OFFSET %s", (limit, offset))
        return total, cur.fetchall()


@app.route("/t/<name>")
def view(name):
    page = max(int(request.args.get("page", 0)), 0)
    total, rows = fetch(name, PAGE, page * PAGE)
    cols = list(rows[0].keys()) if rows else []
    return render_template_string(TABLE, name=name, total=total, rows=rows, cols=cols,
                                  page=page, size=PAGE)


@app.route("/api/<name>")
def api(name):
    limit = min(max(int(request.args.get("limit", 100)), 1), 1000)
    offset = max(int(request.args.get("offset", 0)), 0)
    total, rows = fetch(name, limit, offset)
    return jsonify(table=name, total=total, limit=limit, offset=offset, rows=rows)
