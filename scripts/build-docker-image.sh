#!/bin/bash

set -euo pipefail

source .env
ros_distro="${ROS_DISTRO:-lyrical}"

docker build -t ros-${ros_distro}-builder:${DOCKER_IMAGE_VERSION} \
    --build-arg UID=$(id -u) \
    --build-arg GID=$(id -g) \
    --build-arg USER=$(whoami) .