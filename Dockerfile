# Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+

FROM icinga/icingaweb2-deps

COPY icingaweb2 /usr/share/icingaweb2
COPY icinga-php /usr/share/icinga-php

RUN ["ln", "-vs", "/usr/share/icingaweb2/packages/files/apache/icingaweb2.conf", "/etc/apache2/conf-enabled/"]
RUN ["ln", "-vs", "/usr/share/icingaweb2/bin/icingacli", "/usr/local/bin/"]

USER www-data
CMD ["bash", "-eo", "pipefail", "-c", ". /etc/apache2/envvars; exec apache2 -DFOREGROUND"]
