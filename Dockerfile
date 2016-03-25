FROM haproxy:alpine

MAINTAINER Pan Luo <pan.luo@ubc.ca>

ENV ETCD_NODE 172.17.42.1:2379
ENV confd_ver 0.11.0

#sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/haproxy

RUN apk add --no-cache --update openssl

RUN wget -t 5 https://github.com/kelseyhightower/confd/releases/download/v${confd_ver}/confd-${confd_ver}-linux-amd64 -O /bin/confd && \
    chmod +x /bin/confd

RUN /usr/sbin/addgroup haproxy
RUN /usr/sbin/adduser -D -H -S -G haproxy haproxy

ADD entrypoint.sh /entrypoint.sh
ADD confd /etc/confd

RUN chmod +x /entrypoint.sh

# Expose ports.
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
