#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config"

KINDLE_ARTICLES="$READER_MOUNT/$ARTICLES_DEST"

echo "======================================"
echo "  Kindle Article Sync"
echo "======================================"
echo ""

echo "Waiting for Kindle at $READER_MOUNT..."
for i in $(seq 1 15); do
    [ -d "$READER_MOUNT" ] && break
    sleep 1
done

if [ ! -d "$READER_MOUNT" ]; then
    echo "ERROR: Kindle not found at $READER_MOUNT"
    exit 1
fi
echo "Kindle mounted."
echo ""
echo "Scanning $VAULT_INBOX for flagged articles..."
echo ""

mkdir -p "$KINDLE_ARTICLES"

sent=0
removed=0
failed=0

while IFS= read -r -d '' file; do
    grep -qm1 '^send_to_reader: true' "$file" || continue
    grep -qm1 '^sent_to_reader: true' "$file" && continue

    filename=$(basename "$file")
    dest="$KINDLE_ARTICLES/$filename"

    awk '
      /^---[[:space:]]*$/ && NR==1 { in_fm=1; next }
      /^---[[:space:]]*$/ && in_fm  { in_fm=0; next }
      !in_fm { print }
    ' "$file" > "$dest"

    if [ $? -ne 0 ]; then
        echo "  FAILED (copy): $filename"
        rm -f "$dest"
        ((failed++))
        continue
    fi

    tmp="${file}.synctmp"
    awk '
      BEGIN { in_fm=0; done=0 }
      /^---[[:space:]]*$/ && NR==1 { in_fm=1; print; next }
      /^---[[:space:]]*$/ && in_fm  { in_fm=0; if (!done) print "sent_to_reader: true"; print; next }
      in_fm && /^sent_to_reader:/      { print "sent_to_reader: true"; done=1; next }
      { print }
    ' "$file" > "$tmp" && mv "$tmp" "$file"

    if [ $? -ne 0 ]; then
        echo "  FAILED (mark): $filename"
        rm -f "$tmp" "$dest"
        ((failed++))
        continue
    fi

    echo "  Sent: $filename"
    ((sent++))

done < <(find "$VAULT_INBOX" -name "*.md" -print0)

echo ""
echo "Checking for articles to remove..."
echo ""

while IFS= read -r -d '' kindle_file; do
    filename=$(basename "$kindle_file")
    vault_file="$VAULT_INBOX/$filename"

    grep -qm1 '^send_to_reader: true' "$vault_file" 2>/dev/null && continue

    rm -f "$kindle_file"
    echo "  Removed: $filename"
    ((removed++))

    if [ -f "$vault_file" ]; then
        tmp="${vault_file}.synctmp"
        sed 's/^sent_to_reader:[[:space:]]*true[[:space:]]*$/sent_to_reader: false/' "$vault_file" > "$tmp" && mv "$tmp" "$vault_file"
    fi

done < <(find "$KINDLE_ARTICLES" -name "*.md" -print0)

echo ""
echo "Done. Sent: $sent, Removed: $removed, Failed: $failed"
