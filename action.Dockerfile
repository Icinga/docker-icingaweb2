FROM icinga/icingaweb2-builder

COPY action.bash Dockerfile /

CMD ["/action.bash"]
