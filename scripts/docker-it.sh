#!/bin/bash

set -euo pipefail

source .env
ros_distro="${ROS_DISTRO:-lyrical}"

docker run -v `pwd`:/home/$(whoami)/workspace \
    -w /home/$(whoami)/workspace \
    --rm -it \
    ros-${ros_distro}-builder:${DOCKER_IMAGE_VERSION}