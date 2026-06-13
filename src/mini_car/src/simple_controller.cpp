#include <chrono>
#include <memory>

#include "rclcpp/rclcpp.hpp"
#include "geometry_msgs/msg/twist.hpp"

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

int main(int argc, char ** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<SimpleController>());
  rclcpp::shutdown();
  return 0;
}
