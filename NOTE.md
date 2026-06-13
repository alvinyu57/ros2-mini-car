# Learning Note

## Plan

[x] 1. Initialize ROS2 package
[x] 2. Implement simple_controller.cpp, publish /cmd_vel

1. Create mini_car.urdf.xacro to describe the mini_car model
1. Use robot_state_publisher to publish the robot description and TF tree.
1. Create a Gazebo launch file to spawn the mini car in a simulation world.
1. Add the Gazebo differential drive plugin to control the car using /cmd_vel.
1. Configure RViz to display the robot state, TF frames, and odometry.
1. Add a simulated LiDAR sensor to the mini car model.
1. Use SLAM Toolbox to build a map from simulated LiDAR data.
1. Add Navigation2 support for autonomous navigation.

## Initialization

1. Create ROS2 C++ Package

    ```bash
    cd src

    ros2 pkg create mini_car \
    --build-type ament_cmake \
    --dependencies rclcpp geometry_msgs sensor_msgs nav_msgs tf2 tf2_ros
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
    ament_target_dependencies(simple_controller rclcpp)

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

## Simple Controller

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

## Robot Model + TF

1. Create mini_car_description package

    ```bash
    cd src/

    ros2 pkg create mini_car_description \
      --build-type ament_cmake \
      --dependencies xacro robot_state_publisher joint_state_publisher joint_state_publisher_gui rviz2
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