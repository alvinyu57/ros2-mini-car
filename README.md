# ros2-lyrical-mini-car
A ROS 2 Lyrical C++ learning project for simulating and controlling an Ackermann-style mini car in Gazebo with RViz visualization.

## Environment Setup

```bash
sudo apt update
sudo apt install ros-lyrical-desktop

sudo apt install \
    ros-lyrical-gz-ros2-control \
    ros-lyrical-ros-gz-sim \
    ros-lyrical-ros-gz-bridge \
    ros-lyrical-ros2-control \
    ros-lyrical-ros2-controllers \
    ros-lyrical-ackermann-steering-controller \
    ros-lyrical-controller-manager \
    ros-lyrical-robot-state-publisher \
    ros-lyrical-joint-state-publisher-gui \
    ros-lyrical-xacro \
    ros-lyrical-geometry-msgs \
    ros-lyrical-nav-msgs \
    ros-lyrical-std-msgs \
    ros-lyrical-tf2-ros \
    python3-rosdep

```

## Scripts

1. Build docker image
    ```bash
    ./scripts/build-docker-image.sh
    ```
1. Pull docker image from GHCR
    ```bash
    ./scripts/pull-ghcr.sh
    ```
1. Build ROS2 package
    ```bash
    ./scripts/build-package.sh [--docker] [--test]
    #    --test, test        Run package tests after building.
    #    --docker, docker    Build package in Docker."
    ```
    The `--test` option runs the GoogleTest unit suite, controller configuration
    contract tests, and the ROS 2 ament linters.

    To run only the controller unit tests after a build:
    ```bash
    source install/setup.bash
    colcon test --packages-select mini_car_controller \
        --ctest-args -R test_twist_conversion
    colcon test-result --verbose
    ```
1. Run ROS2 package
    ```bash
    ./scripts/run.sh [--docker] [--headless|--gui]
    #    --docker, docker    Run package in Docker."
    #    --headless          Run Gazebo without the GUI."
    #    --gui               Run Gazebo with the GUI (default)."
    ```

1. Enter docker container
    ```bash
    ./scripts/docker-it.sh
    ```

1. Clean up
    ```bash
    ./scripts/cleanup.sh
    ```


## Learning Note

### Plan

- [x] Initialize ROS2 package
- [x] Implement `simple_controller.cpp` to publish `/cmd_vel`
- [x] Create `mini_car.urdf.xacro` to describe the mini car model
- [x] Use `robot_state_publisher` to publish the robot description and TF tree
- [x] Create a GZ Sim launch file to spawn the mini car in a simulation world
- [x] Add Gazebo Ackermann control using the ROS 2 `ackermann_steering_controller`
- [x] Verify `/odom`, `/tf`, and `/joint_states` from simulation
- [x] Configure RViz to display the robot model, TF frames, odometry, and joint states
- [x] Add a simulated LiDAR sensor to the mini car model
- [ ] Use SLAM Toolbox to build a map from simulated LiDAR data
- [ ] Add Navigation2 support for autonomous navigation

### Initialization

1. Create ROS2 C++ Package

    ```bash
    cd src

    ros2 pkg create mini_car \
    --build-type ament_cmake \
    --dependencies rclcpp geometry_msgs
    ```

1. C++ MVP

    src/mini_car/src/simple_controller.cpp
    ```CPP
    #include "rclcpp/rclcpp.hpp"

    class SimpleController : public rclcpp::Node
    {
    public:
    SimpleController() : Node("simple_controller")
    {
        RCLCPP_INFO(this->get_logger(), "Mini car simple controller started.");
    }
    };

    int main(int argc, char ** argv)
    {
    rclcpp::init(argc, argv);
    rclcpp::spin(std::make_shared<SimpleController>());
    rclcpp::shutdown();
    return 0;
    }
    ```

    src/mini_car/CMakeLists.txt
    ```cmake
    add_executable(simple_controller src/simple_controller.cpp)
    target_link_libraries(simple_controller
      PRIVATE
        rclcpp::rclcpp
        geometry_msgs::geometry_msgs
    )

    install(TARGETS
    simple_controller
    DESTINATION lib/${PROJECT_NAME}
    )
    ```

1. Build the package
    ```bash
    colcon build
    ```

1. setup and run
    ```bash
    . install/setup.bash
    ros2 run mini_car simple_controller
    ```

### Simple Controller

1. Publish /cmd_vel

    src/mini_car/src/simple_controller.cpp
    ```CPP
    class SimpleController : public rclcpp::Node
    {
    public:
      SimpleController()
      : Node("simple_controller")
      {
        cmd_vel_pub_ = this->create_publisher<geometry_msgs::msg::Twist>("/cmd_vel", 10);

        timer_ =
          this->create_wall_timer(
          std::chrono::milliseconds(100),
          std::bind(&SimpleController::publish_cmd_vel, this));

        RCLCPP_INFO(this->get_logger(), "Mini car simple controller started.");
      }

    private:
      void publish_cmd_vel()
      {
        auto msg = geometry_msgs::msg::Twist();

        msg.linear.x = 0.2;
        msg.linear.y = 0.0;
        msg.linear.z = 0.0;

        msg.angular.x = 0.0;
        msg.angular.y = 0.0;
        msg.angular.z = 0.3;

        cmd_vel_pub_->publish(msg);

        RCLCPP_INFO_THROTTLE(
          this->get_logger(),
          *this->get_clock(),
          1000,
          "Publishing /cmd_vel: linear.x=%.2f, angular.z=%2f",
          msg.linear.x,
          msg.angular.z
        );
      }

      rclcpp::Publisher<geometry_msgs::msg::Twist>::SharedPtr cmd_vel_pub_;
      rclcpp::TimerBase::SharedPtr timer_;
    };
    ```

### Robot Model + TF

1. Create mini_car_description package

    ```bash
    cd src/

    ros2 pkg create mini_car_description \
      --build-type ament_cmake \
      --dependencies ament_index_python launch launch_ros xacro robot_state_publisher joint_state_publisher_gui rviz2
    ```
1. Create mini_car.urdf.xacro to describe the mini_car model
1. Create launch file to publish robot description and TF tree
1. Configure RViz to visualize the robot state and TF frames
1. Compile and run the description package

    ```bash
    rosdep install --from-paths src --ignore-src -r -y

    colcon build --packages-select mini_car_description

    source install/setup.bash
    ```
1. Verify xacro

    ```bash
    ros2 run xacro xacro \
      src/mini_car_description/urdf/mini_car.urdf.xacro \
      -o /tmp/mini_car.urdf

    check_urdf /tmp/mini_car.urdf
    ```

1. Start RViz + TF

    ```bash
    ros2 launch mini_car_description display.launch.py
    ```

1. Check TF tree

    ```bash
    ros2 run tf2_tools view_frames
    ```

### Support Gazebo

1. Create mini_car_gazebo

    ```bash
    cd src/

    ros2 pkg create mini_car_gazebo \
      --build-type ament_cmake \
      --dependencies ament_index_python launch launch_ros ros_gz_sim xacro robot_state_publisher mini_car_description
    ```

1. Create Gazebo World `src/mini_car_gazebo/worlds/empty.world`
1. Modify `src/mini_car_description/urdf/mini_car.urdf.xacro`
1. Create Gazebo launch file `src/mini_car_gazebo/launch/gazebo.launch.py`
1. Create `src/mini_car_gazebo/config/ros2_control.yaml`
1. Build and run mini_car_gazebo
    ```bash
    ros2 launch mini_car_gazebo gazebo_ackermann.launch.py gui:="${gazebo_gui}"
    ```
1. Manipulate the mini_car
    ```bash
    # Going to left
    ros2 topic pub /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5}, angular: {z: 0.3}}" -r 10

    # Going to right
    ros2 topic pub /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5}, angular: {z: -0.3}}" -r 10
    ```

### Ackermann Simulation + RViz

The Ackermann simulation launch file starts the whole visualization pipeline:

```bash
ros2 launch mini_car_gazebo gazebo_ackermann.launch.py gui:=true rviz:=true
```

The important nodes and topics are:

- `robot_state_publisher` publishes the URDF model on `/robot_description` and fixed/movable TF links from `/joint_states`.
- `joint_state_broadcaster` publishes `/joint_states` from the Gazebo `ros2_control` hardware interface.
- `cmd_vel_adapter` converts `/cmd_vel` from `Twist` to the stamped reference expected by the ROS 2 controller.
- `ackermann_steering_controller` owns the four joint command interfaces, publishes `/odom`, and broadcasts `odom -> base_footprint`.
- `rviz2` loads `src/mini_car_description/rviz/gazebo_ackermann.rviz`.

The command path is:

```text
/cmd_vel (Twist)
└── cmd_vel_adapter
    └── /ackermann_steering_controller/reference (TwistStamped)
        └── ackermann_steering_controller
```
To control the mini car, there are two options:

1. Publish a `Twist` message on `/cmd_vel`:

    ```bash
    ros2 topic pub /cmd_vel geometry_msgs/msg/Twist "{linear: {x: 0.5}, angular: {z: 0.3}}" -r 10
    ```

1. Use the `teleop_twist_keyboard` node to control the mini car interactively:

    ```bash
    ros2 run teleop_twist_keyboard teleop_twist_keyboard
    ```

    Notice that the `teleop_twist_keyboard' publishes on `/cmd_vel` at 10 Hz, which is the same rate as the `cmd_vel_adapter` timer. And the safety timeout in `ackermann_steering_controller` is set to 5 seconds, so if you stop sending commands, the mini car will stop after 5 seconds.


RViz is configured with:

- Fixed Frame: `odom`
- RobotModel: `/robot_description`
- TF display: all frames enabled
- Odometry display: `/odom`
- LaserScan display: `/scan`

`odom` is used as the RViz fixed frame because the car moves relative to the world. The robot model then follows the dynamic TF chain:

```text
odom
└── base_footprint
    └── base_link
        ├── front_left_steering_link
        ├── front_right_steering_link
        ├── rear_left_wheel_link
        ├── rear_right_wheel_link
        └── lidar_link
```

RViz is delayed in the launch file so it starts after the odometry publisher. Without that delay, RViz can open before the `odom` frame exists and show invalid displays at startup.

### LiDAR Scan

The Ackermann simulation includes a simulated 2D GPU LiDAR mounted on `lidar_link`.
Gazebo publishes the scan on `/scan`, and `ros_gz_bridge` exposes it to ROS 2 as:

```text
/scan sensor_msgs/msg/LaserScan
```

The scan is configured for 10 Hz, 720 horizontal samples, 270 degrees of view, and an 0.08 m to 8.0 m range.
The world includes a few static obstacles in front of the start pose so scan returns are visible immediately.

Launch the simulation:

```bash
ros2 launch mini_car_gazebo gazebo_ackermann.launch.py gui:=true rviz:=true
```

Check the ROS 2 scan topic:

```bash
ros2 topic echo /scan --once
ros2 topic hz /scan
ros2 topic info /scan
ros2 run tf2_ros tf2_echo odom lidar_link
```

Check the Gazebo scan topic directly:

```bash
gz topic -l | grep scan
gz topic -e -t /scan
```

### Runtime Checks

Use these checks when RViz opens but the displays are invalid:

```bash
ros2 topic list
ros2 topic echo /clock --once
ros2 topic echo /joint_states --once
ros2 topic echo /odom --once
ros2 topic echo /scan --once
ros2 run tf2_ros tf2_echo odom base_footprint
```

Expected results:

- `/clock` is publishing when Gazebo is running.
- `/joint_states` contains steering and wheel joint names.
- `/odom` is publishing from `ackermann_steering_controller`.
- `/scan` is publishing `sensor_msgs/msg/LaserScan` with `header.frame_id: lidar_link`.
- `tf2_echo odom base_footprint` returns a transform.

If `/odom` is missing, check that `ackermann_steering_controller` is active. If `/joint_states` is missing, check that `joint_state_broadcaster` loaded successfully. If TF is incomplete, check that every movable URDF joint that RViz needs has a state interface in `mini_car.urdf.xacro`.

### Build Notes

The Docker package build mounts the workspace at the same absolute path inside the container. This avoids stale CMake cache errors when switching between host and Docker builds.

```bash
./scripts/build-package.sh --docker --test
```
