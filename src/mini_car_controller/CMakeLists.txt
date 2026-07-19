cmake_minimum_required(VERSION 3.10)
project(mini_car_controller)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(geometry_msgs REQUIRED)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  # the following line skips the linter which checks for copyrights
  # comment the line when a copyright and license is added to all source files
  set(ament_cmake_copyright_FOUND TRUE)
  # the following line skips cpplint (only works in a git repo)
  # comment the line when this package is in a git repo and when
  # a copyright and license is added to all source files
  set(ament_cmake_cpplint_FOUND TRUE)
  ament_lint_auto_find_test_dependencies()
endif()

add_executable(simple_controller src/simple_controller.cpp)
target_link_libraries(simple_controller
  PRIVATE
    rclcpp::rclcpp
    geometry_msgs::geometry_msgs
)

add_executable(ackermann_controller src/ackermann_controller.cpp)
target_link_libraries(ackermann_controller
  PRIVATE
    rclcpp::rclcpp
    geometry_msgs::geometry_msgs
)

install(TARGETS simple_controller ackermann_controller
  DESTINATION lib/${PROJECT_NAME}
)

ament_package()
