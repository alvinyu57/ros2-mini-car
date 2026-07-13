cmake_minimum_required(VERSION 3.10)
project(mini_car_controller)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# find dependencies
find_package(ament_cmake REQUIRED)
find_package(builtin_interfaces REQUIRED)
find_package(rclcpp REQUIRED)
find_package(geometry_msgs REQUIRED)

add_library(twist_conversion STATIC src/twist_conversion.cpp)
target_include_directories(twist_conversion
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
)
target_link_libraries(twist_conversion
  PUBLIC
    builtin_interfaces::builtin_interfaces
    geometry_msgs::geometry_msgs
)

if(BUILD_TESTING)
  find_package(ament_cmake_gtest REQUIRED)
  find_package(ament_lint_auto REQUIRED)
  # the following line skips the linter which checks for copyrights
  # comment the line when a copyright and license is added to all source files
  set(ament_cmake_copyright_FOUND TRUE)
  # the following line skips cpplint (only works in a git repo)
  # comment the line when this package is in a git repo and when
  # a copyright and license is added to all source files
  set(ament_cmake_cpplint_FOUND TRUE)
  ament_lint_auto_find_test_dependencies()

  ament_add_gtest(test_twist_conversion
    test/test_twist_conversion.cpp
  )
  target_link_libraries(test_twist_conversion twist_conversion)
endif()

add_executable(simple_controller src/simple_controller.cpp)
target_link_libraries(simple_controller
  PRIVATE
    rclcpp::rclcpp
    geometry_msgs::geometry_msgs
)

add_executable(cmd_vel_adapter src/cmd_vel_adapter.cpp)
target_link_libraries(cmd_vel_adapter
  PRIVATE
    twist_conversion
    rclcpp::rclcpp
    geometry_msgs::geometry_msgs
)

install(TARGETS simple_controller cmd_vel_adapter
  DESTINATION lib/${PROJECT_NAME}
)

ament_package()
