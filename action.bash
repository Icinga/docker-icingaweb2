#!/bin/bash
set -exo pipefail

TARGET=icinga/icingaweb2

mkimg () {
	test -n "$TAG"

	node /actions/checkout/dist/index.js |grep -vFe ::add-matcher::

	git archive --prefix=icingaweb2/ HEAD |tar -x
	/get-mods.sh

	for d in icingaweb2 icingaweb2/modules/*; do
		pushd "$d"

		if [ -e composer.json ]; then
			composer install --no-dev --ignore-platform-reqs
		fi

		popd
	done

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

case "$GITHUB_EVENT_NAME" in
	pull_request)
		grep -qEe '^refs/pull/[0-9]+' <<<"$GITHUB_REF"
		TAG="pr$(grep -oEe '[0-9]+' <<<"$GITHUB_REF")"
		mkimg
		;;
	push)
		grep -qEe '^refs/heads/.' <<<"$GITHUB_REF"
		TAG="$(cut -d / -f 3- <<<"$GITHUB_REF")"
		mkimg
		push
		;;
	release)
		grep -qEe '^refs/tags/v[0-9]' <<<"$GITHUB_REF"
		TAG="$(cut -d v -f 2- <<<"$GITHUB_REF")"
		mkimg
		push
		;;
	*)
		echo "Unknown event: $GITHUB_EVENT_NAME" >&2
		false
		;;
esac
