#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$WORKSPACE_DIR/.env"

ros_distro="${ROS_DISTRO:-jazzy}"
docker_image_version="${DOCKER_IMAGE_VERSION:-latest}"

local_image_name="ros-${ros_distro}-builder"
gh_image_name="${GH_IMAGE_NAME:-}"

repo_full_name="${GITHUB_REPOSITORY:-unknown/unknown}"
git_sha="${GITHUB_SHA:-$(git -C "$WORKSPACE_DIR" rev-parse HEAD 2>/dev/null || echo unknown)}"

tags=(
    -t "${local_image_name}:${docker_image_version}"
)

if [[ -n "${gh_image_name}" ]]; then
    tags+=(
        -t "${gh_image_name}:${docker_image_version}"
    )
fi

docker build \
    "${tags[@]}" \
    --build-arg UID="$(id -u)" \
    --build-arg GID="$(id -g)" \
    --build-arg USER="$(whoami)" \
    --label "org.opencontainers.image.title=${local_image_name}" \
    --label "org.opencontainers.image.description=ROS ${ros_distro} builder image for local development and GitHub Actions CI" \
    --label "org.opencontainers.image.source=https://github.com/${repo_full_name}" \
    --label "org.opencontainers.image.revision=${git_sha}" \
    --label "org.opencontainers.image.version=${docker_image_version}" \
    "$WORKSPACE_DIR"
