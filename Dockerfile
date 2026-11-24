# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG PHP_VERSION=8.4
ENV PHP_VERSION=${PHP_VERSION}

ENV DEBIAN_FRONTEND=noninteractive \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/root/.composer \
    COMPOSER_CACHE_DIR=/root/.composer/cache

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        software-properties-common gpg-agent ca-certificates curl git unzip; \
    add-apt-repository -y ppa:ondrej/php; \
    apt-get install -y --no-install-recommends \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip; \
    apt-get purge -y --auto-remove software-properties-common gpg-agent; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY bin/laravel-ci-check /usr/local/bin/laravel-ci-check

# Fail the build when the image does not meet its guarantees.
RUN laravel-ci-check

WORKDIR /app

CMD ["php", "-a"]
