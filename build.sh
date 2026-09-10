#!/usr/bin/env bash
# Build the images locally.
#
#     bash build.sh [tag] [platform]
#
# base is shared; ci and devel are SIBLINGS built from it, not a chain:
#
#     base   build tools + Python venv
#     ├─ ci     + Zephyr SDK and tree baked in   -> GitHub Actions only
#     └─ devel  + flashing tools, runner, editor, /opt/devcontainer scripts
#
# ci is large (~14 GB) and only GitHub Actions consumes it, so it is skipped
# unless asked for:
#
#     WITH_CI=1 bash build.sh
#
# .github/workflows/publish-images.yml builds the same images for GHCR and
# .devcontainer/devcontainer.json inlines the base+devel commands, so keep the
# three in step.
set -euo pipefail

cd "$(dirname "$0")"
# shellcheck source=versions.env
source ./versions.env

TAG="${1:-local}"
PLATFORM="${2:-}"
PLATFORM_ARG=()
[ -n "$PLATFORM" ] && PLATFORM_ARG=(--platform "$PLATFORM")

build() {
    local file="$1" image="$2"
    shift 2
    echo "=== $file -> $image"
    docker build "${PLATFORM_ARG[@]}" -f "$file" -t "$image" "$@" .
}

build Dockerfile.base "zephyr-devcontainer-base:${TAG}"

build Dockerfile.devel "zephyr-devcontainer-devel:${TAG}" \
    --build-arg "BASE_IMAGE=zephyr-devcontainer-base:${TAG}"

if [ -n "${WITH_CI:-}" ]; then
    build Dockerfile.ci "zephyr-devcontainer-ci:${TAG}" \
        --build-arg "BASE_IMAGE=zephyr-devcontainer-base:${TAG}" \
        --build-arg "ZEPHYR_VERSION=${ZEPHYR_VERSION}" \
        --build-arg "ZSDK_VERSION=${ZSDK_VERSION}" \
        --build-arg "ZSDK_TOOLCHAINS=${ZSDK_TOOLCHAINS}" \
        --build-arg "ZEPHYR_BLOBS=${ZEPHYR_BLOBS:-}"
fi

echo "=== ready: zephyr-devcontainer-devel:${TAG}"
