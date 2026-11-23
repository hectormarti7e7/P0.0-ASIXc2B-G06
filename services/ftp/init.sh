#!/bin/bash
# F-NCC: servidor FTP (vsftpd). Només l'usuari bchecker, tancat a /srv/ftp i mode passiu
# 30000-30009. L'executa l'entrypoint abans d'arrencar vsftpd.
set -e

# Adreça que el servidor anuncia al client en mode passiu: la de l'equip dels serveis,
# per on entra el client (no la del contenidor).
PASV_ADDRESS="${FTP_PASV_ADDRESS:?falta FTP_PASV_ADDRESS}"

# Carpeta FTP: l'arrel no és escrivible (si ho fos, vsftpd no tancaria l'usuari);
# només es pot pujar a "pujades".
mkdir -p /srv/ftp/pujades /var/run/vsftpd/empty
chown root:root /srv/ftp && chmod 755 /srv/ftp
chown bchecker:bchecker /srv/ftp/pujades && chmod 755 /srv/ftp/pujades
echo "Servidor FTP de la practica P0.0 (equip N06)" > /srv/ftp/benvinguda.txt

# Només bchecker pot entrar
echo bchecker > /etc/vsftpd.userlist

cat > /etc/vsftpd.conf <<EOF
listen=YES
listen_ipv6=NO
background=NO

# Accés: només usuaris locals de la llista, mai anònim
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
userlist_enable=YES
userlist_deny=NO
userlist_file=/etc/vsftpd.userlist

# L'usuari queda tancat a /srv/ftp
local_root=/srv/ftp
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty

# Mode passiu (ports del firewall) i actiu
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=30009
pasv_address=${PASV_ADDRESS}
connect_from_port_20=YES

# Registre (es mostra a docker logs)
xferlog_enable=YES
xferlog_std_format=NO
vsftpd_log_file=/var/log/vsftpd.log
log_ftp_protocol=YES

# Dins d'un contenidor el sandbox de seccomp no funciona
seccomp_sandbox=NO
ftpd_banner=Servidor FTP P0.0 N06
EOF

# vsftpd escriu el registre en un fitxer: el mostrem a docker logs
touch /var/log/vsftpd.log
nohup tail -F /var/log/vsftpd.log >/proc/1/fd/1 2>&1 &

echo "[ftp] vsftpd preparat: usuari bchecker, passiu 30000-30009, anunci ${PASV_ADDRESS}"
