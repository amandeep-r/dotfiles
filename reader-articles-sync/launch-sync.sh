#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gnome-terminal -- bash -c "$SCRIPT_DIR/sync-articles.sh; echo ''; read -p 'Press Enter to close...'"
