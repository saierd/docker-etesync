include Makefile.m4

ETEBASE_TAG="$(shell git ls-remote https://github.com/etesync/server.git refs/heads/master|cut -f1)"
ETESYNC_WEB_TAG="$(shell git ls-remote https://github.com/etesync/etesync-web.git refs/heads/master|cut -f1)"

M4SCRIPT += -DETEBASE_TAG=$(ETEBASE_TAG)
M4SCRIPT += -DETESYNC_WEB_TAG=$(ETESYNC_WEB_TAG)

Dockerfile-force: Dockerfile-force-impl Dockerfile

Dockerfile-force-impl:
	touch Dockerfile.in

Dockerfile: Dockerfile.in

build: Dockerfile
	docker build .

all: Dockerfile-force build

.PHONY: all build Dockerfile-force Dockerfile-force-impl
