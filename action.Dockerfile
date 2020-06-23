FROM icinga/icingaweb2-builder

COPY action.bash Dockerfile get-mods.sh /

CMD ["/action.bash"]
