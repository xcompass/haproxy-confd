#!/bin/bash

# convert comma separated node list to confd parameters, e.g. -node=node1 -node=node2 ...
IFS=',' read -ra NODES <<< "$ETCD_NODE"
NODES_PARAMS=$(printf -- "-node=%s " "${NODES[@]}")

set -eo pipefail

# first check if we're passing flags,
if [ "${1:0:1}" = '-'  ]; then
    set -- confd "$@"
fi

if [ "$1" = 'confd' ]; then
    # process the template with environment variables
    sed -e "s|%%PREFIX%%|$KEY_PREFIX|" /etc/confd/conf.d/haproxy.toml.in > /etc/confd/conf.d/haproxy.toml
    sed -e "s|%%PREFIX%%|$KEY_PREFIX|" /etc/confd/templates/haproxy.tmpl.in > /etc/confd/templates/haproxy.tmpl

    #confd will start haproxy, since conf will be different than existing (which is null)

    echo "[haproxy-confd] booting container. ETCD: $ETCD_NODE"

    # Loop until confd has updated the haproxy config
    n=0
    until confd -onetime $NODES_PARAMS; do
        if [ "$n" -eq "4" ];  then echo "Failed to start due to config error"; exit 1; fi
        echo "[haproxy-confd] waiting for confd to refresh haproxy.cfg"
        n=$((n+1))
        sleep $n
    done

    echo "[haproxy-confd] Initial HAProxy config created. Starting confd"
    exec "$@" $NODES_PARAMS
fi

exec "$@"
