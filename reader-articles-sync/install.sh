#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config"

chmod +x "$SCRIPT_DIR/sync-articles.sh"
chmod +x "$SCRIPT_DIR/launch-sync.sh"

UDEV_RULE="ACTION==\"add\", KERNEL==\"sd?1\", SUBSYSTEMS==\"usb\", ATTRS{idVendor}==\"$USB_VENDOR\", ATTRS{idProduct}==\"$USB_PRODUCT\", TAG+=\"systemd\", ENV{SYSTEMD_WANTS}=\"kindle-sync@%k.service\""

echo "$UDEV_RULE" | sudo tee /etc/udev/rules.d/99-kindle-sync.rules

# Get user's home directory for the actual user (not root)
ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo ~$ACTUAL_USER)

# Create systemd service
sudo tee /etc/systemd/system/kindle-sync@.service > /dev/null << EOF
[Unit]
Description=Sync articles to Kindle
After=media-$ACTUAL_USER-Kindle.mount

[Service]
Type=oneshot
User=$ACTUAL_USER
Environment="DISPLAY=:0"
Environment="WAYLAND_DISPLAY=wayland-0"
Environment="XDG_RUNTIME_DIR=/run/user/$(id -u $ACTUAL_USER)"
Environment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u $ACTUAL_USER)/bus"
ExecStart=$SCRIPT_DIR/launch-sync.sh
EOF

sudo systemctl daemon-reload
sudo udevadm control --reload-rules

echo "Installed. Replug your E Reader to test."