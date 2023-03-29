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

docker buildx build --load -t icinga/icingaweb2 --build-context "icingaweb2-git=$(realpath "$IW2SRC")/.git" --build-arg "BUILD_MODE=$BUILD_MODE" "$(realpath "$(dirname "$0")")"
