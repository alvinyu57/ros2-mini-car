FROM osrf/ros:humble-desktop-full

ARG USER=user
ARG UID=1000
ARG GID=1000

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-humble-gazebo-ros-pkgs \
        ros-humble-robot-state-publisher \
        ros-humble-joint-state-publisher \
        ros-humble-joint-state-publisher-gui \
        ros-humble-xacro \
        ros-humble-rviz2 \
        ros-humble-ros2-control \
        ros-humble-ros2-controllers \
        ros-humble-diff-drive-controller \
        ros-humble-joint-state-broadcaster \
        ros-humble-slam-toolbox \
        ros-humble-navigation2 \
        ros-humble-nav2-bringup \
        ros-humble-geometry-msgs \
        ros-humble-tf2-tools \
        liburdfdom-tools \
        python3-rosdep

RUN groupadd -g $GID -o $USER && \
    useradd -m -u $UID -g $GID -o -s /bin/bash $USER

USER ${UID}:${GID}
WORKDIR /home/${USER}