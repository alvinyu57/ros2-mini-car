#!/bin/bash

set -euo pipefail

docker run -v `pwd`:/home/$(whoami)/workspace \
    -w /home/$(whoami)/workspace \
    --rm -it \
    ros-human-builder