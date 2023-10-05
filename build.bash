#!/bin/bash
# Icinga Web 2 Docker image | (c) 2020 Icinga GmbH | GPLv2+
set -exo pipefail

IW2SRC="$1"
export BUILD_MODE="${2:-release}"
ACTION="${3:-local}"
TAG="${4:-test}"

if [ -z "$IW2SRC" ]; then
	cat <<EOF >&2
Usage: ${0} /icingaweb2/source/dir [release|snapshot [local|all|push [TAG]]]
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

OUR_DIR="$(realpath "$(dirname "$0")")"
COMMON_ARGS=(-t "icinga/icingaweb2:$TAG" --build-context "icingaweb2-git=$(realpath "$IW2SRC")/.git" --build-arg "BUILD_MODE=$BUILD_MODE" "$OUR_DIR")
BUILDX=(docker buildx build --platform "$(cat "${OUR_DIR}/platforms.txt")")

case "$ACTION" in
	all)
		"${BUILDX[@]}" "${COMMON_ARGS[@]}"
		;;
	push)
		"${BUILDX[@]}" --push "${COMMON_ARGS[@]}"
		;;
	*)
		docker buildx build --load "${COMMON_ARGS[@]}"
		;;
esac
