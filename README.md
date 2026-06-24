# LeKiwi ROS2 Workspace
<p align="center">
  <img src="assets/KiwiRos2.png" alt="KiwiRos2" width="300"/>
</p>


This repository contains a ROS2 workspace/implementation for the LeKiwi robot system. The workspace includes ROS2 implementations of SO101 robot arm control (leader and follower), the LeKiwi omni-wheel mobile manipulator, the LeRRe tracked robot, ROS2 webcam integration, and a few helper utilities. A full ros2_control integration with URDF is included for both robots. While this workspace can function as a self-contained "all-you-need" environment for controlling your LeKiwi robot in ROS2, I hope it's a jumping off point for pushing your LeKiwi to even bigger and better things.

- Interested in building a LeKiwi? YOU SHOULD BE! Check it out [here](https://github.com/SIGRobotics-UIUC/LeKiwi.git) and get started with this great robot platform.
- Just want a ROS2 wrapper for the SO101 arm? Check out the one we use in this workspace [here](https://github.com/bjblank2/so101_ros2.git) and check out the SO101 repo [here](https://github.com/TheRobotStudio/SO-ARM100.git) or [here](https://github.com/huggingface/lerobot.git)
- Interested in using your ROS2-Powered Lekiwi for ML/Embodied-AI development? OF COURSE YOU ARE! Check out rosetta [here](https://github.com/iblnkn/rosetta.git) and get started integrating your new ROS2 system with [LeRobot](https://github.com/huggingface/lerobot.git).

## Prerequisites
This tutorial assumes you are using Ubuntu 24.04 (on a Raspberry Pi 5 or whatever system your LeKiwi is tethered to) [with Docker installed](https://docs.docker.com/engine/install/ubuntu/) and properly configured. Apart from that, all you need is a LeKiwi (obviously), a SO101 leader arm to puppet with, a game controller (Xbox/PS...) to drive the base around, and the IDE of your choice (VS Code and Cursor have both been tested and everything works nicely).

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd lekiwi_ros2_workspace
```

### 2. Open in the Dev Container

If you are using VS Code or Cursor, select **File → Open Folder** and select `lekiwi_ros2_workspace`. After opening the folder, you will be prompted to re-open in a container. Select this option.

The container's `postCreateCommand` will automatically run `pixi install`, which installs all ROS2 and Python dependencies declared in `pixi.toml` via the [pixi](https://prefix.dev/) conda-based package manager. No manual dependency installation is needed.

If you want to build the container manually:

```bash
docker build -t lekiwi_ros2:latest -f docker/Dockerfile \
  --build-arg WORKSPACE=/workspaces/lekiwi_ros2_workspace \
  --build-arg USERNAME=ros \
  --build-arg USER_UID=1000 \
  --build-arg USER_GID=1000 \
  .
```

### 3. Import Source Repositories

Once inside the container, run the setup script to clone the source packages into `src/`:

```bash
./scripts/tasks/setup.sh
```

Or with the VS Code task runner (`Ctrl+Shift+P` → **Tasks: Run Task** → `setup`).

This script imports all repositories listed in `.repos/src.repos` via `vcstool` and registers the colcon mixin repository on first use. All ROS2 and Python dependencies are already handled by pixi.

### 4. Build the Workspace

Build all packages using pixi's colcon wrapper:

```bash
pixi run build
```

Additional build modes:

```bash
pixi run build-release   # rel-with-deb-info + compile_commands.json
pixi run build-debug     # debug build
```

Or via the VS Code task runner (`Ctrl+Shift+P` → **Tasks: Run Task** → `build`).

After building, source the workspace in any terminal where you want to run ROS2 commands:

```bash
source install/setup.bash
```

### 5. Launch Zenoh

Zenoh is the RMW implementation used in this workspace. The `RMW_IMPLEMENTATION=rmw_zenoh_cpp` environment variable is set automatically by pixi on activation.

If running on a Raspberry Pi or in a distributed setup, start the Zenoh router in a dedicated terminal:

```bash
ros2 run rmw_zenoh_cpp rmw_zenohd
```

For local single-machine setups, the embedded RMW is sufficient and no separate router is needed. See **Zenoh Connection Issues** in the Troubleshooting section if nodes cannot communicate.

### 6. Launch Robot Nodes

#### LeKiwi (Omni-Wheel Mobile Manipulator)

There are two launch modes for the LeKiwi:

**Direct servo control** (original mode):
```bash
ros2 launch lekiwi_ros2 lekiwi_ros2.launch.py
```

**ros2_control mode** (recommended — uses URDF, controller_manager, and the feetech_ros2_driver hardware interface):
```bash
ros2 launch lekiwi_ros2 lekiwi_ros2_control.launch.py
```

Both launch files accept the following key arguments:

| Argument | Default | Description |
|---|---|---|
| `port` | `/dev/ttyACM0` | Serial port for the servo bus |
| `baudrate` | `1000000` | Serial baudrate |
| `arm_id` | `follower_arm` | Namespace for the follower arm |
| `leader_arm_id` | `leader_arm` | Namespace of the leader arm to follow |
| `wheel_control_mode` | `joy` | `joy` for `/joy` input, `cmd_vel` for `/cmd_vel` input |
| `wheel_count` | `3` | Number of wheels (3 for omni, 4 for mecanum) |

Example with `cmd_vel` control:
```bash
ros2 launch lekiwi_ros2 lekiwi_ros2.launch.py wheel_control_mode:=cmd_vel
```

#### LeRRe (Tracked/Tank Drive Robot)

The `lekiwi_ros2` package also supports the LeRRe, a tracked differential-drive robot controlled via SpaceMouse (`/spacemouse/joy`).

**Direct servo control**:
```bash
ros2 launch lekiwi_ros2 lerre_ros2.launch.py
```

**ros2_control mode**:
```bash
ros2 launch lekiwi_ros2 lerre_ros2_control.launch.py
```

Key LeRRe-specific arguments: `track_seperation` (default `0.2` m), `wheel_radius` (default `0.05` m).

#### SO101 Leader Arm

Launch the SO101 arm in leader mode for puppeting the follower:

```bash
ros2 launch so101_ros2 so101_leader.launch.py
```

Key arguments: `port` (default `/dev/ttyACM0`), `arm_id` (default `leader_arm`), `publish_rate` (default `50.0` Hz).

#### SO101 Follower Arm (standalone)

If you are using only the SO101 arm without the full LeKiwi base:

```bash
ros2 launch so101_ros2 so101_follower.launch.py
```

#### SO101 Hardware-In-the-Loop Teacher

For hardware-in-the-loop teacher mode:

```bash
ros2 launch so101_ros2 so101_hil_teacher.launch.py
```

#### Webcam Nodes

Launch one node per camera:

```bash
ros2 launch webcam_ros2 webcam_ros2.launch.py \
    camera_id:=1 \
    topic_name:=front_camera
```

#### Helper Utilities

**Joy to Twist**: Converts `/joy` messages to `/cmd_vel` if you need Twist-based base control:

```bash
ros2 run joy_to_twist joy_to_twist_node
```

**Joint State Relay**: Translates joint state message types/namespaces between packages that expect different formats. See the package README for details:

```bash
ros2 launch joint_state_relay relay.launch.py
```

## Running the Container Without an IDE

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

```
lekiwi_ros2_workspace/
├── src/
│   ├── lekiwi_ros2/          # LeKiwi and LeRRe robot control (omni + tracked)
│   ├── so101_ros2/           # SO101 arm driver (leader / follower / HIL teacher)
│   ├── drivers/
│   │   ├── feetech_ros2_driver/  # C++ ros2_control hardware interface for Feetech servos
│   │   └── webcam_ros2/          # Webcam driver
│   └── utilities/
│       ├── joint_state_relay/    # Joint state message relay
│       └── joy_to_twist/         # /joy → /cmd_vel converter
├── docker/                   # Dockerfile and devcontainer.json
├── scripts/                  # setup.sh and build.sh task scripts
├── .repos/src.repos          # vcstool repository manifest
├── pixi.toml                 # Dependency and task definitions (replaces rosdep/pip)
├── build/                    # Build artifacts (generated)
├── install/                  # Install directory (generated)
└── log/                      # Build and runtime logs (generated)
```

## Package Overview

| Package | Description |
|---|---|
| **lekiwi_ros2** | Robot control for the LeKiwi (omni-wheel) and LeRRe (tracked) platforms. Includes direct-servo and ros2_control launch modes, wheel kinematics, arm teleop, and calibration nodes. |
| **so101_ros2** | SO101 arm driver supporting leader, follower, and hardware-in-the-loop teacher modes. |
| **feetech_ros2_driver** | C++ ros2_control hardware interface plugin for Feetech STS/SCS servo series. Used by the ros2_control launch modes. |
| **webcam_ros2** | Camera driver for webcam integration. |
| **joint_state_relay** | Utility for relaying joint state messages between namespaces or message types. |
| **joy_to_twist** | Converts `/joy` messages to `/cmd_vel` Twist messages. |

## Troubleshooting

### Serial Device Permissions

If you encounter permission errors accessing serial devices, ensure your user is in the `dialout` group (handled automatically in the container).

### Build Errors

If you encounter build errors:
1. Confirm `pixi install` completed successfully (runs automatically on container creation)
2. Run `./scripts/tasks/setup.sh` to ensure all source repositories are imported
3. Ensure the workspace is sourced: `source install/setup.bash`
4. For C++ build failures in `feetech_ros2_driver`, confirm `libserial` is installed at `/usr/local` (built from source in the Dockerfile)

### Zenoh Connection Issues

If nodes cannot communicate:
1. Verify `echo $RMW_IMPLEMENTATION` returns `rmw_zenoh_cpp`
2. Verify a consistent domain ID across terminals: `echo $ROS_DOMAIN_ID`
3. For distributed setups (robot nodes on Pi, controller nodes on laptop), ensure the Zenoh router is running on each machine

For a distributed system, kill any existing Zenoh routers on each machine and restart with explicit endpoint configuration:

```bash
export ZENOH_CONFIG_OVERRIDE='connect/endpoints=["tcp/<ip_of_other_machine>:7447"]'
ros2 run rmw_zenoh_cpp rmw_zenohd
```

Run this on each machine in the distributed system.

## Additional Resources

- ROS2 Documentation: [https://docs.ros.org/](https://docs.ros.org/)
- ROS2 Control Documentation: [https://control.ros.org/](https://control.ros.org/)
- Zenoh Documentation: [https://zenoh.io/](https://zenoh.io/), [https://github.com/ros2/rmw_zenoh.git](https://github.com/ros2/rmw_zenoh.git)
- pixi Documentation: [https://prefix.dev/docs/pixi/](https://prefix.dev/docs/pixi/)
- Colcon Documentation: [https://colcon.readthedocs.io/](https://colcon.readthedocs.io/)
