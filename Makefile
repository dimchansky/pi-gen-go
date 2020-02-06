PACKAGE_NAME := github.com/dimchansky/pi-gen-go
SHELL := bash
ARTIFACTS_DIR := $(if $(ARTIFACTS_DIR),$(ARTIFACTS_DIR),bin)

PKGS ?= $(shell go list ./...)
CMDS ?= $(shell ls -d ./cmd/*/ | xargs -L1 basename | grep -v internal)
PKGS_NO_CMDS ?= $(shell go list ./... | grep -v $(PACKAGE_NAME)/cmd)
BENCH_FLAGS ?= -benchmem

VERSION := $(if $(TRAVIS_TAG),$(TRAVIS_TAG),$(if $(TRAVIS_BRANCH),$(TRAVIS_BRANCH),development_in_$(shell git rev-parse --abbrev-ref HEAD)))
COMMIT := $(if $(TRAVIS_COMMIT),$(TRAVIS_COMMIT),$(shell git rev-parse HEAD))
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
cmd: ; $(info $(M) building the artifacts…)
	mkdir -p $(ARTIFACTS_DIR)
	$(foreach cmd,$(CMDS),go build -o $(ARTIFACTS_DIR)/$(cmd) ./cmd/$(cmd);)

.PHONY: cmdx
BUILD_PLATFORMS = "windows/amd64" "darwin/amd64" "linux/amd64"
cmdx: clean ; $(info $(M) cross compiling…)
	for cmd in $(CMDS); do \
		for platform in $(BUILD_PLATFORMS); do \
			platform_split=($${platform//\// }); \
			GOOS=$${platform_split[0]}; \
			GOARCH=$${platform_split[1]}; \
			HUMAN_OS=$${GOOS}; \
			if [ "$$HUMAN_OS" = "darwin" ]; then \
				HUMAN_OS='macos'; \
			fi; \
			output_name=$(ARTIFACTS_DIR)/$${cmd}; \
			if [ "$$GOOS" = "windows" ]; then \
				output_name+='.exe'; \
			fi; \
			env GOOS=$$GOOS GOARCH=$$GOARCH go build -o $${output_name} ./cmd/$${cmd}; \
			if [ "$$GOOS" = "windows" ]; then \
				pushd ${ARTIFACTS_DIR}; zip $${cmd}-$${HUMAN_OS}-$${GOARCH}-$(VERSION).zip $${cmd}.exe; popd; \
			else \
				pushd ${ARTIFACTS_DIR}; tar cvzf $${cmd}-$${HUMAN_OS}-$${GOARCH}-$(VERSION).tgz $${cmd}; popd; \
			fi; \
			rm $${output_name}; \
		done; \
	done

clean:
	rm -rf $(ARTIFACTS_DIR)