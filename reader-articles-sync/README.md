# Kindle Article Sync

Syncs flagged markdown articles from an Obsidian inbox to a Kindle for reading in KOReader.

## Flow

```
Obsidian vault (reading inbox)
  └── article.md  ← send_to_kindle: true, kindle_sent: (unset)
          │
          │  USB plug-in triggers udev → systemd → sync script
          ▼
Kindle /documents/Articles/article.md  ← frontmatter stripped
          │
          └── source note marked kindle_sent: true (atomic write)
```

No epub conversion. KOReader renders `.md` natively. Remote images in articles won't load (URLs aren't fetched/embedded).

Note that Koreader will not enable mass usb storage mode on kindle devices. You must exit Koreader.

## Setup

### 1. Configure paths

Edit `config`:

```bash
VAULT_INBOX="$HOME/Documents/ObsidianVault/Reading/Inbox"  # folder containing clipped articles
READER_MOUNT="/media/$USER/Kindle"                          # where Ubuntu auto-mounts the Kindle
USB_VENDOR="1949"                                            # Kindle USB vendor ID
USB_PRODUCT="0004"                                           # Kindle USB product ID
```

To find your Kindle's USB IDs:

```bash
lsusb | grep -i kindle
# example: Bus 001 Device 005: ID 1949:0004 Amazon.com, Inc. Kindle
#                                  ^^^^ ^^^^
```

### 2. Install the trigger

```bash
cd ~/.dotfiles/reader-articles-sync
sudo ./install.sh
```

This creates:
- `/etc/udev/rules.d/99-kindle-sync.rules` — fires on Kindle USB plug-in
- `/etc/systemd/system/kindle-sync@.service` — launches a terminal running the sync script

### 3. Set up your Obsidian notes

Articles need these frontmatter properties:

```yaml
---
send_to_kindle: true    # checkbox — set this to queue the article
kindle_sent: false      # managed by the script; leave unset or false
---
```

The Obsidian Web Clipper template should include `send_to_kindle: false` by default so you can flip it per-article during triage.

## Usage

1. Triage articles in Obsidian: set `send_to_kindle: true` on notes you want to read
2. Plug in the Kindle via USB
3. A terminal window opens showing sync progress
4. Eject the Kindle
5. In KOReader, browse to `Documents → Articles`

Articles are only sent once. After transfer the source note gets `kindle_sent: true` so replug-ins skip it.

## Manual sync

```bash
cd ~/.dotfiles/reader-articles-sync
./sync-articles.sh
```

## Troubleshooting

**Terminal doesn't appear on plug-in**

```bash
journalctl -u "kindle-sync@*" -n 50
```

**Kindle not detected**

Verify the Kindle is mounted:
```bash
ls /media/$USER/
```

Check that USB IDs in `config` match `lsusb` output.

**Article shows up with raw YAML at the top**

The script strips the frontmatter block before copying. If you see `---` text, the file may not have a well-formed frontmatter block (opening `---`, content, closing `---` on its own line).

## Uninstall

```bash
sudo ./uninstall.sh
```

## Files

| File | Purpose |
|------|---------|
| `config` | Paths and USB IDs |
| `sync-articles.sh` | Main sync script |
| `launch-sync.sh` | Opens terminal window for the script |
| `install.sh` | Installs udev rule + systemd service |
| `uninstall.sh` | Removes udev rule + systemd service |
