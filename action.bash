#!/bin/bash
# Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+
set -exo pipefail

TARGET=icinga/icingaweb2

mkimg () {
	test -n "$TAG"

	node /actions/checkout/dist/index.js |grep -vFe ::add-matcher::

	git archive --prefix=icingaweb2/ HEAD |tar -x

	/get-mods.sh "$1"
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

# Matches Git references that start with `refs/` and then continue with `heads/` or `tags/`.
# An optional `v` that follows is ignored. Then the tag or branch name is captured. These may
# be of the following forms and what is captured of them:
#
#  - <form> -> g1(´heads´ or ´tags´),g2,g3
#
#  - v1 -> ,1,
#  - v1.1 -> ,1.1,
#  - v1.2-1 -> ,1.2-1,
#  - 2.0.0 -> ,2.0.0,
#  - master -> ,master,
#  - main -> ,main,
#  - something -> ,something,
#  - verbose -> ,erbose,
#  - vault -> ,ault,
#  - fix/error-123 -> ,fix/error-123,error-123
#  - fix/mistake-456 -> ,fix/mistake-456,mistake-456
#  - fix/climate -> ,fix/climate,climate
#  - bugfix/legacy -> ,bugfix/legacy,legacy
#  - feature/green-energy -> ,feature/green-energy,green-energy
#  - feature/verbosity -> ,feature/verbosity,verbosity
#  - viehture/bullshit -> ,viehture/bullshit,bullshit
#
re_docker_tag="^refs/(heads|tags)/v?([^/]+|[a-z]+/(.*))$"

case "$GITHUB_EVENT_NAME" in
	workflow_dispatch|schedule|release)
		[[ "$GITHUB_REF" =~ $re_docker_tag ]]
		if [ -n "${BASH_REMATCH[3]}" ]; then
			TAG="${BASH_REMATCH[3]}"
		else
			TAG="${BASH_REMATCH[2]}"
		fi

		if [ "${BASH_REMATCH[1]}" = heads ]; then
			BRANCH="${BASH_REMATCH[2]}"
		fi

		mkimg "$BRANCH"
		push
		;;
	*)
		echo "Unknown event: $GITHUB_EVENT_NAME" >&2
		false
		;;
esac
