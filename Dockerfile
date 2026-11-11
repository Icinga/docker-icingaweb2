# Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+

FROM golang:bookworm as entrypoint

COPY entrypoint /entrypoint

WORKDIR /entrypoint
RUN ["go", "build", "."]


FROM composer:lts as usr-share
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN ["mkdir", "/usr-share"]
WORKDIR /usr-share

ARG BUILD_MODE
COPY get-mods.sh /
RUN /get-mods.sh $BUILD_MODE

COPY composer.bash /
RUN ["/composer.bash"]

COPY --from=icingaweb2-git . /icingaweb2-src/.git
RUN git -C /icingaweb2-src archive --prefix=icingaweb2/ HEAD |tar -x


FROM dunglas/frankenphp:php8.2-bookworm

RUN ["bash", "-exo", "pipefail", "-c", "export DEBIAN_FRONTEND=noninteractive; apt-get update; apt-get upgrade -y; apt-get install --no-install-{recommends,suggests} -y ca-certificates libldap-common locales-all; apt-get clean; rm -vrf /var/lib/apt/lists/*"]

RUN ["install-php-extensions", "bcmath", "bz2", "curl", "dba", "enchant", "gd", "gettext", "gmp", "imagick", "imap", "intl", "ldap", "mbstring", "mysqli", "odbc", "opcache", "pdo_dblib", "pdo_firebird", "pdo_mysql", "pdo_odbc", "pdo_pgsql", "pdo_sqlite", "pgsql", "pspell", "readline", "redis", "snmp", "soap", "sqlite3", "tidy", "xmlrpc", "xsl", "zip"]

RUN ["cp", "/usr/local/etc/php/php.ini-production", "/usr/local/etc/php/php.ini"]

COPY --from=entrypoint /entrypoint/entrypoint /entrypoint
COPY entrypoint/db-init /entrypoint-db-init
COPY Caddyfile /etc/caddy/Caddyfile

EXPOSE 8080

RUN ["chmod", "-R", "u=rwX,go=rX", "/entrypoint-db-init"]
RUN ["chown", "-R", "www-data:www-data", "/config"]
RUN ["ln", "-vs", "/data/etc/icingaweb2", "/etc/icingaweb2"]
RUN ["ln", "-vs", "/data/var/lib/icingaweb2", "/var/lib/icingaweb2"]
RUN ["install", "-o", "www-data", "-g", "www-data", "-d", "/data"]

ENTRYPOINT ["/entrypoint"]

COPY --from=usr-share /usr-share/. /usr/share/
COPY php.ini /usr/local/etc/php/conf.d/99-docker.ini

RUN ["ln", "-vs", "/usr/share/icingaweb2/bin/icingacli", "/usr/local/bin/"]

USER www-data
ENV ICINGAWEB_OFFICIAL_DOCKER_IMAGE 1
ENV XDG_DATA_HOME=/config
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
