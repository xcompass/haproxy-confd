HAProxy combined with confd for HTTP load balancing
===================================================

This is based on yaronr/haproxy-confd and cstpdk/haproxy-confd

* HAProxy 1.6.x with confd 0.12.0-alpha
* Uses zero-downtime reconfiguration (e.g - instead of harpy reload, which will drop all connections, will gradually transfer new connections to the new config)
* Added support for url rexeg (not reggae, damn you spell checker) for routing, in addition to the usual hostname pattern
* Added validation for existence of keys in backing kv store, to prevent failures
* Used official Alpine HAProxy as base to reduce the size of the image
* Added multiple domain support
* Added SSL/HTTPS support
* Added tests

## Usage

### Setup
Create the paths allowing confd to find the services:
```bash
etcdctl mkdir "/services"
etcdctl mkdir "/tcp-services"
etcdctl mkdir "/config"
```

Depending on your needs, create one or more services or tcp-services.
For instance, to create an http service with domain *example.org*  and load balancing on servers *1.2.3.4:80* (we'll call it *nodeA*) and *2.3.4.5:80* (called *nodeB*), run these commands:
```bash
etcdctl mkdir "/services/example.org"
etcdctl set "/services/example.org/upstreams/nodeA" "1.2.3.4:80"
etcdctl set "/services/example.org/upstreams/nodeB" "2.3.4.5:80"
```

### Enable SSL/HTTP support

```bash
etcdctl mkdir "/config/services"
etcdctl set "/config/services/enable_ssl" "true"
etcdctl set "/services/example.org/scheme" "https"
```
Possible values for scheme are: http (default), https, http-and-https. If scheme is https, all traffic to http for the domain will be redirected to https.

Add pem certs/keys to keys directory to be mounted to the container.

### Start Container
Start the container making sure to expose port 80 on the host machine

```bash
docker run -e ETCD_NODE=http://172.17.42.1:2379 -p 1000:1000 -p 80:80 -p 443:443 -v `pwd`/keys:/keys compass/haproxy-confd
```


To *add an upstream node*, let's say *nodeB2*, *2.3.4.5:90*, you just have to run this, and the configuration should safely be updated !
```bash
etcdctl set "/services/example.org/upstreams/nodeB2" "2.3.4.5:90"
```

To *remove an upstream server*, let's say ... *nodeB2* (added by mistake ?), just run
```bash
etcdctl rm "/services/myapp/upstreams/nodeB2"
```

To *remove a service*, and so a directory, you must type
```bash
etcdctl rmdir "/services/example.org"
```

The commands for a tcp-service are the same but with *tcp-services* instead of *services*

