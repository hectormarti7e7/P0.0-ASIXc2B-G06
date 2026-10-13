port=53
no-resolv
server=1.1.1.1
server=9.9.9.9
domain=asix.local
local=/asix.local/
log-queries

# El router es resol com R-NCC i com R
host-record=R-${NCC},R,R-${NCC}.asix.local,172.20.2.254

host-record=W-${NCC},W-${NCC}.asix.local,172.20.1.10
host-record=F-${NCC},F-${NCC}.asix.local,172.20.1.11
host-record=S-${NCC},S-${NCC}.asix.local,172.20.1.12
host-record=B-${NCC},B-${NCC}.asix.local,172.20.2.10
host-record=DNS-${NCC},DNS-${NCC}.asix.local,172.20.2.53
host-record=DHCP-${NCC},DHCP-${NCC}.asix.local,172.20.2.67
host-record=MON-${NCC},MON-${NCC}.asix.local,172.20.2.20
host-record=PC-L-${NCC},PC-L-${NCC}.asix.local,172.20.2.50
