#!/bin/bash
set -e

# Build using colcon mixins.
# Prefer running via pixi: `pixi run build` or `pixi run build-release`
# Usage: ./build.sh [mixin_name]
#   Default: rel-with-deb-info with compile commands and warnings
#   Options: debug, release, or any mixin from the default repository

MIXIN="${1:-rel-with-deb-info}"

# Clear stale AMENT_PREFIX_PATH from previous builds
unset AMENT_PREFIX_PATH

if [[ "$MIXIN" == "rel-with-deb-info" ]]; then
    colcon build \
        --mixin compile-commands rel-with-deb-info \
        --cmake-args -Wall -Wextra -Wpedantic
else
    colcon build --mixin compile-commands "$MIXIN"
fi
