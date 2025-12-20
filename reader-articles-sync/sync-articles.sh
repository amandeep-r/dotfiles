#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config"

READER_ARTICLES="$READER_MOUNT/documents/Articles"

echo "======================================"
echo "  Kindle Article Sync Tool"
echo "======================================"
echo ""
echo "This tool syncs markdown articles from your Obsidian vault to your Kindle."
echo ""
echo "What it does:"
echo "  1. Scans: $WATCH_DIR"
echo "  2. Syncs with Calibre library (tag: '$TAG')"
echo "  3. Prepares articles for your e-reader"
echo ""
echo "Configuration: $SCRIPT_DIR/config"
echo "======================================"
echo ""
echo "Waiting 5 seconds for e-reader to be detected..."
sleep 5

echo "Checking if e-reader is mounted at $READER_MOUNT..."
if [ ! -d "$READER_MOUNT" ]; then
    echo "ERROR: E Reader not mounted at $READER_MOUNT"
    exit 1
fi
echo "E-reader detected successfully"

echo ""
echo "Scanning for markdown files in $WATCH_DIR..."
declare -A folder_files
for file in "$WATCH_DIR"/*.md; do
    [ -f "$file" ] || continue
    name=$(basename "$file" .md)
    folder_files["$name"]=1
done
echo "Found ${#folder_files[@]} markdown file(s)"

echo ""
echo "Fetching books from Calibre with tag '$TAG'..."
declare -A calibre_books
while IFS=$'\t' read -r id title; do
    calibre_books["$title"]="$id"
done < <(calibredb list --search "tags:$TAG" --fields "id,title" --for-machine | jq -r '.[] | [.id, .title] | @tsv')
echo "Found ${#calibre_books[@]} book(s) in Calibre with tag '$TAG'"

echo ""
echo "Syncing new files to Calibre..."
added_count=0
for name in "${!folder_files[@]}"; do
    if [[ -z "${calibre_books[$name]}" ]]; then
        echo "  Adding: $name"
        calibredb add "$WATCH_DIR/$name.md" --tags "$TAG"
        ((added_count++))
    fi
done
if [ $added_count -eq 0 ]; then
    echo "  No new files to add"
fi

echo ""
echo "Removing deleted files from Calibre..."
removed_count=0
for title in "${!calibre_books[@]}"; do
    if [[ -z "${folder_files[$title]+x}" ]]; then
        echo "  Removing: $title"
        calibredb remove "${calibre_books[$title]}"
        ((removed_count++))
    fi
done
if [ $removed_count -eq 0 ]; then
    echo "  No files to remove"
fi

echo ""
echo "Preparing e-reader Articles folder..."
echo "  Clearing: $READER_ARTICLES"
rm -rf "$READER_ARTICLES"
mkdir -p "$READER_ARTICLES"
echo "  Folder ready"

echo ""
echo "Sync complete!"