#!/bin/sh

if [ -z "$ETCD_NODE" ]
then
  echo "Missing ETCD_NODE env var"
  exit 1
fi

set -eo pipefail

# first check if we're passing flags,
if [ "${1:0:1}" = '-'  ]; then
    set -- confd "$@"
fi

if [ "$1" = 'confd' ]; then
    #confd will start haproxy, since conf will be different than existing (which is null)

    echo "[haproxy-confd] booting container. ETCD: $ETCD_NODE"

    # Loop until confd has updated the haproxy config
    n=0
    until confd -onetime -node "$ETCD_NODE"; do
        if [ "$n" -eq "4" ];  then echo "Failed to start due to config error"; exit 1; fi
        echo "[haproxy-confd] waiting for confd to refresh haproxy.cfg"
        n=$((n+1))
        sleep $n
    done

    echo "[haproxy-confd] Initial HAProxy config created. Starting confd"
    exec "$@" -node "$ETCD_NODE"
fi

exec "$@"
