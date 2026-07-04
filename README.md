# Hibernate Installer

Hibernate Installer is a safety-focused Ubuntu utility for configuring Linux hibernation with minimal user interaction.

## Version

v1.0.0 (development bootstrap)

## Supported systems

Phase 1 targets Ubuntu 24.04 LTS and Ubuntu 26.04 LTS with ext4, GNOME, GRUB, initramfs-tools, and a swapfile.

## Installation

```bash
sudo ./install.sh
```

The bootstrap milestone verifies root privileges and supported Ubuntu releases before later milestones add system modification logic.

## How it works

The project is modular. Each responsibility lives under `lib/` and is loaded by the installer as functionality is implemented.

## Troubleshooting

Logs are written to `/var/log/hibernate-installer.log` when run as root.

## FAQ

### Does the bootstrap modify hibernation settings?

No. The bootstrap only performs initial checks and logging.

## Screenshots

Screenshots will be added when user-visible configuration flows are implemented.

## Known limitations

The bootstrap milestone does not yet configure swap, GRUB, initramfs, GNOME, or polkit.
