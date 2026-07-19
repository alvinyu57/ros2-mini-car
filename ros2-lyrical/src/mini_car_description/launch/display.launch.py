import os

from ament_index_python.packages import get_package_share_directory

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.conditions import IfCondition
from launch.substitutions import Command, LaunchConfiguration, PathJoinSubstitution

from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare


def generate_launch_description():
    package_name = 'mini_car_description'

    use_gui = LaunchConfiguration('use_gui')
    use_rviz = LaunchConfiguration('use_rviz')

    xacro_file = PathJoinSubstitution(
        [
            FindPackageShare(package_name),
            'urdf',
            'mini_car.urdf.xacro',
        ]
    )

    rviz_config_file = os.path.join(
        get_package_share_directory(package_name),
        'rviz',
        'mini_car.rviz',
    )

    robot_description = {
        'robot_description': Command(
            [
                'xacro ',
                xacro_file,
            ]
        )
    }

    robot_state_publisher_node = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        name='robot_state_publisher',
        output='screen',
        parameters=[robot_description],
    )

    joint_state_publisher_gui_node = Node(
        package='joint_state_publisher_gui',
        executable='joint_state_publisher_gui',
        name='joint_state_publisher_gui',
        output='screen',
        condition=IfCondition(use_gui),
    )

    rviz_node = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        output='screen',
        arguments=['-d', rviz_config_file],
        condition=IfCondition(use_rviz),
    )

    return LaunchDescription(
        [
            DeclareLaunchArgument(
                'use_gui',
                default_value='true',
                description='Start joint_state_publisher_gui',
            ),
            DeclareLaunchArgument(
                'use_rviz',
                default_value='true',
                description='Start RViz',
            ),
            robot_state_publisher_node,
            joint_state_publisher_gui_node,
            rviz_node,
        ]
    )
