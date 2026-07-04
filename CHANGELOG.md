# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-07-04

### Added

- Full Phase 1 installer workflow for Ubuntu 24.04 LTS and 26.04 LTS.
- ext4 filesystem validation.
- RAM and swapfile detection.
- Recommended swap sizing and safe swapfile creation/replacement.
- Swapfile extent validation with `filefrag`.
- Automatic resume UUID and resume offset detection.
- GRUB resume parameter preservation and update logic.
- initramfs resume configuration and update logic.
- GNOME/systemd hibernate policy configuration.
- Polkit rule for local active users to run hibernate.
- Verification checks for swap, fstab, GRUB, resume offset, and initramfs configuration.
- Uninstaller for managed configuration.
- Dry-run, verbose, debug, and yes modes.
- ShellCheck GitHub Actions workflow and bootstrap syntax tests.
