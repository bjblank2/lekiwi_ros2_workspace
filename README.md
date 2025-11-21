# LeKiwi ROS2 Workspace

This repository contains the ROS2 workspace for the LeKiwi robot system, including robot arm control, base movement, camera integration, and helper utilities.

## Prerequisites

- Docker installed and configured
- Git
- Access to serial devices (for robot arms) and USB devices (for joystick and cameras)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd lekiwi_ros2_workspace
```

### 2. Build the Container

Build the Docker container using the Dockerfile in the `docker/` directory:

```bash
docker build -t ros2_zenoh:latest -f docker/Dockerfile .
```

Or if you need to specify build arguments:

```bash
docker build -t ros2_zenoh:latest -f docker/Dockerfile \
  --build-arg WORKSPACE=/workspaces/lekiwi_ros2_workspace \
  --build-arg USERNAME=ros \
  --build-arg USER_UID=1000 \
  --build-arg USER_GID=1000 \
  .
```

### 3. Update Colcon Mixin

Once inside the container, update the colcon mixin:

```bash
colcon mixin update default
```

This ensures you have the latest build configurations and mixins available.

### 4. Run the Setup Task

Execute the setup script to install dependencies and configure the workspace:

```bash
./scripts/tasks/setup.sh
```

This script will:
- Import repositories from `.repos/src.repos` if it exists
- Update package lists
- Update rosdep
- Install ROS2 dependencies (excluding Python packages handled by pip in the Dockerfile)
- Set up colcon mixins if not already configured

### 5. Run the Build Task

Build the ROS2 workspace using colcon:

```bash
./scripts/tasks/build.sh
```

This will build all packages in the workspace with the default `rel-with-deb-info` mixin. You can also specify a different mixin:

```bash
./scripts/tasks/build.sh debug    # For debug build
./scripts/tasks/build.sh release  # For release build
```

### 6. Launch Zenoh

Ensure the Zenoh RMW implementation is set in your environment. The container should already have this configured, but you can verify:

```bash
export RMW_IMPLEMENTATION=rmw_zenoh_cpp
```

If you need to run a Zenoh router (for distributed systems), you can launch it separately:

```bash
zenohd
```

For most local setups, the embedded RMW implementation is sufficient and no separate daemon is needed.

### 7. Launch Robot Nodes

Launch the required nodes for your robot setup. You can launch them individually or together:

#### Launch LeKiwi Node

```bash
ros2 launch lekiwi_ros2 lekiwi_ros2.launch.py
```

#### Launch SO101 ROS2 Nodes

For the leader arm:
```bash
ros2 launch so101_ros2 so101_leader.launch.py
```

For the follower arm:
```bash
ros2 launch so101_ros2 so101_follower.launch.py
```

#### Launch Webcam Node

```bash
ros2 launch webcam_ros2 webcam_ros2.launch.py
```

#### Launch Helper Nodes

For joint state relay:
```bash
ros2 launch joint_state_relay relay.launch.py
```

## Running the Container

To run the container with proper device access, use the provided script:

```bash
./scripts/run.sh
```

This script automatically:
- Mounts the workspace
- Passes through serial devices (`/dev/ttyACM*`, `/dev/ttyUSB*`)
- Passes through joystick devices (`/dev/input/js*`, `/dev/input/event*`)
- Passes through camera devices (`/dev/video*`)
- Sets up X11 forwarding for GUI applications (if not in headless mode)
- Configures the Zenoh RMW implementation

For headless mode (no GUI):
```bash
HEADLESS=1 ./scripts/run.sh
```

## Workspace Structure

- `src/` - ROS2 packages
  - `lekiwi_ros2/` - Main robot control package
  - `so101_ros2/` - SO101 robot arm control package
  - `drivers/webcam_ros2/` - Webcam driver package
  - `utilities/` - Helper utilities (joint_state_relay, joy_to_twist)
- `docker/` - Docker configuration files
- `scripts/` - Setup and build scripts
- `build/` - Build artifacts (generated)
- `install/` - Installation directory (generated)
- `log/` - Build and runtime logs (generated)

## Package Overview

- **lekiwi_ros2**: Main robot control node handling base movement, arm control, and joystick input
- **so101_ros2**: SO101 robot arm driver supporting leader/follower modes
- **webcam_ros2**: Camera driver for webcam integration
- **joint_state_relay**: Utility for relaying joint state messages between different namespaces
- **joy_to_twist**: Joystick to twist message converter (if needed)

## Troubleshooting

### Serial Device Permissions

If you encounter permission errors accessing serial devices, ensure your user is in the `dialout` group (handled automatically in the container).

### Build Errors

If you encounter build errors:
1. Make sure you've run `colcon mixin update default`
2. Ensure all dependencies are installed via `setup.sh`
3. Check that the workspace is properly sourced: `source install/setup.bash`

### Zenoh Connection Issues

If nodes cannot communicate:
1. Verify `RMW_IMPLEMENTATION=rmw_zenoh_cpp` is set
2. For distributed setups, ensure the Zenoh router is running
3. Check network connectivity if using remote Zenoh routers

## Additional Resources

- ROS2 Documentation: https://docs.ros.org/
- Zenoh Documentation: https://zenoh.io/
- Colcon Documentation: https://colcon.readthedocs.io/

