#!/bin/bash
mkdir -p /var/lib/misc
envsubst < /opt/dnsmasq.conf.tpl > /etc/dnsmasq.p00.conf
dnsmasq --test --conf-file=/etc/dnsmasq.p00.conf
