# OS Builder

This directory contains a script to generate a bootable ISO that runs the
`icoTest` application as a touch‐friendly file manager. The script builds a
minimal Debian-based system, installs Panda3D, and configures automatic
startup of the icosahedron interface when the system boots on a touchscreen
device.

## Requirements

- Linux host with `debootstrap`, `grub-mkrescue`, `xorriso` and `sudo`
- Internet connection to download Debian packages
- Sufficient permissions to run `sudo` commands

## Building the ISO

Run the following from the repository root:

```bash
cd os_builder
./build_iso.sh
```

If successful, an `icosa_os.iso` file will be created in the `os_builder`
directory. This ISO can be written to a USB drive or booted in a virtual
machine.
