ARG ROS_DISTRO=lyrical
FROM osrf/ros:${ROS_DISTRO}-desktop-full

ARG ROS_DISTRO
ARG USER=user
ARG UID=1000
ARG GID=1000

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-${ROS_DISTRO}-ros-gz-sim \
        ros-${ROS_DISTRO}-ament-index-python \
        ros-${ROS_DISTRO}-launch \
        ros-${ROS_DISTRO}-launch-ros \
        ros-${ROS_DISTRO}-robot-state-publisher \
        ros-${ROS_DISTRO}-joint-state-publisher-gui \
        ros-${ROS_DISTRO}-xacro \
        ros-${ROS_DISTRO}-rviz2 \
        ros-${ROS_DISTRO}-geometry-msgs \
        ros-${ROS_DISTRO}-tf2-tools \
        libxcb-cursor0 \
        liburdfdom-tools \
        python3-rosdep

RUN groupadd -g $GID -o $USER && \
    useradd -m -u $UID -g $GID -o -s /bin/bash $USER

USER ${UID}:${GID}
WORKDIR /home/${USER}
