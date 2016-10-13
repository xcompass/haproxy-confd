.PHONY: docs

build:
	docker build -t haproxy-confd .

clean:
	docker rm -f haproxy-confd
	docker rmi haproxy-confd

test: build
	./test.sh

log:
	docker logs haproxy-confd
