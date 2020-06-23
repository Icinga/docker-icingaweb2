FROM icinga/icingaweb2-builder

COPY action.bash Dockerfile get-mods.sh icingaweb2.patch /

CMD ["/action.bash"]
