#include <algorithm>
#include <cmath>
#include <memory>
#include <string>

#include "geometry_msgs/msg/transform_stamped.hpp"
#include "geometry_msgs/msg/twist.hpp"
#include "nav_msgs/msg/odometry.hpp"
#include "rclcpp/rclcpp.hpp"
#include "std_msgs/msg/float64_multi_array.hpp"
#include "tf2_ros/transform_broadcaster.hpp"

class AckermannController : public rclcpp::Node {
public:
  AckermannController()
  : Node("mini_car_ackermann_controller")
  {
    wheel_base_ = declare_parameter<double>("wheel_base", 0.40);
    wheel_radius_ = declare_parameter<double>("wheel_radius", 0.07);
    max_steering_angle_ = declare_parameter<double>("max_steering_angle", 0.6);
    max_speed_ = declare_parameter<double>("max_speed", 2.0);
    command_timeout_sec_ = declare_parameter<double>("command_timeout_sec", 0.5);
    publish_odom_ = declare_parameter<bool>("publish_odom", true);

    base_frame_id_ = declare_parameter<std::string>("base_frame_id", "base_footprint");
    odom_frame_id_ = declare_parameter<std::string>("odom_frame_id", "odom");

    steering_pub_ =
      create_publisher<std_msgs::msg::Float64MultiArray>(
        "/front_steering_controller/commands", 10);

    rear_wheel_pub_ =
      create_publisher<std_msgs::msg::Float64MultiArray>(
        "/rear_wheel_velocity_controller/commands", 10);

    odom_pub_ = create_publisher<nav_msgs::msg::Odometry>("/odom", 10);

    tf_broadcaster_ = std::make_unique<tf2_ros::TransformBroadcaster>(*this);

    cmd_sub_ =
      create_subscription<geometry_msgs::msg::Twist>(
        "/cmd_vel",
        10,
        std::bind(&AckermannController::cmdVelCallback, this, std::placeholders::_1));

    last_cmd_time_ = now();
    last_update_time_ = now();

    timer_ =
      create_wall_timer(
        std::chrono::milliseconds(20),
        std::bind(&AckermannController::update, this));

    RCLCPP_INFO(get_logger(), "Mini car Ackermann controller started");
  }

private:
  void cmdVelCallback(const geometry_msgs::msg::Twist::SharedPtr msg)
  {
    target_speed_ = std::clamp(msg->linear.x, -max_speed_, max_speed_);
    target_yaw_rate_ = msg->angular.z;
    last_cmd_time_ = now();
  }

  void update()
  {
    const rclcpp::Time current_time = now();
    const double dt = (current_time - last_update_time_).seconds();
    last_update_time_ = current_time;

    if (dt <= 0.0) {
      return;
    }

    double speed = target_speed_;
    double yaw_rate = target_yaw_rate_;

    const double age = (current_time - last_cmd_time_).seconds();
    if (age > command_timeout_sec_) {
      speed = 0.0;
      yaw_rate = 0.0;
    }

    const double steering_angle = computeSteeringAngle(speed, yaw_rate);
    const double rear_wheel_velocity = speed / wheel_radius_;

    publishJointCommands(steering_angle, rear_wheel_velocity);

    if (publish_odom_) {
      integrateAndPublishOdometry(current_time, dt, speed, steering_angle);
    }
  }

  double computeSteeringAngle(double speed, double yaw_rate) const
  {
    if (std::abs(speed) < 1e-3) {
      return 0.0;
    }

    const double steering_angle = std::atan(wheel_base_ * yaw_rate / speed);
    return std::clamp(steering_angle, -max_steering_angle_, max_steering_angle_);
  }

  void publishJointCommands(double steering_angle, double rear_wheel_velocity)
  {
    std_msgs::msg::Float64MultiArray steering_cmd;
    steering_cmd.data = {steering_angle, steering_angle};
    steering_pub_->publish(steering_cmd);

    std_msgs::msg::Float64MultiArray wheel_cmd;
    wheel_cmd.data = {rear_wheel_velocity, rear_wheel_velocity};
    rear_wheel_pub_->publish(wheel_cmd);
  }

  void integrateAndPublishOdometry(
    const rclcpp::Time & stamp,
    double dt,
    double speed,
    double steering_angle)
  {
    const double yaw_rate = speed * std::tan(steering_angle) / wheel_base_;

    x_ += speed * std::cos(yaw_) * dt;
    y_ += speed * std::sin(yaw_) * dt;
    yaw_ += yaw_rate * dt;

    const double half_yaw = yaw_ * 0.5;
    const double orientation_z = std::sin(half_yaw);
    const double orientation_w = std::cos(half_yaw);

    geometry_msgs::msg::TransformStamped tf_msg;
    tf_msg.header.stamp = stamp;
    tf_msg.header.frame_id = odom_frame_id_;
    tf_msg.child_frame_id = base_frame_id_;
    tf_msg.transform.translation.x = x_;
    tf_msg.transform.translation.y = y_;
    tf_msg.transform.translation.z = 0.0;
    tf_msg.transform.rotation.x = 0.0;
    tf_msg.transform.rotation.y = 0.0;
    tf_msg.transform.rotation.z = orientation_z;
    tf_msg.transform.rotation.w = orientation_w;

    tf_broadcaster_->sendTransform(tf_msg);

    nav_msgs::msg::Odometry odom;
    odom.header.stamp = stamp;
    odom.header.frame_id = odom_frame_id_;
    odom.child_frame_id = base_frame_id_;

    odom.pose.pose.position.x = x_;
    odom.pose.pose.position.y = y_;
    odom.pose.pose.position.z = 0.0;
    odom.pose.pose.orientation = tf_msg.transform.rotation;

    odom.twist.twist.linear.x = speed;
    odom.twist.twist.angular.z = yaw_rate;

    odom_pub_->publish(odom);
  }

  double wheel_base_{0.40};
  double wheel_radius_{0.07};
  double max_steering_angle_{0.6};
  double max_speed_{2.0};
  double command_timeout_sec_{0.5};

  bool publish_odom_{true};

  std::string base_frame_id_{"base_footprint"};
  std::string odom_frame_id_{"odom"};

  double target_speed_{0.0};
  double target_yaw_rate_{0.0};

  double x_{0.0};
  double y_{0.0};
  double yaw_{0.0};

  rclcpp::Time last_cmd_time_;
  rclcpp::Time last_update_time_;

  rclcpp::Subscription<geometry_msgs::msg::Twist>::SharedPtr cmd_sub_;
  rclcpp::Publisher<std_msgs::msg::Float64MultiArray>::SharedPtr steering_pub_;
  rclcpp::Publisher<std_msgs::msg::Float64MultiArray>::SharedPtr rear_wheel_pub_;
  rclcpp::Publisher<nav_msgs::msg::Odometry>::SharedPtr odom_pub_;

  std::unique_ptr<tf2_ros::TransformBroadcaster> tf_broadcaster_;
  rclcpp::TimerBase::SharedPtr timer_;
};

int main(int argc, char ** argv)
{
  rclcpp::init(argc, argv);
  rclcpp::spin(std::make_shared<AckermannController>());
  rclcpp::shutdown();
  return 0;
}
