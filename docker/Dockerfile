# Base image
FROM ros:jazzy-ros-base

# Set up dev packages
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
   && apt-get -y install --no-install-recommends \
    bash-completion \
    gdb \
    gettext-base \
    git-core \
    openssh-client \
    python3-argcomplete \
    python3-colcon-common-extensions \
    python3-colcon-mixin \
    python3-pip \
    python3-rosdep \
    python3-venv \
    python3-vcs2l \
    sudo \
    locales \
    ca-certificates \
    gnupg \
    curl \
   # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Locale setup
RUN locale-gen en_US en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install ROS 2 packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Zenoh RMW for ROS 2 jazzy
    ros-jazzy-rmw-zenoh-cpp \
    # ROS 2 Control stack (provides hardware_interface)
    ros-jazzy-ros2-control \
    # Joy node for joystick input
    ros-jazzy-teleop-twist-joy \
    && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=dialog

# Create virtual environment for Python packages (accessible to all users)
RUN python3 -m venv /opt/venv && \
    chmod -R 755 /opt/venv

# Install Python packages in virtual environment
RUN /opt/venv/bin/pip3 install --no-cache-dir --upgrade pip && \
    /opt/venv/bin/pip3 install --no-cache-dir vcstool pyserial opencv-python-headless numpy feetech-servo-sdk

# Add venv to PATH and PYTHONPATH so ROS 2 nodes can find packages
ENV PATH="/opt/venv/bin:$PATH"
# Compute Python version and create a script to set PYTHONPATH dynamically
RUN PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')") && \
    VENV_SITE_PACKAGES="/opt/venv/lib/python${PYTHON_VERSION}/site-packages" && \
    echo "${VENV_SITE_PACKAGES}" > /opt/venv_pythonpath && \
    echo '#!/bin/bash' > /usr/local/bin/setup_venv_path.sh && \
    echo 'export PYTHONPATH="$(cat /opt/venv_pythonpath):${PYTHONPATH}"' >> /usr/local/bin/setup_venv_path.sh && \
    chmod +x /usr/local/bin/setup_venv_path.sh
# Source the script in profile for all users
RUN echo 'source /usr/local/bin/setup_venv_path.sh' >> /etc/profile
# For ROS 2 launch, we need PYTHONPATH set before nodes run
# Set it directly in ENV (Jazzy uses Python 3.12 on Ubuntu 24.04)
# Note: This is the first PYTHONPATH definition, so no need to reference existing value
ENV PYTHONPATH="/opt/venv/lib/python3.12/site-packages"

# Make sure colcon ignores the venv directory
RUN touch /opt/venv/COLCON_IGNORE

# Default to FastRTPS; you can override at runtime with -e RMW_IMPLEMENTATION=...
ENV RMW_IMPLEMENTATION=rmw_fastrtps_cpp

# Set up auto-source of workspace for ros 
ARG WORKSPACE
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Ensure group and user exist with target GID/UID and name
# Handles: user/group with target UID/GID but wrong name (renames), or missing (creates)
# Does NOT change UIDs of existing users (would require no running processes)
# If changing USER_UID, also update devcontainer.json volume mount path
RUN set -eux; \
    group_by_gid=$(getent group "$USER_GID" | cut -d: -f1 || true); \
    if [ -n "$group_by_gid" ] && [ "$group_by_gid" != "$USERNAME" ]; then \
        groupmod -n "$USERNAME" "$group_by_gid"; \
    elif [ -z "$group_by_gid" ]; then \
        groupadd --gid "$USER_GID" "$USERNAME" 2>/dev/null || true; \
    fi; \
    user_by_uid=$(getent passwd "$USER_UID" | cut -d: -f1 || true); \
    if [ -n "$user_by_uid" ] && [ "$user_by_uid" != "$USERNAME" ]; then \
        usermod -l "$USERNAME" -d "/home/$USERNAME" -m "$user_by_uid"; \
        usermod -g "$USERNAME" "$USERNAME"; \
    elif [ -z "$user_by_uid" ]; then \
        useradd -s /bin/bash --uid "$USER_UID" --gid "$USER_GID" -m "$USERNAME" 2>/dev/null || true; \
    fi

# Ensure necessary directories and permissions
RUN mkdir -p /home/$USERNAME /run/user/$USER_UID && \
    chown -R $USER_UID:$USER_GID /home/$USERNAME /run/user/$USER_UID

# Add sudo support for the non-root user
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && touch /home/$USERNAME/.sudo_as_admin_successful

# Set up autocompletion for user
RUN  echo "if [ -f /opt/ros/${ROS_DISTRO}/setup.bash ]; then source /opt/ros/${ROS_DISTRO}/setup.bash; fi" >> /home/$USERNAME/.bashrc \
  && echo "if [ -f /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash ]; then source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash; fi" >> /home/$USERNAME/.bashrc \
  && echo "if [ -f /usr/share/vcs2l-completion/vcs.bash ]; then source /usr/share/vcs2l-completion/vcs.bash; fi" >> /home/$USERNAME/.bashrc \
  # Set up auto-source of workspace for user
  && echo "if [ -f ${WORKSPACE}/install/setup.bash ]; then source ${WORKSPACE}/install/setup.bash; fi" >> /home/$USERNAME/.bashrc \
  # Activate virtual environment
  && echo "source /opt/venv/bin/activate" >> /home/$USERNAME/.bashrc \
  # Set up colcon mixins helper (runs on first container start)
  && echo "if ! colcon mixin list | grep -q default; then colcon mixin add default https://raw.githubusercontent.com/colcon/colcon-mixin-repository/master/index.yaml 2>/dev/null && colcon mixin update default 2>/dev/null || true; fi" >> /home/$USERNAME/.bashrc

# Set up python symlinks for vscode paths
RUN PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')") \
 && tgt="/opt/ros/${ROS_DISTRO}/lib/python${PYTHON_VERSION}/site-packages" \
 && [ -d "$tgt" ] && ln -s "$tgt" "/opt/ros/${ROS_DISTRO}/lib/ros_site_packages"

ENV AMENT_CPPCHECK_ALLOW_SLOW_VERSIONS=1
