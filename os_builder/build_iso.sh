#!/bin/bash
# Build a bootable ISO that starts the icosahedron file manager.
# This script uses debootstrap and grub to create a minimal Debian-based
# system which automatically launches the icoTest Python application on boot.
# Note: running this script requires root privileges and network access.

set -e

# Directory layout
WORKDIR=$(pwd)/build_root
ISODIR=$(pwd)/iso_root

# Clean previous runs
sudo rm -rf "$WORKDIR" "$ISODIR"
mkdir -p "$WORKDIR" "$ISODIR"

# Create minimal filesystem with debootstrap
sudo debootstrap --variant=minbase stable "$WORKDIR" http://deb.debian.org/debian

# Install packages inside the new root
sudo chroot "$WORKDIR" bash -c "apt-get update && apt-get install -y python3 python3-pip panda3d python3-panda3d libgl1-mesa-dri xserver-xorg xinit fluxbox"

# Copy icoTest application
sudo mkdir -p "$WORKDIR/opt/icosa"
sudo cp ../icoTest "$WORKDIR/opt/icosa/icoTest.py"

# Create startup script that launches X and the application
echo '#!/bin/bash
startx /usr/local/bin/start_icosa.sh' | sudo tee "$WORKDIR/usr/local/bin/autostart.sh" > /dev/null
sudo chmod +x "$WORKDIR/usr/local/bin/autostart.sh"

# Script launched by X
sudo tee "$WORKDIR/usr/local/bin/start_icosa.sh" > /dev/null <<'EOL'
#!/bin/bash
fluxbox &
python3 /opt/icosa/icoTest.py
EOL
sudo chmod +x "$WORKDIR/usr/local/bin/start_icosa.sh"

# Configure system to autologin and run autostart.sh
sudo tee "$WORKDIR/etc/systemd/system/getty@tty1.service.d/autologin.conf" > /dev/null <<'EOL'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
EOL

sudo tee "$WORKDIR/root/.bash_profile" > /dev/null <<'EOL'
if [ -z "$DISPLAY" ] && [ $(tty) = /dev/tty1 ]; then
  /usr/local/bin/autostart.sh
fi
EOL

# Install GRUB
sudo grub-install --target=i386-pc --boot-directory="$WORKDIR/boot" --root-directory="$WORKDIR" --modules="linux normal iso9660 multiboot" --no-floppy --force /dev/loop0

# Create a basic GRUB config
sudo tee "$WORKDIR/boot/grub/grub.cfg" > /dev/null <<'EOL'
set timeout=5
set default=0

menuentry "3D Icosahedron OS" {
    linux /boot/vmlinuz root=/dev/sr0 rw quiet
    initrd /boot/initrd.img
}
EOL

# Create initrd and kernel packages
sudo chroot "$WORKDIR" bash -c "apt-get install -y linux-image-amd64"

# Copy kernel and initrd to ISO directory
sudo cp "$WORKDIR/boot/vmlinuz" "$ISODIR/"
sudo cp "$WORKDIR/boot/initrd.img" "$ISODIR/"
sudo mkdir -p "$ISODIR/boot/grub"
sudo cp "$WORKDIR/boot/grub/grub.cfg" "$ISODIR/boot/grub/"

# Build ISO
grub-mkrescue -o icosa_os.iso "$WORKDIR" -- -volid "ICOSADISK" -iso-level 3

echo "ISO generated: icosa_os.iso"
