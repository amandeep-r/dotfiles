# Kindle Article Sync Tool

Automatically sync markdown articles from your Obsidian vault to your Kindle e-reader via Calibre.

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  Obsidian Vault                                                 │
│  └── Reading/ToReader/*.md                                      │
│                                                                 │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 │ (1) Sync on Kindle plug-in
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  Calibre Library                                                │
│  └── Books tagged "Articles"                                    │
│      • Adds new .md files                                       │
│      • Removes deleted files                                    │
│                                                                 │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 │ (2) Convert & send using template
                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  Kindle E-Reader                                                │
│  └── documents/Articles/*.epub                                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Setup

### 1. Install the Tool

Run the install script to set up automatic sync when you plug in your Kindle:

```bash
cd ~/.dotfiles/reader-articles-sync
sudo ./install.sh
```

This creates:
- A udev rule that detects when your Kindle is plugged in
- A systemd service that launches the sync script in a terminal window

### 2. Configure Calibre Template (IMPORTANT!)

To ensure articles are saved in the `Articles/` folder on your Kindle, you **must** configure Calibre's save template for your device:

#### Steps:

1. **Connect your Kindle** to your computer via USB
2. Wait for Calibre to detect it (you'll see the device icon in the toolbar)
3. Click the **device dropdown** in the toolbar and select **"Configure this device"**
4. In the device configuration window, find the **Save template for this device** section and set:

   ```
   {:'str_in_list($tags, ",", "article", "Articles/", "")'}{title}
   ```

   **What this does:**
   - If a book has a tag containing "article" (case-insensitive), prefix the path with `Articles/`
   - Otherwise, save it to the root directory
   - The final path becomes either `Articles/{title}` or just `{title}`

5. Click **Apply** and **OK**

> **Note:** This template uses the `str_in_list()` function to check if "article" appears anywhere in the tags list, making it case-insensitive and flexible.

### 3. Configure Your Paths

Edit the `config` file to match your setup:

```bash
nano config
```

```bash
WATCH_DIR="$HOME/Documents/ObsidianVault/Reading/ToReader"  # Your Obsidian folder
TAG="Articles"                                               # Calibre tag
READER_MOUNT="/media/$USER/Kindle"                          # Where Kindle mounts
USB_VENDOR="1949"                                            # Kindle USB vendor ID
USB_PRODUCT="0004"                                           # Kindle USB product ID
```

## Usage

### Automatic Sync (Recommended)

1. Plug in your Kindle
2. A terminal window will pop up showing the sync progress
3. Wait for sync to complete
4. Safely eject your Kindle
5. Your articles will be in the `Articles` folder on your Kindle

### Manual Sync

You can also run the sync manually:

```bash
cd ~/.dotfiles/reader-articles-sync
./sync-articles.sh
```

## What the Tool Does

1. **Waits** 5 seconds for your e-reader to be detected
2. **Scans** your Obsidian folder for markdown files
3. **Fetches** existing books from Calibre with the "Articles" tag
4. **Adds** new markdown files to Calibre
5. **Removes** books from Calibre if their source files were deleted
6. **Prepares** the e-reader Articles folder (clears it for fresh sync)

> **Note:** The tool only manages the Calibre library. You still need to use Calibre's "Send to device" feature to actually transfer books to your Kindle. The template ensures they go to the right folder.

## Files

- `config` - Configuration file
- `sync-articles.sh` - Main sync script
- `launch-sync.sh` - Wrapper that launches terminal
- `install.sh` - Install udev rule and systemd service
- `/etc/udev/rules.d/99-kindle-sync.rules` - Auto-trigger rule
- `/etc/systemd/system/kindle-sync@.service` - Systemd service

## Troubleshooting

### Terminal doesn't pop up

Check the systemd service logs:

```bash
journalctl -u "kindle-sync@*" -n 50
```

### Kindle not detected

Verify your Kindle's USB IDs:

```bash
lsusb | grep -i kindle
```

Update `USB_VENDOR` and `USB_PRODUCT` in the `config` file if needed.

### Articles not in Articles folder

Make sure you configured the Calibre template as described in **Setup Step 2**.

### Permission errors

The install script needs sudo access to create udev rules and systemd services.

## Uninstalling

To remove the automatic sync, run the uninstall script:

```bash
cd ~/.dotfiles/reader-articles-sync
sudo ./uninstall.sh
```

This will remove:
- The udev rule (`/etc/udev/rules.d/99-kindle-sync.rules`)
- The systemd service (`/etc/systemd/system/kindle-sync@.service`)
- Reload system configuration

The script files will remain in your dotfiles for manual use if needed.

## Credits

Location: `~/.dotfiles/reader-articles-sync`
