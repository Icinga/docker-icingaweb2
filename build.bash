#!/bin/bash
# Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+
set -exo pipefail

IW2SRC="$1"
export BUILD_MODE="${2:-release}"

if [ -z "$IW2SRC" ]; then
	cat <<EOF >&2
Usage: ${0} /icingaweb2/source/dir
EOF

	false
fi

IW2SRC="$(realpath "$IW2SRC")"
BLDCTX="$(realpath "$(dirname "$0")")"

docker build -f "${BLDCTX}/action.Dockerfile" -t icinga/icingaweb2-builder "$BLDCTX"

docker run --rm -i \
	-v "${IW2SRC}:/iw2src:ro" \
	-v "${BLDCTX}:/bldctx:ro" \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-e BUILD_MODE \
	icinga/icingaweb2-builder bash <<EOF
set -exo pipefail

git -C /iw2src archive --prefix=iw2cp/icingaweb2/ HEAD |tar -xC /
cd /iw2cp

/bldctx/get-mods.sh "$BUILD_MODE"
/bldctx/composer.bash
patch -d icingaweb2 -p0 < /bldctx/icingaweb2.patch

cp -r /entrypoint /bldctx/{php.ini,uncomment-locales.pl} .
docker build -f /bldctx/Dockerfile -t icinga/icingaweb2 .
EOF
