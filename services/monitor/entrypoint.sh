#!/bin/sh
[ -n "$GATEWAY" ] && ip route replace default via "$GATEWAY"
exec /usr/bin/dumb-init -- "$@"
