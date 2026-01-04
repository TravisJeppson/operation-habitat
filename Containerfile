# Arch Linux base for distrobox development environment
# Keep this minimal - dev tools come from Devbox
FROM docker.io/archlinux:latest

# Update and install base requirements
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm --needed \
        base-devel \
        git \
        curl \
        wget \
        unzip \
        openssh \
        sudo \
        which \
        man-db \
        man-pages \
        # Required for distrobox integration
        xorg-xhost \
        # Nix/Devbox dependencies
        xz \
        # Useful to have at system level
        iproute2 \
        iputils \
        bind-tools \
        procps-ng \
        htop \
        && \
    # Clean up cache
    pacman -Scc --noconfirm

# Enable en_US.UTF-8 locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create marker file for distrobox compatibility
RUN touch /etc/container-release

# Labels for identification
LABEL com.github.containers.toolbox="true" \
      name="ophab-arch" \
      version="1.0" \
      description="Arch Linux development environment for distrobox"