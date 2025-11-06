#!/usr/bin/env bash
set -euo pipefail

# ---------- Config you can tweak ----------
IMAGE="${IMAGE:-ros2_zenoh:latest}"
NAME="${NAME:-ros2_zenoh}"       # container name
WS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEADLESS="${HEADLESS:-0}"        # set to 1 to skip X11/GUI bits
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
  -v "$WS_DIR":/root/ros2_ws
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

# Pass serial devices for SO101 arms
# Add ttyACM devices for USB serial connections
for dev in /dev/ttyACM*; do
  [[ -e "$dev" ]] && ARGS+=( --device="$dev" )
done
# Also allow access to USB serial devices if needed
for dev in /dev/ttyUSB*; do
  [[ -e "$dev" ]] && ARGS+=( --device="$dev" )
done
# Also allow access to usb joystick devices if needed
for dev in /dev/input/js*; do
  [[ -e "$dev" ]] && ARGS+=( --device="$dev" )
done
# Also mount the input event devices (some joystick drivers need these)
for dev in /dev/input/event*; do
  [[ -e "$dev" ]] && ARGS+=( --device="$dev" )
done
# Also allow for webcams if needed
for dev in /dev/video*; do
  [[ -e "$dev" ]] && ARGS+=( --device="$dev" )
done

exec docker run "${ARGS[@]}" "$IMAGE" bash
