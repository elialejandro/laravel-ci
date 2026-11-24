# laravel-ci

A PHP CLI image for running Laravel test suites in CI: `elialejandro/laravel-ci`.

It exists so CI jobs stop installing PHP on every run, and so the test suite can use
in-memory SQLite with SQLite >= 3.44 (needed for `CONCAT`, `GROUP_CONCAT ... ORDER BY`).

## What's inside

- Ubuntu 24.04 base
- PHP CLI from [`ppa:ondrej/php`](https://launchpad.net/~ondrej/+archive/ubuntu/php) (8.4 and 8.5)
- Extensions: bcmath, curl, gd, intl, mbstring, redis, sqlite3 / pdo_sqlite, xml (dom, xmlreader, xmlwriter), zip,
  plus the CLI defaults (ctype, fileinfo, iconv, openssl, pcntl, posix, sodium, ...)
- SQLite 3.45 (Ubuntu 24.04 system library)
- Composer 2, git, unzip, curl
- `COMPOSER_ALLOW_SUPERUSER=1`, `COMPOSER_HOME=/root/.composer`, `COMPOSER_CACHE_DIR=/root/.composer/cache`
- Working directory `/app`

No web server, FPM, or Octane: it only runs CLI commands.

The image ships a self-check, `laravel-ci-check`, which runs during the build and fails it when
SQLite is older than 3.44, a required extension is missing, or Composer is not 2.x:

```sh
docker run --rm elialejandro/laravel-ci:8.4 laravel-ci-check
```

## Tags

| Tag | Example | Moves? |
|-----|---------|--------|
| PHP patch version | `8.4.28`, `8.5.13` | Immutable per PHP release (rebuilt only for OS patches) |
| PHP minor version | `8.4`, `8.5` | Floats to the newest patch release |
| `latest` | `8.4` | Floats with `8.4` |

Images are published for `linux/amd64` and `linux/arm64`.

**Use the patch tag in CI.** Tools such as Pint store the exact PHP version in their cache, so a
floating tag that moves from `8.4.28` to `8.4.29` silently invalidates those caches and can change
behaviour between runs. Bump the patch tag on purpose. The floating tag is for convenience.

## Usage

### Bitbucket Pipelines

```yaml
image: elialejandro/laravel-ci:8.4.28

definitions:
  caches:
    composer-home: ~/.composer/cache

pipelines:
  default:
    - step:
        name: Tests
        caches:
          - composer-home
        script:
          - composer install --no-interaction --prefer-dist
          - php artisan test
```

### Jenkins (Declarative Pipeline with Docker)

```groovy
pipeline {
  agent any
  stages {
    stage('Tests') {
      steps {
        script {
          docker.image('elialejandro/laravel-ci:8.4.28').inside('-u root') {
            sh 'composer install --no-interaction --prefer-dist'
            sh 'php artisan test'
          }
        }
      }
    }
  }
}
```

`-u root` matches the image's `COMPOSER_HOME` under `/root`; drop it if your agent mounts a
writable home for the Jenkins user and you set `COMPOSER_HOME` accordingly.

### GitHub Actions

```yaml
jobs:
  tests:
    runs-on: ubuntu-24.04
    container:
      image: elialejandro/laravel-ci:8.4.28
    steps:
      - uses: actions/checkout@v7
      - uses: actions/cache@v6
        with:
          path: /root/.composer/cache
          key: composer-${{ hashFiles('composer.lock') }}
      - run: composer install --no-interaction --prefer-dist
      - run: php artisan test
```

## Build and verify locally

```sh
make check                    # builds elialejandro/laravel-ci:8.4-local and runs laravel-ci-check
make check PHP_VERSION=8.5    # same for 8.5
make build-all                # both versions
```

Equivalent without make:

```sh
docker build --build-arg PHP_VERSION=8.4 -t elialejandro/laravel-ci:8.4-local .
docker run --rm elialejandro/laravel-ci:8.4-local laravel-ci-check
```

Check a project's platform requirements against the image (read-only mount):

```sh
docker run --rm -v "$PWD":/app:ro elialejandro/laravel-ci:8.4-local composer check-platform-reqs --lock
```

## Publishing

[`.github/workflows/publish.yml`](.github/workflows/publish.yml) runs on push to `main`, on manual
dispatch, and monthly (1st of the month) to pick up security patches. For each PHP version it:

1. builds `linux/amd64`, loads it, and runs `laravel-ci-check`;
2. reads the PHP version from that image to derive the tags (`8.4`, `8.4.28`, and `latest` for 8.4);
3. builds and pushes `linux/amd64` + `linux/arm64` with those tags.

Required repository secrets: `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (a Docker Hub access token
with read/write scope).

GitHub disables scheduled workflows after 60 days without repository activity; re-enable it from
the Actions tab, or run it manually, if that happens.
