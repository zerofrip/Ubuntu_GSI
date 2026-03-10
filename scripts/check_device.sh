#!/bin/bash
# =============================================================================
# scripts/check_device.sh — Pre-Flash Device Validator
# =============================================================================
# Checks device readiness before flashing the Ubuntu GSI.
# Supports both ADB (pre-flash) and Fastboot modes.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

pass()    { echo -e "  ${GREEN}✔${NC}  $1"; }
fail()    { echo -e "  ${RED}✘${NC}  $1"; ERRORS=$((ERRORS + 1)); }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $1"; WARNINGS=$((WARNINGS + 1)); }
info()    { echo -e "  ${CYAN}ℹ${NC}  $1"; }

ERRORS=0
WARNINGS=0

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}         Ubuntu GSI — Device Compatibility Check              ${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# ---------------------------------------------------------------------------
# 1. Check host tools
# ---------------------------------------------------------------------------
echo -e "${BOLD}[1/4] Host Tools${NC}"

if command -v fastboot > /dev/null 2>&1; then
    pass "fastboot available"
else
    fail "fastboot not found — install: sudo apt install android-tools-fastboot"
fi

if command -v adb > /dev/null 2>&1; then
    pass "adb available (for pre-flash checks)"
else
    warn "adb not found — pre-flash device checks will be skipped"
fi
echo ""

# ---------------------------------------------------------------------------
# 2. Detect device mode
# ---------------------------------------------------------------------------
echo -e "${BOLD}[2/4] Device Detection${NC}"

FB_DEVICE=$(fastboot devices 2>/dev/null | head -1 | awk '{print $1}')
ADB_DEVICE=$(adb devices 2>/dev/null | grep -w "device" | head -1 | awk '{print $1}')

if [ -n "$FB_DEVICE" ]; then
    pass "Device in FASTBOOT mode: $FB_DEVICE"
    DEVICE_MODE="fastboot"
elif [ -n "$ADB_DEVICE" ]; then
    pass "Device in ADB mode: $ADB_DEVICE"
    DEVICE_MODE="adb"
else
    fail "No device detected. Connect via USB and enable debugging."
    echo ""
    echo -e "  ${BOLD}To enter fastboot mode:${NC}"
    echo -e "    Power off → hold Volume Down + Power"
    echo -e "    Or: adb reboot bootloader"
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${RED}${BOLD}RESULT: $ERRORS error(s)${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    exit 1
fi
echo ""

# ---------------------------------------------------------------------------
# 3. Device compatibility (ADB mode only)
# ---------------------------------------------------------------------------
echo -e "${BOLD}[3/4] Device Compatibility${NC}"

if [ "$DEVICE_MODE" = "adb" ]; then
    # Treble support
    TREBLE=$(adb shell getprop ro.treble.enabled 2>/dev/null || echo "")
    if [ "$TREBLE" = "true" ]; then
        pass "Project Treble: supported"
    elif [ -z "$TREBLE" ]; then
        warn "Treble support: unknown (could not read property)"
    else
        fail "Project Treble: NOT supported — GSI requires Treble"
    fi

    # Architecture
    ARCH=$(adb shell getprop ro.product.cpu.abi 2>/dev/null || echo "")
    if [ "$ARCH" = "arm64-v8a" ]; then
        pass "Architecture: arm64 ✓"
    elif [ -n "$ARCH" ]; then
        warn "Architecture: $ARCH (this GSI targets arm64)"
    fi

    # Dynamic partitions
    DYNAMIC=$(adb shell getprop ro.boot.dynamic_partitions 2>/dev/null || echo "")
    if [ "$DYNAMIC" = "true" ]; then
        pass "Dynamic partitions: supported"
    elif [ -z "$DYNAMIC" ]; then
        info "Dynamic partitions: unknown"
    else
        warn "Dynamic partitions: not detected — may need legacy flash method"
    fi

    # Device info
    MODEL=$(adb shell getprop ro.product.model 2>/dev/null || echo "Unknown")
    ANDROID=$(adb shell getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    VNDK=$(adb shell getprop ro.vndk.version 2>/dev/null || echo "Unknown")

    info "Device: $MODEL"
    info "Android: $ANDROID"
    info "VNDK version: $VNDK"

elif [ "$DEVICE_MODE" = "fastboot" ]; then
    # Limited checks in fastboot mode
    UNLOCKED=$(fastboot getvar unlocked 2>&1 | grep "unlocked:" | awk '{print $2}')
    if [ "$UNLOCKED" = "yes" ]; then
        pass "Bootloader: unlocked"
    elif [ "$UNLOCKED" = "no" ]; then
        fail "Bootloader: LOCKED — unlock before flashing"
        echo -e "    ${YELLOW}Run: fastboot flashing unlock${NC}"
    else
        warn "Bootloader lock status: unknown"
    fi

    # Check partition existence
    SLOT=$(fastboot getvar current-slot 2>&1 | grep "current-slot:" | awk '{print $2}')
    if [ -n "$SLOT" ]; then
        pass "A/B device detected (current slot: $SLOT)"
    else
        info "A/B slot information unavailable"
    fi
fi
echo ""

# ---------------------------------------------------------------------------
# 4. Summary
# ---------------------------------------------------------------------------
echo -e "${BOLD}[4/4] Flash Readiness${NC}"

if [ "$DEVICE_MODE" = "adb" ]; then
    info "Device is in ADB mode. To flash, reboot to bootloader:"
    echo -e "    ${CYAN}adb reboot bootloader${NC}"
    echo -e "    Then run: ${CYAN}bash scripts/flash.sh${NC}"
elif [ "$DEVICE_MODE" = "fastboot" ]; then
    if [ "$ERRORS" -eq 0 ]; then
        pass "Device is ready for flashing"
        echo -e "    Run: ${CYAN}bash scripts/flash.sh${NC}"
    fi
fi

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
if [ "$ERRORS" -gt 0 ]; then
    echo -e "  ${RED}${BOLD}RESULT: $ERRORS error(s), $WARNINGS warning(s)${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    exit 1
else
    echo -e "  ${GREEN}${BOLD}RESULT: Device checks passed ($WARNINGS warning(s))${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    exit 0
fi
