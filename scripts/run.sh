#!/bin/bash

set -euo pipefail

ORIGINAL_ARGS=("$@")

show_usage() {
    echo "Usage: $0 [--docker]"
    echo
    echo "Run the ROS2 package."
    echo "  --docker, docker    Run package in Docker."
    echo "  -h, --help          Show this help message."
}

run_in_docker=false

while [[ $# -gt 0 ]]; do
    case "$1" in
    "--docker"|"docker")
        run_in_docker=true
        shift
        ;;
    "-h"|"--help")
        show_usage
        exit 0
        ;;
    *)
        show_usage
        exit 1
        ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ "$run_in_docker" = true ]; then
    echo "Running in Docker..."

    command_name=$(basename "$0")

    args=()
    for arg in "${ORIGINAL_ARGS[@]}"; do
        if [[ "$arg" != "--docker" && "$arg" != "docker" ]]; then
            args+=("$arg")
        fi
    done

    inner_command="./scripts/$command_name"
    for arg in "${args[@]}"; do
        inner_command+=" $(printf '%q' "$arg")"
    done

    docker_tty_args=()
    if [ -t 0 ]; then
        docker_tty_args=(-it)
    fi

    docker run --rm "${docker_tty_args[@]}" \
        -v "$WORKSPACE_DIR:/workspace" \
        -w /workspace \
        ros-human-builder \
        bash -c "$inner_command"

    exit 0
fi

if [ ! -f "$WORKSPACE_DIR/install/setup.bash" ]; then
    echo "ROS2 workspace is not built. Missing: $WORKSPACE_DIR/install/setup.bash"
    echo "Run ./scripts/build.sh first."
    exit 1
fi

set +u
source "$WORKSPACE_DIR/install/setup.bash"
set -u

ros2 run mini_car simple_controller &
ros2 launch mini_car_description display.launch.py &
wait