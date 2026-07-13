#include "gtest/gtest.h"
#include "mini_car_controller/twist_conversion.hpp"

TEST(TwistConversionTest, PreservesCommandAndAddsTimestamp)
{
  geometry_msgs::msg::Twist twist;
  twist.linear.x = 1.0;
  twist.linear.y = 2.0;
  twist.linear.z = 3.0;
  twist.angular.x = 4.0;
  twist.angular.y = 5.0;
  twist.angular.z = 6.0;

  builtin_interfaces::msg::Time stamp;
  stamp.sec = 123;
  stamp.nanosec = 456;

  const auto stamped_twist = mini_car_controller::stamp_twist(twist, stamp);

  EXPECT_EQ(stamped_twist.header.stamp, stamp);
  EXPECT_EQ(stamped_twist.twist, twist);
}
