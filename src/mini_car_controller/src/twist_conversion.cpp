#include "mini_car_controller/twist_conversion.hpp"

namespace mini_car_controller
{

geometry_msgs::msg::TwistStamped stamp_twist(
  const geometry_msgs::msg::Twist & twist,
  const builtin_interfaces::msg::Time & stamp)
{
  geometry_msgs::msg::TwistStamped stamped_twist;
  stamped_twist.header.stamp = stamp;
  stamped_twist.twist = twist;
  return stamped_twist;
}

}  // namespace mini_car_controller
