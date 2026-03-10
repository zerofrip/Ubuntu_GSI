#!/bin/bash
# =============================================================================
# scripts/install.sh — Device Flash & Install Helper (Fastboot-Only)
# =============================================================================
# Wrapper around flash.sh for backward compatibility.
# All installation is done via fastboot — no adb required.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Delegate to flash.sh
exec bash "$SCRIPT_DIR/flash.sh" "$@"
