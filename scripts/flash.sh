#!/bin/bash
# =============================================================================
# scripts/flash.sh — Fastboot-Only Device Flash Script
# =============================================================================
# Flashes system.img and userdata.img to a Treble-compliant device.
# Does NOT require adb at any point.
#
# Usage:
#   bash scripts/flash.sh                    # flash both images
#   bash scripts/flash.sh --system-only      # flash system.img only
#   bash scripts/flash.sh --userdata-only    # flash userdata.img only
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$REPO_ROOT/builder/out"

SYSTEM_IMG="$BUILD_DIR/system.img"
USERDATA_IMG="$BUILD_DIR/userdata.img"

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[Flash]${NC}  $1"; }
success() { echo -e "${GREEN}[Flash]${NC}  $1"; }
error()   { echo -e "${RED}[Flash]${NC}  $1"; }
warning() { echo -e "${YELLOW}[Flash]${NC}  $1"; }

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
FLASH_SYSTEM=true
FLASH_USERDATA=true

case "${1:-}" in
    --system-only)   FLASH_USERDATA=false ;;
    --userdata-only) FLASH_SYSTEM=false ;;
    --help|-h)
        echo "Usage: $0 [--system-only | --userdata-only]"
        echo ""
        echo "  (default)        Flash system.img + userdata.img"
        echo "  --system-only    Flash system.img only (preserves userdata)"
        echo "  --userdata-only  Flash userdata.img only (preserves system)"
        exit 0
        ;;
    "") ;;
    *)  error "Unknown argument: $1"; exit 1 ;;
esac

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}         Ubuntu GSI — Device Flash                            ${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# ---------------------------------------------------------------------------
# 1. Verify build artifacts
# ---------------------------------------------------------------------------
info "Checking build artifacts..."

MISSING=0
if [ "$FLASH_SYSTEM" = true ] && [ ! -f "$SYSTEM_IMG" ]; then
    error "system.img not found: $SYSTEM_IMG"
    MISSING=1
fi
if [ "$FLASH_USERDATA" = true ] && [ ! -f "$USERDATA_IMG" ]; then
    error "userdata.img not found: $USERDATA_IMG"
    error "Run: ./build.sh   (this builds all images including userdata.img)"
    MISSING=1
fi
if [ "$MISSING" -eq 1 ]; then
    exit 1
fi

if [ "$FLASH_SYSTEM" = true ]; then
    SIMG_SIZE=$(du -h "$SYSTEM_IMG" | cut -f1)
    info "system.img   : $SIMG_SIZE"
fi
if [ "$FLASH_USERDATA" = true ]; then
    UIMG_SIZE=$(du -h "$USERDATA_IMG" | cut -f1)
    info "userdata.img : $UIMG_SIZE"
fi
echo ""

# ---------------------------------------------------------------------------
# 2. Check fastboot
# ---------------------------------------------------------------------------
if ! command -v fastboot > /dev/null 2>&1; then
    error "fastboot not found. Install: sudo apt install android-tools-fastboot"
    exit 1
fi

# ---------------------------------------------------------------------------
# 3. Detect device
# ---------------------------------------------------------------------------
info "Waiting for fastboot device..."
echo -e "  ${YELLOW}Put your device in bootloader mode:${NC}"
echo -e "    • Power off → hold Volume Down + Power"
echo -e "    • Or from Android: adb reboot bootloader"
echo ""

FB_DEVICE=""
WAIT=0
while [ $WAIT -lt 60 ]; do
    FB_DEVICE=$(fastboot devices 2>/dev/null | head -1 | awk '{print $1}')
    if [ -n "$FB_DEVICE" ]; then
        break
    fi
    sleep 2
    WAIT=$((WAIT + 2))
    # Print a dot every 10 seconds
    if [ $((WAIT % 10)) -eq 0 ]; then
        echo -n "."
    fi
done
echo ""

if [ -z "$FB_DEVICE" ]; then
    error "No fastboot device detected after 60s."
    error "Check USB connection and ensure device is in bootloader mode."
    exit 1
fi

success "Device detected: $FB_DEVICE"
echo ""

# ---------------------------------------------------------------------------
# 4. Safety confirmation
# ---------------------------------------------------------------------------
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}${BOLD}  ⚠  WARNING: This will OVERWRITE the following partitions:  ${NC}"
echo ""
if [ "$FLASH_SYSTEM" = true ]; then
    echo -e "    ${RED}• system${NC}    (replaces Android with Ubuntu GSI)"
fi
if [ "$FLASH_USERDATA" = true ]; then
    echo -e "    ${RED}• userdata${NC}  (ALL DATA ON DEVICE WILL BE ERASED)"
fi
echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -n -e "${YELLOW}Type 'FLASH' to confirm: ${NC}"
read -r CONFIRM

if [ "$CONFIRM" != "FLASH" ]; then
    info "Cancelled."
    exit 0
fi
echo ""

# ---------------------------------------------------------------------------
# 5. Flash
# ---------------------------------------------------------------------------
if [ "$FLASH_SYSTEM" = true ]; then
    info "Flashing system.img..."
    if fastboot flash system "$SYSTEM_IMG"; then
        success "system.img flashed"
    else
        error "Failed to flash system.img"
        exit 1
    fi
fi

if [ "$FLASH_USERDATA" = true ]; then
    info "Flashing userdata.img (this may take a few minutes)..."
    if fastboot flash userdata "$USERDATA_IMG"; then
        success "userdata.img flashed"
    else
        error "Failed to flash userdata.img"
        exit 1
    fi
fi

echo ""

# ---------------------------------------------------------------------------
# 6. Reboot
# ---------------------------------------------------------------------------
echo -n -e "${YELLOW}Reboot device now? [Y/n]: ${NC}"
read -r REBOOT
if [[ "$REBOOT" != "n" && "$REBOOT" != "N" ]]; then
    info "Rebooting..."
    fastboot reboot
    success "Device rebooting. Ubuntu GSI should start in ~15-30 seconds."
else
    info "Device left in bootloader mode. Reboot manually when ready."
fi

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}${BOLD}Flash complete!${NC}"
echo ""
echo -e "  If the system fails to boot, enter fastboot and reflash."
echo -e "  To trigger a rollback (if previously booted):"
echo -e "    Mount userdata and create: /uhl_overlay/rollback"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
