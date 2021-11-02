# Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+

FROM golang:bullseye as entrypoint

COPY entrypoint /entrypoint

WORKDIR /entrypoint
RUN ["go", "build", "."]


FROM debian:bullseye-slim

RUN ["bash", "-exo", "pipefail", "-c", "export DEBIAN_FRONTEND=noninteractive; apt-get update; apt-get install --no-install-{recommends,suggests} -y apache2 ca-certificates libapache2-mod-php7.4 locales-all php-{imagick,redis} php7.4-{bcmath,bz2,common,curl,dba,enchant,gd,gmp,imap,interbase,intl,json,ldap,mbstring,mysql,odbc,opcache,pgsql,pspell,readline,snmp,soap,sqlite3,sybase,tidy,xml,xmlrpc,xsl,zip}; apt-get clean; rm -vrf /var/lib/apt/lists/*"]

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

COPY icingaweb2 /usr/share/icingaweb2
COPY icinga-php /usr/share/icinga-php

RUN ["ln", "-vs", "/usr/share/icingaweb2/packages/files/apache/icingaweb2.conf", "/etc/apache2/conf-enabled/"]
RUN ["ln", "-vs", "/usr/share/icingaweb2/bin/icingacli", "/usr/local/bin/"]

USER www-data
CMD ["bash", "-eo", "pipefail", "-c", ". /etc/apache2/envvars; exec apache2 -DFOREGROUND"]
