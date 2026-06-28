# ros2-lyrical-mini-car
A ROS 2 Lyrical C++ learning project for simulating and controlling a differential-drive mini car in Gazebo with RViz visualization.

## Environment Setup

```bash
sudo apt update
sudo apt install ros-lyrical-desktop

sudo apt install \
  ros-lyrical-ros-gz-sim \
  ros-lyrical-ament-index-python \
  ros-lyrical-launch \
  ros-lyrical-launch-ros \
  ros-lyrical-robot-state-publisher \
  ros-lyrical-joint-state-publisher-gui \
  ros-lyrical-xacro \
  ros-lyrical-rviz2 \
  ros-lyrical-geometry-msgs \
  ros-lyrical-tf2-tools \
  liburdfdom-tools \
  python3-rosdep

```

## Scripts

1. Build docker image
    ```bash
    ./scripts/build-docker-image.sh
    ```
1. Pull docker image from GHCR
    ```bash
    ./scripts/pull-docker-image.sh
    ```
1. Build ROS2 package
    ```bash
    ./scripts/build-package.sh [--docker] [--test]
    #    --test, test        Run package tests after building.
    #    --docker, docker    Build package in Docker."
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
    ./scripts/pull-docker-image.sh
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
- [x] Create a Gazebo launch file to spawn the mini car in a simulation world
- [ ] Add the Gazebo Ackermann steering plugin to control the car using `/cmd_vel`
- [ ] Verify `/odom`, `/tf`, and `/joint_states` from the Gazebo simulation
- [ ] Configure RViz to display the robot model, TF frames, odometry, and joint states
- [ ] Add a simulated LiDAR sensor to the mini car model
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
