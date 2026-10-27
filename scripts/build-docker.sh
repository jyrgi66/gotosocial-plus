#!/bin/sh

set -e

# Log and execute provided args.
log_exec() { echo "$ ${*}"; "$@"; }

# Always run from the repository root, regardless of caller's cwd.
cd "$(dirname "$0")/.."

# Match build.sh's own version resolution so the binary and the
# image tag always agree, eg. "0.22.3-plus.8".
VERSION="${VERSION:-$(git describe --tags --abbrev=0)}"
export VERSION

# Build the gotosocial binary expected by the Dockerfile.
log_exec ./scripts/build.sh

# web/assets/swagger.yaml is excluded from version control (see
# .gitignore) but the Dockerfile's executor stage expects it to be
# present alongside the other web assets.
log_exec cp docs/api/swagger.yaml web/assets/swagger.yaml

IMAGE_TAG="${IMAGE_TAG:-gotosocial-plus:${VERSION#v}}"

# Preserve a previously built image under the same tag, so it
# doesn't just turn into a dangling, untagged image once the new
# build below replaces the tag.
if docker image inspect "${IMAGE_TAG}" >/dev/null 2>&1; then
    log_exec docker tag "${IMAGE_TAG}" "${IMAGE_TAG}-previous"
fi

# Any extra arguments are passed through to `docker buildx build`,
# eg. IMAGE_TAG=foo ./scripts/build-docker.sh --platform linux/amd64,linux/arm64
log_exec docker buildx build -t "${IMAGE_TAG}" "$@" .
