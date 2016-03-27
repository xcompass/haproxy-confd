#!/bin/bash

ETCD_VER=2.3.0
[ -z "$HOST_IP" ] &&  HOST_IP=172.17.0.1

#set -e
etcdctl() {
    docker run --rm --net=host --entrypoint /etcdctl quay.io/coreos/etcd:v$ETCD_VER "$@" > /dev/null
}

curl() {
    docker run --rm --net=host appropriate/curl \
        -s -o /dev/null -I -w "%{http_code}" \
        "$@"
}

check(){
    printf "Checking $3..."
    if [ "$1" != "$2" ] ; then
        printf "Failed\n"
        printf "Wrong test output\n"
        printf "Was: $1\n"
        printf "Expected: $2\n"
        exit 1
    else
        printf "OK\n"
    fi
}

echo "Setting up test environmenet..."

docker rm -f etcd >/dev/null 2>&1 || true
docker rm -f discoverer >/dev/null 2>&1 || true
docker rm -f echoserver >/dev/null 2>&1 || true

docker run -d -p 2379:2379 --name etcd quay.io/coreos/etcd:v$ETCD_VER \
    --listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
    --advertise-client-urls http://${HOST_IP}:2379,http://${HOST_IP}:4001 > /dev/null 2>&1

docker run -d --name echoserver -p 1234:80 nginx > /dev/null 2>&1

sleep 2 # yeah

# Setup
etcdctl mkdir /services
etcdctl mkdir /tcp-services
etcdctl mkdir /config

docker run -d \
    --net=host --name discoverer \
    -v `pwd`/keys:/keys \
    -p 80:80 \
    -p 443:443\
    -e SSL_PATH=/keys \
    haproxy-confd \
    -interval 1

# Happy path
etcdctl set /services/srv1/upstreams/host1 localhost:1234

sleep 2

TARGET=srv1.local:80
check "$(curl --resolve "$TARGET:$HOST_IP" http://$TARGET)" "200" "$TARGET"

# Missing hosts
etcdctl set /services/srv2/scheme http

# Missing hosts and scheme!!!
etcdctl mkdir /services/srv3

# Missing scheme
etcdctl set /services/srv4/upstreams/host1 localhost:1234

sleep 2

TARGET=srv2.local:80
check "$(curl --resolve "$TARGET:$HOST_IP" http://$TARGET)" "503" "$TARGET"

TARGET=srv3.local:80
check "$(curl --resolve "$TARGET:$HOST_IP" http://$TARGET)" "503" "$TARGET"


# SSL
etcdctl set /config/services/enable_ssl true
etcdctl set /services/srv5/scheme https
etcdctl set /services/srv5/upstreams/host1 localhost:1234

sleep 2

# Happy path
TARGET=srv5.local:443
check "$(curl --resolve "$TARGET:$HOST_IP" --insecure https://$TARGET)" "200" "$TARGET"

# Redirect non-https to https ... Btw curl is magic <3
TARGET=srv5.local:80
check "$(curl --resolve "$TARGET:$HOST_IP" http://$TARGET)" "301" "$TARGET"

# Hybrid http/https
etcdctl set /services/srv7/scheme http-and-https
etcdctl set /services/srv7/upstreams/host1 localhost:1234

sleep 2

TARGET=srv7.local:80
check "$(curl --resolve "$TARGET:$HOST_IP" http://$TARGET)" "200" "$TARGET"
TARGET=srv7.local:443
check "$(curl --resolve "$TARGET:$HOST_IP" --insecure https://$TARGET)" "200" "$TARGET"
