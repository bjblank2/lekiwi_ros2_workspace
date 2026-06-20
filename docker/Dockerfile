# Thin base image — all ROS 2 and Python packages are managed by pixi
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# OS essentials only: locale, sudo, curl (for pixi install), git and python3 (for VS Code extensions)
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    sudo \
    curl \
    ca-certificates \
    git \
    python3 \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV DEBIAN_FRONTEND=dialog

# Install pixi system-wide so all users can invoke it
RUN curl -fsSL https://pixi.sh/install.sh | PIXI_HOME=/opt/pixi PIXI_NO_PATH_UPDATE=1 bash
ENV PATH="/opt/pixi/bin:$PATH"

ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create non-root user — handles pre-existing UID/GID gracefully
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

RUN mkdir -p /home/$USERNAME /run/user/$USER_UID && \
    chown -R $USER_UID:$USER_GID /home/$USERNAME /run/user/$USER_UID

# Passwordless sudo
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && touch /home/$USERNAME/.sudo_as_admin_successful

# Device group access for serial, joystick, and camera hardware
RUN usermod -aG dialout "$USERNAME" && \
    (getent group input  >/dev/null 2>&1 && usermod -aG input  "$USERNAME" || true) && \
    (getent group video  >/dev/null 2>&1 && usermod -aG video  "$USERNAME" || true)

# Default workspace path — overridden by devcontainer build arg or -e WORKSPACE at runtime
ARG WORKSPACE=/workspaces/lekiwi_ros2_workspace
ENV WORKSPACE=$WORKSPACE

# Shell setup: activate pixi env, source the built workspace, and enable ROS2/colcon tab completion.
# ros2-argcomplete.bash is not sourced automatically because the RoboStack conda activate script
# calls setup.sh (not setup.bash), leaving AMENT_SHELL=sh so bash-specific scripts are skipped.
RUN echo 'eval "$(pixi shell-hook 2>/dev/null)" || true' >> /home/$USERNAME/.bashrc && \
    echo '[ -f "${WORKSPACE}/install/setup.bash" ] && source "${WORKSPACE}/install/setup.bash"' >> /home/$USERNAME/.bashrc && \
    echo '[ -f "$CONDA_PREFIX/share/ros2cli/environment/ros2-argcomplete.bash" ] && source "$CONDA_PREFIX/share/ros2cli/environment/ros2-argcomplete.bash"' >> /home/$USERNAME/.bashrc && \
    echo '[ -f "$CONDA_PREFIX/share/colcon_argcomplete/hook/colcon-argcomplete.bash" ] && source "$CONDA_PREFIX/share/colcon_argcomplete/hook/colcon-argcomplete.bash"' >> /home/$USERNAME/.bashrc && \
    echo '[ -f "${WORKSPACE}/install/setup.bash" ] && source "${WORKSPACE}/install/setup.bash"' >> /home/$USERNAME/.bash_profile

ENV AMENT_CPPCHECK_ALLOW_SLOW_VERSIONS=1
