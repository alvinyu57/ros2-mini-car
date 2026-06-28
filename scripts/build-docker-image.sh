#!/bin/bash

set -euo pipefail

ROS_DISTRO=lyrical

docker build -t ros-${ROS_DISTRO}-builder \
    --build-arg UID=$(id -u) \
    --build-arg GID=$(id -g) \
    --build-arg USER=$(whoami) .