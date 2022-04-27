#!/bin/bash
# Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+
set -exo pipefail

TARGET=icinga/icingaweb2

mkimg () {
	test -n "$TAG"
	test -n "$MODE"

	node /actions/checkout/dist/index.js |grep -vFe ::add-matcher::

	git archive --prefix=icingaweb2/ HEAD |tar -x

	/get-mods.sh "$MODE"
	/composer.bash
	patch -d icingaweb2 -p0 < /icingaweb2.patch

	cp -r /entrypoint .
	docker build -f /Dockerfile -t "${TARGET}:$TAG" .

	STATE_isPost=1 node /actions/checkout/dist/index.js
}

push () {
	test -n "$TAG"

	if [ "$(tr -d '\n' <<<"$DOCKER_HUB_PASSWORD" |wc -c)" -gt 0 ]; then
		docker login -u icingaadmin --password-stdin <<<"$DOCKER_HUB_PASSWORD"
		docker push "${TARGET}:$TAG"
		docker logout
	fi
}

case "$GITHUB_EVENT_NAME" in
	workflow_dispatch|schedule|release)
		case "$GITHUB_REF" in
			refs/tags/v*)
				MODE=release
				TAG=${GITHUB_REF#refs/tags/v}
				;;
			refs/heads/*)
				MODE=snapshot
				TAG=${GITHUB_REF#refs/heads/}
				# Remove everything up to the first slash to remove prefixes like "feature/"
				TAG=${TAG#*/}
				;;
			*)
				echo "Unknown ref: $GITHUB_REF" >&2
				false
				;;
		esac
		mkimg
		push
		;;
	*)
		echo "Unknown event: $GITHUB_EVENT_NAME" >&2
		false
		;;
esac
