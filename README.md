# Hibernate Installer

Hibernate Installer is a safety-focused Ubuntu utility that configures Linux hibernation with minimal user interaction while preserving existing system configuration.

## Version

v1.0.0

## Supported systems

Phase 1 supports:

- Ubuntu 24.04 LTS and Ubuntu 26.04 LTS
- ext4 root filesystem
- GNOME desktop
- GRUB bootloader
- initramfs-tools
- swapfile-based hibernation

Unsupported in Phase 1: Btrfs, XFS, ZFS, swap partitions, LVM, LUKS, Fedora, Debian, Pop!_OS, and Secure Boot integration.

## Installation

```bash
git clone https://github.com/your-org/hibernate-installer.git
cd hibernate-installer
sudo ./install.sh
```

Useful options:

```bash
sudo ./install.sh --dry-run
sudo ./install.sh --verbose
sudo ./install.sh --debug
sudo ./install.sh --yes
HI_STRICT_EXTENTS=1 sudo ./install.sh
```

## How it works

The installer runs these steps in order:

1. Verifies root privileges.
2. Detects Ubuntu release support.
3. Verifies the root filesystem is ext4.
4. Detects RAM, active swap, boot mode, Secure Boot state, GRUB, and initramfs-tools.
5. Creates timestamped backups under `/var/backups/hibernate-installer/`.
6. Creates or replaces a swapfile according to the recommended size policy.
7. Validates swapfile extents using `filefrag`.
8. Detects resume UUID and resume offset automatically.
9. Preserves existing GRUB kernel parameters while replacing old resume parameters.
10. Writes `/etc/initramfs-tools/conf.d/resume`.
11. Installs a small systemd oneshot service that populates `/sys/power/resume` and `/sys/power/resume_offset` at boot for systems where systemd does not populate them from the kernel command line.
12. Runs `update-grub` and `update-initramfs -u`.
13. Verifies swap, fstab, GRUB, resume offset, initramfs resume configuration, and the resume sysfs service.
14. Offers a reboot.

## Swap size policy

- RAM <= 8 GiB: 8 GiB swap
- RAM <= 16 GiB: 20 GiB swap
- RAM <= 32 GiB: 40 GiB swap
- RAM > 32 GiB: RAM + 4 GiB swap

## Uninstall

```bash
sudo ./uninstall.sh
```

The uninstaller backs up current files, restores the latest Hibernate Installer backup when available, removes managed resume parameters or generated initramfs/systemd/polkit files, and regenerates GRUB/initramfs when available.

## Logging

Logs are written to:

```text
/var/log/hibernate-installer.log
```

## Troubleshooting

- If the installer reports an unsupported filesystem, do not force it. Resume offsets are filesystem-specific.
- If `filefrag` reports multiple extents, the installer retries swapfile creation up to three times. By default it then continues with a warning because Ubuntu/Linux can resume from a swapfile using the first physical offset; set `HI_STRICT_EXTENTS=1` to abort instead.
- If `systemctl hibernate` reports `Invalid resume config: resume= is not populated yet resume_offset= is`, rerun the latest installer. It installs `hibernate-installer-resume.service`, which writes the resume device and offset into `/sys/power/resume*` at boot.
- If hibernation fails after installation, reboot once and check `/proc/cmdline`, `/etc/initramfs-tools/conf.d/resume`, `systemctl status hibernate-installer-resume.service`, and `/var/log/hibernate-installer.log`.

## FAQ

### Does this overwrite my GRUB command line?

No. Existing kernel parameters are parsed and preserved. Old `resume=` and `resume_offset=` parameters are removed before the new values are appended.

### Does this support encrypted disks?

Not yet. LUKS support is planned for a future phase.

### Does this disable Secure Boot?

No. Phase 1 detects Secure Boot and warns when it is enabled, but does not change Secure Boot policy.

## Screenshots

The installer uses colored terminal output with INFO, SUCCESS, WARNING, and ERROR messages.

## Known limitations

This release intentionally limits support to the Phase 1 target platform to avoid unsafe configuration on systems that need different resume logic.
