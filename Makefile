# =============================================================================
# Makefile — Ubuntu GSI Build System
# =============================================================================

.DEFAULT_GOAL := help

.PHONY: help all build rootfs squashfs system userdata package \
        flash flash-system flash-userdata \
        check check-device clean lint

# =============================================================================
# Build Targets
# =============================================================================

help: ## Show available targets
	@echo ""
	@echo "Ubuntu GSI — Build System"
	@echo "══════════════════════════════════════════════════"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""

all: build ## Build everything (alias for 'build')

build: ## Full build: rootfs → squashfs → system.img → userdata.img
	@bash build.sh

rootfs: ## Build Ubuntu rootfs from scratch (requires sudo)
	@sudo bash scripts/build_rootfs.sh

squashfs: ## Compile rootfs into SquashFS
	@bash builder/scripts/rootfs-builder.sh

system: ## Generate system.img only
	@bash builder/scripts/gsi-pack.sh

userdata: ## Generate userdata.img only
	@bash scripts/build_userdata_img.sh

package: squashfs system userdata ## Build all flashable images (without rootfs)

# =============================================================================
# Flash Targets
# =============================================================================

flash: ## Flash all images to device via fastboot
	@bash scripts/flash.sh

flash-system: ## Flash system.img only
	@bash scripts/flash.sh --system-only

flash-userdata: ## Flash userdata.img only
	@bash scripts/flash.sh --userdata-only

# =============================================================================
# Validation Targets
# =============================================================================

check: ## Validate host build environment
	@bash scripts/check_environment.sh

check-device: ## Check device compatibility before flashing
	@bash scripts/check_device.sh

lint: ## Run ShellCheck on all scripts
	@echo "Running ShellCheck..."
	@find . -name '*.sh' \
		-not -path './third_party/*' \
		-not -path './builder/out/*' \
		-print0 | xargs -0 shellcheck --severity=warning && \
		echo "All scripts passed." || \
		echo "ShellCheck found issues (see above)."

# =============================================================================
# Maintenance
# =============================================================================

clean: ## Remove all build artifacts
	@echo "Cleaning build artifacts..."
	rm -rf builder/out/system.img
	rm -rf builder/out/linux_rootfs.squashfs
	rm -rf builder/out/userdata.img
	rm -rf builder/out/gsi_sys
	rm -rf builder/out/ubuntu-rootfs
	rm -rf builder/out/userdata_staging
	@echo "Done."

gui-install: ## Install Lomiri GUI stack (requires sudo, run in chroot)
	@sudo bash gui/install_lomiri.sh
