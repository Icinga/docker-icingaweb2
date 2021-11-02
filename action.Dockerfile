# Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+

FROM buildpack-deps:scm as clone
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN mkdir actions ;\
	cd actions ;\
	git clone --bare https://github.com/actions/checkout.git ;\
	git -C checkout.git archive --prefix=checkout/ v2 |tar -x ;\
	rm -rf *.git


FROM debian:bullseye-slim
SHELL ["/bin/bash", "-exo", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update ;\
	apt-get install --no-install-{recommends,suggests} -y \
		apt-transport-https gnupg2 dirmngr ca-certificates ;\
	apt-get clean ;\
	rm -vrf /var/lib/apt/lists/* ;\
	apt-key adv --fetch-keys https://download.docker.com/linux/debian/gpg ;\
	apt-get purge -y gnupg2 dirmngr ;\
	apt-get autoremove --purge -y

ADD action-base.list /etc/apt/sources.list.d/docker.list

RUN apt-get update ;\
	apt-get install --no-install-{recommends,suggests} -y \
		composer docker-ce-cli git nodejs patch php7.4-zip ;\
	apt-get clean ;\
	rm -vrf /var/lib/apt/lists/*

COPY --from=clone /actions /actions

COPY action.bash composer.bash Dockerfile get-mods.sh icingaweb2.patch /
COPY entrypoint /entrypoint

CMD ["/action.bash"]
