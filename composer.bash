#!/bin/bash
set -exo pipefail

for d in icingaweb2 icingaweb2/modules/*; do
	pushd "$d"

	if [ -e composer.json ]; then
		composer install --no-dev --ignore-platform-reqs
	fi

	popd
done
