FROM haproxy:1.6.11-alpine

MAINTAINER Pan Luo <pan.luo@ubc.ca>

ENV ETCD_NODE http://172.17.0.1:2379
ENV confd_ver 0.12.0-alpha3
ENV KEY_PREFIX ""

RUN apk add --no-cache --update openssl bash

RUN wget -t 5 https://github.com/kelseyhightower/confd/releases/download/v${confd_ver}/confd-${confd_ver}-linux-amd64 -O /bin/confd && \
    chmod +x /bin/confd

RUN /usr/sbin/addgroup haproxy && /usr/sbin/adduser -D -H -S -G haproxy haproxy

# Expose ports.
EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
CMD ["-watch"]

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ADD confd /etc/confd
