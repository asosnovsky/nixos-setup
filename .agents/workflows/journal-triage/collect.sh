#!/bin/sh
# Collect journald warnings+ and failed units into the run folder, plus a deduplicated digest.
set -eu
since="$1"; priority="$2"
dir="$NBOT_WF_RUN_DIR"
raw="$dir/journal-raw.log"; digest="$dir/journal-digest.txt"

journalctl -p "$priority" --since "$since" --no-pager -q -o short-iso > "$raw" || true

{
  echo "=== Failed systemd units ==="
  systemctl --failed --no-legend --plain || true
  systemctl --user --failed --no-legend --plain 2>/dev/null || true
  echo
  echo "=== Boots in window ==="
  journalctl --list-boots --no-pager -q | tail -5 || true
  echo
  echo "=== Unique messages (count, source: message; numbers/hex normalized), most frequent first ==="
  cut -d' ' -f3- "$raw" \
    | sed -E 's/\[[0-9]+\]//; s/0x[0-9a-fA-F]+/0xN/g; s/[0-9]+/N/g' \
    | sort | uniq -c | sort -rn | head -400
} > "$digest"

lines=$(wc -l < "$raw")
uniq=$(grep -c '^ *[0-9]' "$digest" || true)
printf 'raw_log=%s\ndigest=%s\nlines=%s\nunique=%s\n' "$raw" "$digest" "$lines" "$uniq" >> "$NBOT_WF_OUTPUTS"
