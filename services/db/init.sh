#!/bin/bash
# B-NCC: prepara MySQL (idempotent): datadir, base de dades i usuaris.
set -e
SOCK=/var/run/mysqld/mysqld.sock
mkdir -p /var/run/mysqld && chown mysql:mysql /var/run/mysqld

cat > /etc/mysql/mysql.conf.d/zz-p00.cnf <<'EOF'
[mysqld]
bind-address = 0.0.0.0
skip-name-resolve
character-set-server = utf8mb4
collation-server = utf8mb4_0900_ai_ci
EOF

if [ ! -d /var/lib/mysql/mysql ]; then
  echo "[db] inicialitzant datadir"
  mysqld --initialize-insecure --user=mysql
fi

# Arrencada temporal sense xarxa per aplicar usuaris i permisos
mysqld --user=mysql --skip-networking --socket=$SOCK > /var/log/mysql-init.log 2>&1 &
PID=$!
for i in $(seq 1 90); do
  mysqladmin --socket=$SOCK ping --silent 2>/dev/null && break
  sleep 1
done
envsubst < /opt/init.sql | mysql --socket=$SOCK
mysqladmin --socket=$SOCK shutdown
wait $PID || true
echo "[db] usuaris i base de dades preparats"
