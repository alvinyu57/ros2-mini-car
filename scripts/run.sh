#!/bin/bash

set -euo pipefail

ORIGINAL_ARGS=("$@")

show_usage() {
    echo "Usage: $0 [--docker] [--headless|--gui]"
    echo
    echo "Run the ROS2 package."
    echo "  --docker, docker    Run package in Docker."
    echo "  --headless          Run Gazebo without the GUI."
    echo "  --gui               Run Gazebo with the GUI (default)."
    echo "  -h, --help          Show this help message."
}

run_in_docker=false
gazebo_gui=true
ros_distro="${ROS_DISTRO:-lyrical}"
source .env

while [[ $# -gt 0 ]]; do
    case "$1" in
    "--docker"|"docker")
        run_in_docker=true
        shift
        ;;
    "--headless")
        gazebo_gui=false
        shift
        ;;
    "--gui")
        gazebo_gui=true
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

    docker_display_args=()
    if [ -n "${DISPLAY:-}" ]; then
        docker_display_args+=(
            -e "DISPLAY=${DISPLAY}"
            -e "QT_X11_NO_MITSHM=1"
        )

        if [ -d /tmp/.X11-unix ]; then
            docker_display_args+=(-v /tmp/.X11-unix:/tmp/.X11-unix:rw)
        fi

        if [ -n "${XAUTHORITY:-}" ] && [ -f "${XAUTHORITY}" ]; then
            docker_display_args+=(
                -e "XAUTHORITY=${XAUTHORITY}"
                -v "${XAUTHORITY}:${XAUTHORITY}:ro"
            )
        fi
    fi

    docker_device_args=()
    if [ -e /dev/dri ]; then
        docker_device_args+=(--device /dev/dri)
    fi

    docker run --rm "${docker_tty_args[@]}" \
        "${docker_display_args[@]}" \
        "${docker_device_args[@]}" \
        -v "$WORKSPACE_DIR:/workspace" \
        -w /workspace \
        ros-${ros_distro}-builder:${DOCKER_IMAGE_VERSION} \
        bash -c "$inner_command"

    exit 0
fi

if [ ! -f "$WORKSPACE_DIR/install/setup.bash" ]; then
    echo "ROS2 workspace is not built. Missing: $WORKSPACE_DIR/install/setup.bash"
    echo "Run ./scripts/build-package.sh first."
    exit 1
fi

if [ ! -f "/opt/ros/${ros_distro}/setup.bash" ]; then
    echo "ROS distro '${ros_distro}' is not installed at /opt/ros/${ros_distro}."
    echo "Set ROS_DISTRO to an installed distro or build the Docker image first."
    exit 1
fi

if [ -n "${SNAP:-}" ]; then
    real_home="${SNAP_REAL_HOME:-$HOME}"

    export HOME="$real_home"
    export XDG_DATA_HOME="$HOME/.local/share"

    if [ -n "${XDG_DATA_DIRS_VSCODE_SNAP_ORIG:-}" ]; then
        export XDG_DATA_DIRS="$XDG_DATA_DIRS_VSCODE_SNAP_ORIG"
    fi

    if [ -n "${XDG_CONFIG_DIRS_VSCODE_SNAP_ORIG:-}" ]; then
        export XDG_CONFIG_DIRS="$XDG_CONFIG_DIRS_VSCODE_SNAP_ORIG"
    fi

    for snap_var in ${!SNAP@}; do
        unset "$snap_var"
    done

    unset GIO_LAUNCHED_DESKTOP_FILE
    unset GIO_LAUNCHED_DESKTOP_FILE_PID
    unset GIO_MODULE_DIR
    unset GTK_EXE_PREFIX
    unset GTK_IM_MODULE_FILE
    unset GTK_MODULES
    unset GTK_PATH
    unset LOCPATH
    unset QT_PLUGIN_PATH
    unset QML2_IMPORT_PATH
    unset LD_PRELOAD
fi

set +u
source "/opt/ros/${ros_distro}/setup.bash"
source "$WORKSPACE_DIR/install/setup.bash"
set -u

# ros2 run mini_car simple_controller &
# ros2 launch mini_car_description display.launch.py &
ros2 launch mini_car_gazebo gazebo.launch.py gui:="${gazebo_gui}" &
wait
