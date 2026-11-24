IMAGE ?= rurounize/laravel-ci
PHP_VERSION ?= 8.4
TAG := $(IMAGE):$(PHP_VERSION)-local

.PHONY: build check build-all

build:
	docker build --build-arg PHP_VERSION=$(PHP_VERSION) -t $(TAG) .

check: build
	docker run --rm $(TAG) laravel-ci-check

build-all:
	$(MAKE) check PHP_VERSION=8.4
	$(MAKE) check PHP_VERSION=8.5
