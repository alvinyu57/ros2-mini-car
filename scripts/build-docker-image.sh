#!/bin/bash

set -euo pipefail

docker build -t ros-human-builder \
    --build-arg UID=$(id -u) \
    --build-arg GID=$(id -g) \
    --build-arg USER=$(whoami) .