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


FROM debian:bookworm-slim

RUN ["bash", "-exo", "pipefail", "-c", "export DEBIAN_FRONTEND=noninteractive; apt-get update; apt-get install --no-install-{recommends,suggests} -y apache2 ca-certificates libapache2-mod-php8.2 libldap-common locales-all php-{imagick,redis} php8.2-{bcmath,bz2,common,curl,dba,enchant,gd,gmp,imap,interbase,intl,ldap,mbstring,mysql,odbc,opcache,pgsql,pspell,readline,snmp,soap,sqlite3,sybase,tidy,xml,xmlrpc,xsl,zip}; apt-get clean; rm -vrf /var/lib/apt/lists/*"]

COPY --from=entrypoint /entrypoint/entrypoint /entrypoint
COPY entrypoint/db-init /entrypoint-db-init

RUN ["a2enmod", "rewrite"]
RUN ["ln", "-vsf", "/dev/stdout", "/var/log/apache2/access.log"]
RUN ["ln", "-vsf", "/dev/stderr", "/var/log/apache2/error.log"]
RUN ["ln", "-vsf", "/dev/stdout", "/var/log/apache2/other_vhosts_access.log"]

RUN ["perl", "-pi", "-e", "if (/Listen/) { s/80/8080/ }", "/etc/apache2/ports.conf"]
RUN ["perl", "-pi", "-e", "if (/VirtualHost/) { s/80/8080/ }", "/etc/apache2/sites-available/000-default.conf"]
EXPOSE 8080

RUN ["chmod", "-R", "u=rwX,go=rX", "/entrypoint-db-init"]
RUN ["chmod", "o+x", "/var/log/apache2"]
RUN ["chown", "www-data:www-data", "/var/run/apache2"]
RUN ["ln", "-vs", "/data/etc/icingaweb2", "/etc/icingaweb2"]
RUN ["ln", "-vs", "/data/var/lib/icingaweb2", "/var/lib/icingaweb2"]
RUN ["install", "-o", "www-data", "-g", "www-data", "-d", "/data"]

ENTRYPOINT ["/entrypoint"]

COPY --from=usr-share /usr-share/. /usr/share/
COPY php.ini /etc/php/8.2/cli/conf.d/99-docker.ini

RUN ["ln", "-vs", "/usr/share/icingaweb2/bin/icingacli", "/usr/local/bin/"]
RUN ["icingacli", "setup", "config", "webserver", "apache", "--path=/", "--file=/etc/apache2/conf-enabled/icingaweb2.conf"]

USER www-data
ENV ICINGAWEB_OFFICIAL_DOCKER_IMAGE 1
CMD ["bash", "-eo", "pipefail", "-c", ". /etc/apache2/envvars; exec apache2 -DFOREGROUND"]
