#include <functional>
#include <memory>

#include "geometry_msgs/msg/twist.hpp"
#include "geometry_msgs/msg/twist_stamped.hpp"
#include "mini_car_controller/twist_conversion.hpp"
#include "rclcpp/rclcpp.hpp"

class CmdVelAdapter : public rclcpp::Node
{
public:
  CmdVelAdapter()
  : Node("cmd_vel_adapter")
  {
    reference_pub_ = create_publisher<geometry_msgs::msg::TwistStamped>(
      "/ackermann_steering_controller/reference", 10);

    cmd_vel_sub_ = create_subscription<geometry_msgs::msg::Twist>(
      "/cmd_vel", 10,
      std::bind(&CmdVelAdapter::cmd_vel_callback, this, std::placeholders::_1));

    RCLCPP_INFO(
      get_logger(),
      "Forwarding /cmd_vel to /ackermann_steering_controller/reference");
  }

private:
  void cmd_vel_callback(const geometry_msgs::msg::Twist::SharedPtr msg)
  {
    reference_pub_->publish(mini_car_controller::stamp_twist(*msg, now()));
  }

  rclcpp::Subscription<geometry_msgs::msg::Twist>::SharedPtr cmd_vel_sub_;
  rclcpp::Publisher<geometry_msgs::msg::TwistStamped>::SharedPtr reference_pub_;
};

int main(int argc, char ** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<CmdVelAdapter>());
  rclcpp::shutdown();
  return 0;
}
