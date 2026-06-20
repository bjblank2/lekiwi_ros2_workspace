#!/bin/bash
set -e

# Import repositories (if repos file exists and has content)
if [ -f .repos/src.repos ] && [ -s .repos/src.repos ]; then
    envsubst < .repos/src.repos | vcs import src
fi
sudo apt-get update
rosdep update --rosdistro=$ROS_DISTRO
# Skip Python packages that are installed in the virtual environment
# These are handled by pip in the Dockerfile: pyserial, opencv-python-headless, numpy, feetech-servo-sdk
rosdep install --from-paths src --ignore-src -y --rosdistro=$ROS_DISTRO --skip-keys "pyserial opencv-python-headless numpy feetech-servo-sdk"

# Set up colcon mixins (if not already set up)
if ! colcon mixin list | grep -q "default"; then
    echo "Setting up colcon mixins..."
    colcon mixin add default https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml
    colcon mixin update default
fi