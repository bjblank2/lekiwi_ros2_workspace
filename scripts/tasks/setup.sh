#!/bin/bash
set -e

# Import source repositories declared in .repos/src.repos.
# All ROS 2 and Python dependencies are managed by pixi (see pixi.toml).
# Run `pixi install` to install packages; this script only handles repo import.

if [ -f .repos/src.repos ] && [ -s .repos/src.repos ]; then
    envsubst < .repos/src.repos | vcs import src
fi

# Set up colcon mixins on first use
if ! colcon mixin list 2>/dev/null | grep -q "default"; then
    echo "Setting up colcon mixins..."
    colcon mixin add default https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml
    colcon mixin update default
fi
