#include <chrono>
#include <functional>
#include <memory>

#include "geometry_msgs/msg/twist_stamped.hpp"
#include "rclcpp/rclcpp.hpp"

class AckermannController : public rclcpp::Node
{
public:
  AckermannController()
  : Node("ackermann_controller")
  {
    linear_speed_ = declare_parameter<double>("linear_speed", 0.2);
    angular_speed_ = declare_parameter<double>("angular_speed", 0.3);

    cmd_vel_pub_ =
      create_publisher<geometry_msgs::msg::TwistStamped>("/cmd_vel", 10);

    timer_ = create_wall_timer(
      std::chrono::milliseconds(100),
      std::bind(&AckermannController::publish_cmd_vel, this));

    RCLCPP_INFO(get_logger(), "Mini car stamped command publisher started.");
  }

private:
  void publish_cmd_vel()
  {
    geometry_msgs::msg::TwistStamped msg;
    msg.header.stamp = now();
    msg.twist.linear.x = linear_speed_;
    msg.twist.angular.z = angular_speed_;
    cmd_vel_pub_->publish(msg);

    RCLCPP_INFO_THROTTLE(
      get_logger(), *get_clock(), 1000,
      "Publishing stamped /cmd_vel: linear.x=%.2f, angular.z=%.2f",
      msg.twist.linear.x, msg.twist.angular.z);
  }

  rclcpp::Publisher<geometry_msgs::msg::TwistStamped>::SharedPtr cmd_vel_pub_;
  rclcpp::TimerBase::SharedPtr timer_;
  double linear_speed_{0.2};
  double angular_speed_{0.3};
};

int main(int argc, char ** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<AckermannController>());
  rclcpp::shutdown();
  return 0;
}
