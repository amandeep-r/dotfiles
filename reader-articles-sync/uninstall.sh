#!/bin/bash

echo "======================================"
echo "  Kindle Sync Uninstaller"
echo "======================================"
echo ""
echo "This will remove:"
echo "  - udev rule: /etc/udev/rules.d/99-kindle-sync.rules"
echo "  - systemd service: /etc/systemd/system/kindle-sync@.service"
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo "Removing udev rule..."
if [ -f /etc/udev/rules.d/99-kindle-sync.rules ]; then
    sudo rm /etc/udev/rules.d/99-kindle-sync.rules
    echo "  ✓ Removed /etc/udev/rules.d/99-kindle-sync.rules"
else
    echo "  ℹ No udev rule found (already removed)"
fi

echo ""
echo "Removing systemd service..."
if [ -f /etc/systemd/system/kindle-sync@.service ]; then
    # Stop any running instances
    sudo systemctl stop "kindle-sync@*.service" 2>/dev/null
    sudo rm /etc/systemd/system/kindle-sync@.service
    echo "  ✓ Removed /etc/systemd/system/kindle-sync@.service"
else
    echo "  ℹ No systemd service found (already removed)"
fi

echo ""
echo "Reloading system configuration..."
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
echo "  ✓ System configuration reloaded"

echo ""
echo "======================================"
echo "  Uninstall Complete!"
echo "======================================"
echo ""
echo "The automatic sync has been disabled."
echo "You can still run sync-articles.sh manually if needed."
echo ""
