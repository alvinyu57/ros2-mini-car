#!/bin/bash

set -euo pipefail

source .env

ros_distro="${ROS_DISTRO:-lyrical}"
docker_image_version="${DOCKER_IMAGE_VERSION:-latest}"

docker run -v `pwd`:/home/$(whoami)/workspace \
    --user "$(id -u):$(id -g)" \
    -w /home/$(whoami)/workspace \
    --rm -it \
    ros-${ros_distro}-builder:${docker_image_version}