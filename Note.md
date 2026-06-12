# Learning Note

## Plan

[x] 1. Initialize ROS2 package

1. Implement simple_controller.cpp, publish /cmd_vel
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