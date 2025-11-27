#!/bin/bash
#
# Buildroot build script for i.MX8MP Olimex
#
# Usage:
#   ./build.sh              - Incremental build
#   ./build.sh clean        - Clean build directories
#   ./build.sh rebuild      - Full clean rebuild
#   ./build.sh menuconfig   - Configure buildroot
#   ./build.sh savedefconfig - Save current config to defconfig
#   ./build.sh help         - Show this help
#

set -e

# Clean PATH to avoid Windows paths with spaces (WSL issue)
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Number of parallel jobs (adjust based on your CPU cores)
JOBS=$(nproc)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    echo "Buildroot Build Script for i.MX8MP Olimex"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  (none)        Incremental build"
    echo "  clean         Clean build directories (keeps downloads)"
    echo "  distclean     Full clean including downloads and config"
    echo "  rebuild       Clean and rebuild from scratch"
    echo "  menuconfig    Open configuration menu"
    echo "  savedefconfig Save current config to defconfig"
    echo "  linux-menuconfig  Configure Linux kernel"
    echo "  linux-rebuild Rebuild Linux kernel only"
    echo "  uboot-rebuild Rebuild U-Boot only"
    echo "  help          Show this help message"
    echo ""
    echo "Output images will be in: output/images/"
    echo ""
    echo "Default credentials:"
    echo "  Username: root"
    echo "  Password: olimex"
}

check_dependencies() {
    local missing=()
    
    for cmd in make gcc g++ patch gzip bzip2 perl tar cpio unzip rsync bc wget; do
        if ! command -v $cmd &> /dev/null; then
            missing+=($cmd)
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install with: sudo apt-get install build-essential patch gzip bzip2 perl tar cpio unzip rsync bc wget libncurses-dev"
        exit 1
    fi
}

do_build() {
    log_info "Starting incremental build with $JOBS parallel jobs..."
    log_info "Build log: build.log"
    
    time make -j$JOBS 2>&1 | tee build.log
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_info "Build completed successfully!"
        log_info "Output images are in: output/images/"
        ls -lh output/images/*.img output/images/Image 2>/dev/null || true
    else
        log_error "Build failed! Check build.log for details."
        exit 1
    fi
}

do_clean() {
    log_info "Cleaning build directories..."
    make clean
    log_info "Clean completed. Downloads preserved in dl/"
}

do_distclean() {
    log_warn "This will remove everything including downloads and configuration!"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Performing full clean..."
        make distclean
        log_info "Distclean completed."
    else
        log_info "Cancelled."
    fi
}

do_rebuild() {
    log_info "Starting clean rebuild..."
    make clean
    do_build
}

do_menuconfig() {
    log_info "Opening Buildroot configuration menu..."
    make menuconfig
}

do_savedefconfig() {
    log_info "Saving current configuration..."
    make savedefconfig
    log_info "Configuration saved."
}

do_linux_menuconfig() {
    log_info "Opening Linux kernel configuration menu..."
    make linux-menuconfig
}

do_linux_rebuild() {
    log_info "Rebuilding Linux kernel..."
    make linux-rebuild 2>&1 | tee -a build.log
    log_info "Rebuilding images..."
    make 2>&1 | tee -a build.log
}

do_uboot_rebuild() {
    log_info "Rebuilding U-Boot..."
    make uboot-rebuild 2>&1 | tee -a build.log
    log_info "Rebuilding images..."
    make 2>&1 | tee -a build.log
}

# Main
cd "$(dirname "$0")"

case "${1:-}" in
    help|--help|-h)
        show_help
        ;;
    clean)
        do_clean
        ;;
    distclean)
        do_distclean
        ;;
    rebuild)
        check_dependencies
        do_rebuild
        ;;
    menuconfig)
        do_menuconfig
        ;;
    savedefconfig)
        do_savedefconfig
        ;;
    linux-menuconfig)
        do_linux_menuconfig
        ;;
    linux-rebuild)
        check_dependencies
        do_linux_rebuild
        ;;
    uboot-rebuild)
        check_dependencies
        do_uboot_rebuild
        ;;
    "")
        check_dependencies
        do_build
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
