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