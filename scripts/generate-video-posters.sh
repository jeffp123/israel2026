#!/bin/bash
# Extracts a poster frame (a couple seconds in, not the first frame — which is
# often a black or transitional frame) for each video under src/assets, saving
# it as <name>-poster.jpg next to the video. Video.astro picks these up
# automatically by filename convention, no per-entry wiring needed.
#
# Run with no arguments to (re-)cover every video under src/assets that's
# missing a poster, or pass explicit video paths to (re-)generate just those.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS="$PROJECT_ROOT/src/assets"
FFMPEG="/opt/homebrew/bin/ffmpeg"
FFPROBE="/opt/homebrew/bin/ffprobe"

force=0
files=()
for arg in "$@"; do
  if [ "$arg" = "--force" ]; then
    force=1
  else
    files+=("$arg")
  fi
done

if [ "${#files[@]}" -eq 0 ]; then
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "$ASSETS" -type f \( -iname '*.mp4' -o -iname '*.mov' \) -print0)
fi

made=0
skipped=0
failed=0

for f in "${files[@]}"; do
  dir=$(dirname "$f")
  base=$(basename "$f")
  name="${base%.*}"
  poster="$dir/$name-poster.jpg"

  if [ "$force" -ne 1 ] && [ -e "$poster" ]; then
    skipped=$((skipped + 1))
    continue
  fi

  duration=$("$FFPROBE" -v quiet -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$f" 2>/dev/null || echo "0")
  # A couple seconds in reads as a real moment from the clip rather than a
  # black/transitional first frame, but short clips need a smaller offset.
  offset=$(awk -v d="$duration" 'BEGIN { t = d * 0.25; if (t > 2) t = 2; if (t < 0.1) t = 0.1; printf "%.2f", t }')

  if "$FFMPEG" -y -v error -ss "$offset" -i "$f" -vframes 1 -q:v 3 "$poster" </dev/null; then
    made=$((made + 1))
  else
    rm -f "$poster"
    failed=$((failed + 1))
  fi
done

echo "$made posters generated, $skipped skipped (already existed), $failed failed"
