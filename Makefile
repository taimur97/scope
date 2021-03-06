.PHONY: all build client static dist test clean

# If you can use Docker without being root, you can `make SUDO= <target>`
SUDO=sudo

DOCKERHUB_USER=weaveworks
APP_EXE=app/app
PROBE_EXE=probe/probe
FIXPROBE_EXE=experimental/fixprobe/fixprobe
SCOPE_IMAGE=$(DOCKERHUB_USER)/scope
SCOPE_EXPORT=scope.tar

all: build

build:
	go build ./...

client:
	cd client && make build && rm -f dist/.htaccess

static:
	go get github.com/mjibson/esc
	cd app && esc -o static.go -prefix ../client/dist ../client/dist

dist: client static build

test: $(APP_EXE) $(FIXPROBE_EXE)
	# app and fixprobe needed for integration tests
	go test ./...

$(APP_EXE):
	cd app && go build

$(FIXPROBE_EXE):
	cd experimental/fixprobe && go build

$(PROBE_EXE):
	cd probe && go build

$(SCOPE_EXPORT): Dockerfile $(APP_EXE) $(PROBE_EXE) entrypoint.sh supervisord.conf
	$(SUDO) docker build -t $(SCOPE_IMAGE) .
	$(SUDO) docker save $(SCOPE_IMAGE):latest > $@

docker: $(SCOPE_EXPORT)
	docker run --privileged -d --name=scope --net=host \
		-v /proc:/hostproc \
		-v /var/run/docker.sock:/var/run/docker.sock \
		$(SCOPE_IMAGE)

clean:
	go clean ./...
	rm -f $(SCOPE_EXPORT)
