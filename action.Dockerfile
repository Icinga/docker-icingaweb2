# Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+

FROM icinga/icingaweb2-builder

COPY action.bash composer.bash Dockerfile get-mods.sh icingaweb2.patch /

CMD ["/action.bash"]
