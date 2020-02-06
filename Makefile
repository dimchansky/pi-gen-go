PACKAGE_NAME := github.com/dimchansky/pi-gen-go
SHELL := bash
ARTIFACTS_DIR := $(if $(ARTIFACTS_DIR),$(ARTIFACTS_DIR),bin)

PKGS ?= $(shell go list ./...)
PKGS_NO_CMDS ?= $(shell go list ./... | grep -v $(PACKAGE_NAME)/cmd)
BENCH_FLAGS ?= -benchmem

VERSION ?= vlatest
COMMIT := $(shell git rev-parse HEAD)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
BUILD_TIME := $(shell TZ=UTC date -u '+%Y-%m-%dT%H:%M:%SZ')
M = $(shell printf "\033[32;1m▶▶▶\033[0m")
M2 = $(shell printf "\033[32;1m▶▶▶▶▶▶\033[0m")

export GO111MODULE := on

.PHONY: all
all: clean lint test cmd

.PHONY: dependencies
dependencies: ; $(info $(M) retrieving dependencies…)
	@echo "$(M2) Installing dependencies..."
	go mod download
	@echo "$(M2) Installing goimports..."
	go install golang.org/x/tools/cmd/goimports
	@echo "$(M2) Installing golint..."
	go install golang.org/x/lint/golint
	@echo "$(M2) Installing staticcheck..."
	go install honnef.co/go/tools/cmd/staticcheck

.PHONY: lint
lint: ; $(info $(M) running lint tools…)
	@echo "$(M2) checking formatting..."
	@gofiles=$$(go list -f {{.Dir}} $(PKGS) | grep -v mock) && [ -z "$$gofiles" ] || unformatted=$$(for d in $$gofiles; do goimports -l $$d/*.go; done) && [ -z "$$unformatted" ] || (echo >&2 "Go files must be formatted with goimports. Following files has problem:\n$$unformatted" && false)
	@echo "$(M2) checking vet..."
	@go vet $(PKG_FILES)
	@echo "$(M2) checking staticcheck..."
	@staticcheck $(PKG_FILES)
	@echo "$(M2) checking lint..."
	@$(foreach dir,$(PKGS),golint $(dir);)

.PHONY: test
test: ; $(info $(M) running tests…)
	go test -tags=dev -timeout 60s -race -v $(PKGS)

.PHONY: bench
BENCH ?= .
bench: ; $(info $(M) running benchmarks…)
	$(foreach pkg,$(PKGS),go test -bench=$(BENCH) -run="^$$" $(BENCH_FLAGS) $(pkg);)

.PHONY: cover
cover: ; $(info $(M) analyzing the code coverage…)
	mkdir -p ./${ARTIFACTS_DIR}/.cover
	go test -race -coverprofile=./${ARTIFACTS_DIR}/.cover/cover.out -covermode=atomic -coverpkg=./... $(PKGS_NO_CMDS)
	go tool cover -func=./${ARTIFACTS_DIR}/.cover/cover.out
	go tool cover -html=./${ARTIFACTS_DIR}/.cover/cover.out -o ./${ARTIFACTS_DIR}/cover.html

.PHONY: fmt
fmt: ; $(info $(M) formatting the code…)
	@echo "$(M2) formatting files..."
	@gofiles=$$(go list -f {{.Dir}} $(PKGS) | grep -v mock) && [ -z "$$gofiles" ] || for d in $$gofiles; do goimports -l -w $$d/*.go; done

.PHONY: cmd
CMDS ?= $(shell ls -d ./cmd/*/ | xargs -L1 basename | grep -v internal)
cmd: ; $(info $(M) building the artifacts…)
	mkdir -p $(ARTIFACTS_DIR)
	$(foreach cmd,$(CMDS),go build -o $(ARTIFACTS_DIR)/$(cmd) ./cmd/$(cmd);)

clean:
	rm -rf $(ARTIFACTS_DIR)