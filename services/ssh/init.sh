#!/bin/bash
# S-NCC: servidor SSH (bastió) amb una configuració una mica endurida.
set -e
cat > /etc/ssh/sshd_config.d/p00.conf <<'EOF'
PermitRootLogin no
MaxAuthTries 3
LoginGraceTime 30
AllowUsers bchecker
LogLevel VERBOSE
EOF
