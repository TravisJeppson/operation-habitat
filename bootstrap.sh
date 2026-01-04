#!/usr/bin/env bash
# Bootstrap script for ophab
# Usage: ./bootstrap.sh [--rebuild] [--enter]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="ophab-arch"
CONTAINER_NAME="ophab"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Parse arguments
REBUILD=false
ENTER=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --rebuild|-r)
            REBUILD=true
            shift
            ;;
        --enter|-e)
            ENTER=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --rebuild, -r    Force rebuild of container image"
            echo "  --enter, -e      Enter container after creation"
            echo "  --help, -h       Show this help"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Detect container runtime
detect_runtime() {
    if command -v podman &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null; then
        echo "docker"
    else
        log_error "Neither podman nor docker found. Please install one."
        exit 1
    fi
}

RUNTIME=$(detect_runtime)
log_info "Using container runtime: $RUNTIME"

# Check for distrobox
if ! command -v distrobox &> /dev/null; then
    log_error "distrobox not found. Please install it first."
    echo ""
    echo "Installation options:"
    echo "  curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh"
    echo ""
    echo "Or via package manager:"
    echo "  Fedora: sudo dnf install distrobox"
    echo "  Arch:   sudo pacman -S distrobox"
    echo "  Ubuntu: sudo apt install distrobox"
    exit 1
fi

log_success "distrobox found"

# Build container image
build_image() {
    log_info "Building container image: $IMAGE_NAME"
    
    cd "$SCRIPT_DIR"
    
    if [[ "$RUNTIME" == "podman" ]]; then
        podman build -t "localhost/$IMAGE_NAME:latest" -f Containerfile .
    else
        docker build -t "$IMAGE_NAME:latest" -f Containerfile .
        # Tag for localhost reference
        docker tag "$IMAGE_NAME:latest" "localhost/$IMAGE_NAME:latest"
    fi
    
    log_success "Image built successfully"
}

# Check if image exists
image_exists() {
    if [[ "$RUNTIME" == "podman" ]]; then
        podman image exists "localhost/$IMAGE_NAME:latest" 2>/dev/null
    else
        docker image inspect "localhost/$IMAGE_NAME:latest" &>/dev/null
    fi
}

# Check if container exists
container_exists() {
    distrobox list | grep -q "^$CONTAINER_NAME " 2>/dev/null
}

# Main logic
main() {
    echo ""
    echo "╔══════════════════════════════════════╗"
    echo "║     Development Environment Setup    ║"
    echo "╚══════════════════════════════════════╝"
    echo ""

    # Build image if needed
    if ! image_exists || [[ "$REBUILD" == true ]]; then
        if [[ "$REBUILD" == true ]]; then
            log_info "Rebuild requested"
        else
            log_info "Image not found, building..."
        fi
        build_image
    else
        log_success "Image already exists (use --rebuild to force)"
    fi

    # Remove existing container if rebuilding
    if [[ "$REBUILD" == true ]] && container_exists; then
        log_info "Removing existing container..."
        distrobox stop "$CONTAINER_NAME" 2>/dev/null || true
        distrobox rm "$CONTAINER_NAME" --force 2>/dev/null || true
    fi

    # Create container using distrobox-assemble
    if ! container_exists; then
        log_info "Creating container with distrobox-assemble..."
        cd "$SCRIPT_DIR"
        distrobox-assemble create --file distrobox-assemble.yaml
        log_success "Container created"
        
        # Run post-create hooks
        log_info "Running post-create hooks..."
        distrobox enter "$CONTAINER_NAME" -- bash "$SCRIPT_DIR/hooks/post-create.sh"
    else
        log_success "Container already exists"
    fi

    echo ""
    log_success "Setup complete!"
    echo ""
    echo "To enter the environment:"
    echo "  distrobox enter $CONTAINER_NAME"
    echo ""
    echo "To run post-create hooks again:"
    echo "  distrobox enter $CONTAINER_NAME -- bash hooks/post-create.sh"
    echo ""

    # Enter if requested
    if [[ "$ENTER" == true ]]; then
        log_info "Entering container..."
        exec distrobox enter "$CONTAINER_NAME"
    fi
}

main
