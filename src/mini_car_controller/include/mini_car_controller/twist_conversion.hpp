#ifndef MINI_CAR_CONTROLLER__TWIST_CONVERSION_HPP_
#define MINI_CAR_CONTROLLER__TWIST_CONVERSION_HPP_

#include "builtin_interfaces/msg/time.hpp"
#include "geometry_msgs/msg/twist.hpp"
#include "geometry_msgs/msg/twist_stamped.hpp"

namespace mini_car_controller
{

geometry_msgs::msg::TwistStamped stamp_twist(
  const geometry_msgs::msg::Twist & twist,
  const builtin_interfaces::msg::Time & stamp);

}  // namespace mini_car_controller

#endif  // MINI_CAR_CONTROLLER__TWIST_CONVERSION_HPP_
