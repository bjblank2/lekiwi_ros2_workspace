from setuptools import find_packages, setup
from glob import glob
import os

package_name = 'joy_to_twist'

setup(
    name=package_name,
    version='0.1.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='ros',
    maintainer_email='brianjblank7@gmail.com',
    description='Convert joystick Joy messages to Twist cmd_vel messages for robot control.',
    license='Apache-2.0',
    extras_require={
        'test': [
            'pytest',
        ],
    },
    entry_points={
        'console_scripts': [
            'joy_to_twist_node = joy_to_twist.joy_to_twist_node:main'
        ],
    },
)

