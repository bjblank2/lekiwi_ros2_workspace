#!/bin/bash
set -e

# Build using colcon mixins (from default repository)
# Usage: ./build.sh [mixin_name]
# Default: rel-with-deb-info with compile commands and warnings
# Options: debug, release, or any mixin from default repository

MIXIN="${1:-rel-with-deb-info}"

# Clear stale AMENT_PREFIX_PATH from previous builds (prevents warnings about non-existent paths)
# This happens when switching between isolated and merged install layouts
unset AMENT_PREFIX_PATH

# Build with mixins - mixins handle cmake-args, we add colcon flags separately
if [[ "$MIXIN" == "rel-with-deb-info" ]]; then
    # Default: RelWithDebInfo with compile commands and warnings
    colcon build \
        --mixin compile-commands rel-with-deb-info \
        --cmake-args -Wall -Wextra -Wpedantic
else
    # Use mixin from default repository (debug, release, etc.)
    colcon build --mixin compile-commands "$MIXIN"
fi

