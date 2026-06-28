#!/bin/bash

set -euo pipefail

ROS_DISTRO=lyrical

docker run -v `pwd`:/home/$(whoami)/workspace \
    -w /home/$(whoami)/workspace \
    --rm -it \
    ros-${ROS_DISTRO}-builder