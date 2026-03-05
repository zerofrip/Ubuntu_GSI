# Unified Modular GSI Framework

This repository represents the culmination of Treble-native Linux integrations. The Unified Architecture introduces fundamentally robust, adaptive scripting designed expressly to identify hardware targets perfectly, falling back intelligently on errors rather than fatally halting the graphical stack!

## Key Refinements Over Prior Approaches

- **Adaptive GPU Bridging (`gpu-bridge.sh`):** Scans the `/vendor` abstraction locally. Sets Wayland mappings using Vulkan (`Zink`), EGL (`libhybris`), or forcibly engaging Software `llvmpipe` rendering. Employs active crash-trapping preventing visual lockup implicitly.
- **Universal HAL Degradation (`detect-hal-version.sh`):** Probes the VINTF manifest. If specific modules (like cameras) are missing from the obscure vendor topology, the DAEMON gracefully mocks the `/dev/uhl/` interaction strictly preventing fatal loop exhaustion across Canonical services natively.
- **Safe Pivot Dynamic RootFS:** Fuses Linux over an `overlayfs` bounds. Contains snapshot routing allowing explicit rollback capability safely undoing OS updates.

## Build Instructions

Using `arm64` hosts with available `sudo` environments:
```bash
chmod +x scripts/*.sh init/*.sh system/gpu-wrapper/*.sh system/uhl/*.sh system/haf/*.sh
sudo ./scripts/build-gsi.sh . ubuntu-touch-hybrid-unified.img
```
*Note:* Execution logic relies upon placing `squashfs` root topologies specifically against Android userdata payloads.

## References and Attributions
The Unified Modular GSI aggregates concepts inherently pioneered by:
- **UBports Foundation:** Architecting the core Lomiri frameworks.
- **Libhybris & Halium Teams:** Pioneering initial Bionic to glibc translational abstractions mapping Android limits aggressively.
- **Waydroid Project:** Generating seamless isolated bridging concepts within generic subsystems natively.
- Concepts developed in alignment with XDA discussions located here:
`https://xdaforums.com/t/gsi-arm64-a-ab-ubuntu-touch-ubports.4110581/`
