#!/usr/bin/make
# Makefile readme (ru): <http://linux.yaroslavl.ru/docs/prog/gnu_make_3-79_russian_manual.html>
# Makefile readme (en): <https://www.gnu.org/software/make/manual/html_node/index.html#SEC_Contents>

SHELL = /bin/sh

VERSION ?= $(shell git rev-list -1 HEAD)
TAG_COMMIT ?= $(shell git rev-list --tags --max-count=1)
TAG ?= $(shell git describe --tags ${TAG_COMMIT})

image_name = public.ecr.aws/q5z8n0i3/markdown-lint:$(TAG)

.PHONY : help build test shell clean
.DEFAULT_GOAL : help

# This will output the help for each task. thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Show this help
	@printf "\033[33m%s:\033[0m\n" 'Available commands'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[32m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build docker image with application
	docker build --tag $(image_name) -f Dockerfile .

test: ## Execute tests
	docker run --rm -t -v "$(shell pwd)/tests:/tests" -w "/tests" --entrypoint "" $(image_name) /tests/run.sh

shell: ## Start shell into container
	docker run --rm -ti --entrypoint "" $(image_name) sh

clean: ## Make some clean
	docker rmi -f $(image_name)

docker-login:
	@aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/q5z8n0i3

build-multi-arch: docker-login
	@docker build \
		--push \
		--platform linux/arm/v7,linux/arm64,linux/amd64 \
		--tag $(image_name) -f Dockerfile .
