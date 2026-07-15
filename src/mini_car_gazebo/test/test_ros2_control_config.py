from math import isclose
from pathlib import Path
import xml.etree.ElementTree as ET

import yaml


PACKAGE_DIR = Path(__file__).resolve().parents[1]
CONFIG_FILE = PACKAGE_DIR / 'config' / 'ros2_control.yaml'
LAUNCH_FILE = PACKAGE_DIR / 'launch' / 'gazebo_ackermann.launch.py'
URDF_FILE = (
    PACKAGE_DIR.parent
    / 'mini_car_description'
    / 'urdf'
    / 'mini_car.urdf.xacro'
)


def load_controller_parameters():
    with CONFIG_FILE.open(encoding='utf-8') as config_stream:
        config = yaml.safe_load(config_stream)

    controller_type = config['controller_manager']['ros__parameters'][
        'ackermann_steering_controller'
    ]['type']
    parameters = config['ackermann_steering_controller']['ros__parameters']
    return controller_type, parameters


def test_uses_ros2_ackermann_controller_with_right_left_joint_order():
    controller_type, parameters = load_controller_parameters()

    assert controller_type == (
        'ackermann_steering_controller/AckermannSteeringController'
    )
    assert parameters['traction_joints_names'] == [
        'rear_right_wheel_joint',
        'rear_left_wheel_joint',
    ]
    assert parameters['steering_joints_names'] == [
        'front_right_steering_joint',
        'front_left_steering_joint',
    ]


def test_controller_geometry_matches_robot_description():
    _, parameters = load_controller_parameters()

    assert parameters['wheelbase'] == 0.40
    assert parameters['traction_track_width'] == 0.34
    assert parameters['steering_track_width'] == 0.34
    assert parameters['traction_wheels_radius'] == 0.07


def test_configured_joints_expose_required_command_interfaces():
    _, parameters = load_controller_parameters()
    ros2_control = ET.parse(URDF_FILE).getroot().find('ros2_control')
    assert ros2_control is not None

    command_interfaces = {
        joint.attrib['name']: joint.find('command_interface').attrib['name']
        for joint in ros2_control.findall('joint')
        if joint.find('command_interface') is not None
    }

    for joint_name in parameters['traction_joints_names']:
        assert command_interfaces[joint_name] == 'velocity'
    for joint_name in parameters['steering_joints_names']:
        assert command_interfaces[joint_name] == 'position'


def test_traction_command_limits_preserve_two_meter_per_second_ceiling():
    _, parameters = load_controller_parameters()
    ros2_control = ET.parse(URDF_FILE).getroot().find('ros2_control')
    assert ros2_control is not None

    joints = {
        joint.attrib['name']: joint
        for joint in ros2_control.findall('joint')
    }
    expected_limit = 2.0 / parameters['traction_wheels_radius']

    for joint_name in parameters['traction_joints_names']:
        command_interface = joints[joint_name].find('command_interface')
        limits = {
            parameter.attrib['name']: float(parameter.text)
            for parameter in command_interface.findall('param')
        }
        assert isclose(limits['min'], -expected_limit)
        assert isclose(limits['max'], expected_limit)


def test_stamped_command_input_is_remapped_directly_to_cmd_vel():
    launch_source = LAUNCH_FILE.read_text(encoding='utf-8')

    assert '--remap ~/reference:=/cmd_vel' in launch_source
    assert 'cmd_vel_adapter' not in launch_source
