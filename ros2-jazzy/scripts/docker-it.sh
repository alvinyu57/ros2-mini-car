#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$WORKSPACE_DIR/.env"

ros_distro="${ROS_DISTRO:-jazzy}"
docker_image_version="${DOCKER_IMAGE_VERSION:-latest}"

docker run -v "$WORKSPACE_DIR:/workspace" \
    --user "$(id -u):$(id -g)" \
    -w /workspace \
    --rm -it \
    ros-${ros_distro}-builder:${docker_image_version}
