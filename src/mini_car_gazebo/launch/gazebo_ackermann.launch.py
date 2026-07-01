import os

from ament_index_python.packages import get_package_share_directory

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription, TimerAction
from launch.conditions import IfCondition, UnlessCondition
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import Command, LaunchConfiguration

from launch_ros.actions import Node
from launch_ros.parameter_descriptions import ParameterValue


def generate_launch_description():
    gui = LaunchConfiguration('gui')
    rviz = LaunchConfiguration('rviz')

    mini_car_description_dir = get_package_share_directory('mini_car_description')
    mini_car_gazebo_dir = get_package_share_directory('mini_car_gazebo')
    ros_gz_sim_dir = get_package_share_directory('ros_gz_sim')

    xacro_file = os.path.join(
        mini_car_description_dir,
        'urdf',
        'mini_car.urdf.xacro',
    )

    world_file = os.path.join(
        mini_car_gazebo_dir,
        'worlds',
        'empty.sdf',
    )

    ros2_control_config = os.path.join(
        mini_car_gazebo_dir,
        'config',
        'ros2_control.yaml',
    )

    rviz_config_file = os.path.join(
        mini_car_description_dir,
        'rviz',
        'gazebo_ackermann.rviz',
    )

    robot_description = {
        'robot_description': ParameterValue(
            Command([
                'xacro ',
                xacro_file,
            ]),
            value_type=str,
        )
    }

    robot_state_publisher = Node(
        package='robot_state_publisher',
        executable='robot_state_publisher',
        name='robot_state_publisher',
        output='screen',
        parameters=[
            robot_description,
            {'use_sim_time': True},
        ],
    )

    gazebo_gui = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(ros_gz_sim_dir, 'launch', 'gz_sim.launch.py')
        ),
        launch_arguments={
            'gz_args': f'-r -v 4 {world_file}',
        }.items(),
        condition=IfCondition(gui),
    )

    gazebo_headless = IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            os.path.join(ros_gz_sim_dir, 'launch', 'gz_sim.launch.py')
        ),
        launch_arguments={
            'gz_args': f'-s -r -v 4 {world_file}',
        }.items(),
        condition=UnlessCondition(gui),
    )

    spawn_robot = Node(
        package='ros_gz_sim',
        executable='create',
        output='screen',
        arguments=[
            '-world', 'empty',
            '-topic', 'robot_description',
            '-name', 'mini_car',
            '-z', '0.15',
            '-allow_renaming', 'true',
        ],
    )

    clock_bridge = Node(
        package='ros_gz_bridge',
        executable='parameter_bridge',
        name='clock_bridge',
        output='screen',
        arguments=[
            '/clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock',
        ],
    )

    rviz_node = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        output='screen',
        arguments=['-d', rviz_config_file],
        parameters=[{'use_sim_time': True}],
        condition=IfCondition(rviz),
    )

    joint_state_broadcaster_spawner = Node(
        package='controller_manager',
        executable='spawner',
        arguments=[
            'joint_state_broadcaster',
            '--controller-manager',
            '/controller_manager',
            '--param-file',
            ros2_control_config,
        ],
        output='screen',
    )

    front_steering_controller_spawner = Node(
        package='controller_manager',
        executable='spawner',
        arguments=[
            'front_steering_controller',
            '--controller-manager',
            '/controller_manager',
            '--param-file',
            ros2_control_config,
        ],
        output='screen',
    )

    rear_wheel_velocity_controller_spawner = Node(
        package='controller_manager',
        executable='spawner',
        arguments=[
            'rear_wheel_velocity_controller',
            '--controller-manager',
            '/controller_manager',
            '--param-file',
            ros2_control_config,
        ],
        output='screen',
    )

    ackermann_controller = Node(
        package='mini_car_controller',
        executable='ackermann_controller',
        name='mini_car_ackermann_controller',
        output='screen',
        parameters=[{
            'use_sim_time': True,
            'wheel_base': 0.40,
            'wheel_radius': 0.07,
            'max_steering_angle': 0.6,
            'max_speed': 2.0,
            'command_timeout_sec': 0.5,
            'publish_odom': True,
            'odom_frame_id': 'odom',
            'base_frame_id': 'base_footprint',
        }],
    )

    delayed_spawn = TimerAction(
        period=2.0,
        actions=[spawn_robot],
    )

    delayed_controllers = TimerAction(
        period=5.0,
        actions=[
            joint_state_broadcaster_spawner,
            front_steering_controller_spawner,
            rear_wheel_velocity_controller_spawner,
        ],
    )

    delayed_ackermann_controller = TimerAction(
        period=7.0,
        actions=[ackermann_controller],
    )

    delayed_rviz = TimerAction(
        period=8.0,
        actions=[rviz_node],
    )

    return LaunchDescription([
        DeclareLaunchArgument(
            'gui',
            default_value='true',
            description='Start the Gazebo GUI',
        ),
        DeclareLaunchArgument(
            'rviz',
            default_value='true',
            description='Start RViz with the Ackermann simulation view',
        ),
        robot_state_publisher,
        gazebo_gui,
        gazebo_headless,
        clock_bridge,
        delayed_spawn,
        delayed_controllers,
        delayed_ackermann_controller,
        delayed_rviz,
    ])
