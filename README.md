# NVIDIA Driver Manager

A Debian-native management utility for NVIDIA's proprietary Linux driver.

## Overview

NVIDIA Driver Manager automatically checks NVIDIA's UNIX driver page for new
Production Branch releases, downloads new drivers, and installs them using
NVIDIA's official `.run` installer while integrating with DKMS and Secure Boot.

The project is specifically designed for Debian Trixie systems using the
official NVIDIA installer instead of Debian-packaged drivers.

## Configuration File

Update your configuration preferences in /etc/nvidia-driver-manager.conf

## Features

- Weekly automatic update checks
- Parses NVIDIA's UNIX driver page
- Downloads the latest Production Branch driver
- Uses NVIDIA's official installer
- Builds DKMS modules for every installed kernel
- Secure Boot aware
- Automatically repairs known DKMS permission issues
- Installation health checks
- Logging
- Zenity GUI
- PolicyKit integration
- Debian package

## Current Status

Development Version 1.0.4

Initial build works.  Recently added dependecies.

## Requirements

Debian Trixie (13)

Systemd

DKMS

Official NVIDIA .run installer

Installing from .deb file, please run apt-get install --fix-broken to install dependencies.

## Building

```bash
dpkg-buildpackage -us -uc
```

## License

GPL-3.0-or-later
