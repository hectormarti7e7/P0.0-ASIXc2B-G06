#!/bin/bash
# Servidor SSH S-NCC: port 2222, només l'usuari bchecker i només amb clau pública.
# L'executa l'entrypoint de la imatge base abans d'arrencar sshd.
set -e

USUARI=bchecker
CLAUS=/opt/authorized_keys     # clau(s) pública(s) autoritzades (muntat en només lectura)

# Configuració d'sshd. Ubuntu 22.04 inclou sshd_config.d/*.conf al principi del fitxer principal.
cat > /etc/ssh/sshd_config.d/10-p00.conf <<'EOF'
Port 2222
PermitRootLogin no
AllowUsers bchecker
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
LogLevel VERBOSE
EOF

# Clau pública de l'usuari (propietari i permisos estrictes, si no sshd la ignora)
[ -s "$CLAUS" ] || { echo "[ssh] falta $CLAUS"; exit 1; }
install -d -m 700 -o "$USUARI" -g "$USUARI" "/home/$USUARI/.ssh"
install -m 600 -o "$USUARI" -g "$USUARI" "$CLAUS" "/home/$USUARI/.ssh/authorized_keys"

# Validar la configuració abans d'arrencar el servei
sshd -t
echo "[ssh] configuració vàlida: port 2222, només clau pública"
