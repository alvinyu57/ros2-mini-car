#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$WORKSPACE_DIR/.env"

ros_distro="${ROS_DISTRO:-jazzy}"
docker_image_version="${DOCKER_IMAGE_VERSION:-latest}"

local_image_name="ros-${ros_distro}-builder"
gh_image_name="${GH_IMAGE_NAME:-ghcr.io/alvinyu57/${local_image_name}}"

docker pull "${gh_image_name}:${docker_image_version}"

docker tag \
    "${gh_image_name}:${docker_image_version}" \
    "${local_image_name}:${docker_image_version}"

docker rmi "${gh_image_name}:${docker_image_version}"
