#!/bin/bash
set -e
mkdir -p /var/run/vsftpd/empty /home/bchecker/ftp
NCC=${HOSTNAME#F-} envsubst < /opt/vsftpd.conf.tpl > /etc/vsftpd.conf
# Si hi ha IP pública (clients externs en mode passiu) s'anuncia aquesta
[ -n "${PUBLIC_IP:-}" ] && echo "pasv_address=${PUBLIC_IP}" >> /etc/vsftpd.conf
[ -f /home/bchecker/ftp/LLEGEIX.txt ] || echo "FTP de la practica P0.0" > /home/bchecker/ftp/LLEGEIX.txt
chown -R bchecker:bchecker /home/bchecker/ftp
