#!/usr/bin/env bash
set -euo pipefail

# --------- Config you can tweak ----------
IMAGE="${IMAGE:-lekiwi_ros2:latest}"
NAME="${NAME:-lekiwi_ros2}"      # container name
WS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEADLESS="${HEADLESS:-0}"        # set to 1 to skip X11/GUI bits
WORKSPACE=/workspace             # path inside the container
# -----------------------------------------

# Allow GUI apps (rviz/rqt) to display on host X server (safe for local)
if [[ "$HEADLESS" != "1" ]]; then
  xhost +local:root >/dev/null 2>&1 || true
fi

# Base docker args
ARGS=(
  -it --rm
  --name "$NAME"
  --net=host
  -v "$WS_DIR":/workspace
  -e WORKSPACE="$WORKSPACE"
  -e RMW_IMPLEMENTATION="${RMW_IMPLEMENTATION:-rmw_zenoh_cpp}"
)

# Optional GUI passthrough (rviz/rqt)
if [[ "$HEADLESS" != "1" ]]; then
  ARGS+=(
    -e DISPLAY="$DISPLAY"
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw
    --device /dev/dri
  )
fi

# Bind-mount the entire host /dev so hot-plugged devices (serial, joystick,
# webcam) appear inside the container without a restart.
ARGS+=( -v /dev:/dev )

exec docker run "${ARGS[@]}" "$IMAGE" bash
