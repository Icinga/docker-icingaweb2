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

if ! docker version; then
	echo 'Docker not found' >&2
	false
fi

if ! docker buildx version; then
	echo '"docker buildx" not found (see https://docs.docker.com/buildx/working-with-buildx/ )' >&2
	false
fi

IW2SRC="$(realpath "$IW2SRC")"
OUR_DIR="$(realpath "$(dirname "$0")")"
OUR_FILES="$(mktemp -d)"

pushd "$OUR_FILES"

git -C "$IW2SRC" archive --prefix=icingaweb2/ HEAD |tar -x
"${OUR_DIR}/get-mods.sh" "$BUILD_MODE"
docker run --rm -iv "$(pwd):/iw2" -w /iw2 composer:lts bash <"${OUR_DIR}/composer.bash"

popd

docker buildx build --load -t icinga/icingaweb2 --build-context "icinga-files=$OUR_FILES" "$OUR_DIR"
