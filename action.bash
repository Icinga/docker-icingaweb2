#!/bin/bash
set -exo pipefail

TARGET=icinga/icingaweb2

mkimg () {
	test -n "$TAG"

	node /actions/checkout/dist/index.js |grep -vFe ::add-matcher::

	git archive --prefix=icingaweb2/ HEAD |tar -x

	/get-mods.sh "$1"
	/composer.bash
	patch -d icingaweb2 -p0 < /icingaweb2.patch

	docker build -f /Dockerfile -t "${TARGET}:$TAG" .

	STATE_isPost=1 node /actions/checkout/dist/index.js

	docker save "${TARGET}:$TAG" |gzip >docker-save.tgz
	INPUT_NAME=docker-image INPUT_PATH=docker-save.tgz node /actions/upload-artifact/dist/index.js
	rm docker-save.tgz
}

push () {
	test -n "$TAG"

	if [ "$(tr -d '\n' <<<"$DOCKER_HUB_PASSWORD" |wc -c)" -gt 0 ]; then
		docker login -u icingaadmin --password-stdin <<<"$DOCKER_HUB_PASSWORD"
		docker push "${TARGET}:$TAG"
		docker logout
	fi
}

re_docker_tag="^refs/(heads|tags)/([^/]+|[a-z]+/(.*))$"

case "$GITHUB_EVENT_NAME" in
	workflow_dispatch|schedule|release)
		[[ "$GITHUB_REF" =~ $re_docker_tag ]]
		if [ -n "${BASH_REMATCH[3]}" ]; then
			TAG="${BASH_REMATCH[3]}"
		else
			TAG="${BASH_REMATCH[2]}"
		fi
		mkimg
		push
		;;
	*)
		echo "Unknown event: $GITHUB_EVENT_NAME" >&2
		false
		;;
esac
