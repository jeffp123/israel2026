#!/bin/bash
# Resize+copy dropped photos/videos into src/assets/<date>/<HHMMSS>.<ext>.
#
# Photos get resized (max 2400px edge, quality 82) via ImageMagick; videos
# are copied through untouched. <date> (folder) and <HHMMSS> (filename) are
# both read from metadata embedded in the file itself wherever possible, so
# naming is consistent regardless of where it was dragged from (Finder, a
# staging export folder, or directly out of Photos.app — which hands off a
# temp file with a random UUID name and no useful folder structure):
#   photos: EXIF DateTimeOriginal
#   videos: QuickTime com.apple.quicktime.creationdate (has the capture
#           timezone baked in, so no conversion needed), else the UTC
#           creation_time tag converted to local time.
#
# Fallback chain if no embedded date is found:
#   date:  parent folder name if it looks like YYYY-MM-DD, else file's local
#          modification date.
#   time:  file's local modification time.
#
# Same-second collisions (e.g. burst shots) get a -2, -3, ... suffix.
# Invoked by the "Import to israel2026" droplet app.
set -euo pipefail

PROJECT_ASSETS="/Users/chaim/Projects/israel2026/src/assets"
MAGICK="/opt/homebrew/bin/magick"
SIPS="/usr/bin/sips"
FFPROBE="/opt/homebrew/bin/ffprobe"

success=0
skip=0
last_dest=""

# Sets date_folder/time_str from the file's own local modification time,
# or from its parent folder name if that already looks like YYYY-MM-DD.
fallback_datetime() {
  local src="$1"
  local parent_name
  parent_name=$(basename "$(dirname "$src")")
  if [[ "$parent_name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    date_folder="$parent_name"
  else
    date_folder=$(stat -f "%Sm" -t "%Y-%m-%d" "$src")
  fi
  time_str=$(stat -f "%Sm" -t "%H%M%S" "$src")
}

for f in "$@"; do
  if [ -d "$f" ]; then
    skip=$((skip + 1))
    continue
  fi

  ext="${f##*.}"
  ext_lower=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

  is_video=0
  case "$ext_lower" in
    jpg | jpeg | heic) out_ext="jpg" ;;
    png) out_ext="png" ;;
    mov | mp4 | m4v) out_ext="$ext_lower"; is_video=1 ;;
    *)
      skip=$((skip + 1))
      continue
      ;;
  esac

  if [ "$is_video" = "1" ]; then
    # Prefer the tag that already includes the capture timezone offset.
    qt_date=$("$FFPROBE" -v quiet -show_entries format_tags=com.apple.quicktime.creationdate \
      -of default=noprint_wrappers=1:nokey=1 "$f" 2>/dev/null || true)
    if [[ "$qt_date" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2}) ]]; then
      date_folder="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
      time_str="${BASH_REMATCH[4]}${BASH_REMATCH[5]}${BASH_REMATCH[6]}"
    else
      # UTC "creation_time" tag, e.g. "2026-07-27T13:35:39.000000Z" — convert to local.
      utc_date=$("$FFPROBE" -v quiet -show_entries format_tags=creation_time \
        -of default=noprint_wrappers=1:nokey=1 "$f" 2>/dev/null || true)
      if [[ "$utc_date" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})T([0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
        local_dt=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "${BASH_REMATCH[1]} ${BASH_REMATCH[2]} +0000" "+%Y-%m-%d %H%M%S" 2>/dev/null || true)
        if [ -n "$local_dt" ]; then
          date_folder="${local_dt% *}"
          time_str="${local_dt#* }"
        else
          fallback_datetime "$f"
        fi
      else
        fallback_datetime "$f"
      fi
    fi
  else
    cleanup_tmp=""
    if [ "$ext_lower" = "heic" ]; then
      working_file=$(mktemp -t import_photo).jpg
      "$SIPS" -s format jpeg "$f" --out "$working_file" >/dev/null
      cleanup_tmp="$working_file"
    else
      working_file="$f"
    fi

    # EXIF DateTimeOriginal, e.g. "2026:08:03 13:08:28".
    exif_date=$("$MAGICK" identify -format "%[EXIF:DateTimeOriginal]" "$working_file" 2>/dev/null || true)
    if [[ "$exif_date" =~ ^([0-9]{4}):([0-9]{2}):([0-9]{2})\ ([0-9]{2}):([0-9]{2}):([0-9]{2}) ]]; then
      date_folder="${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}"
      time_str="${BASH_REMATCH[4]}${BASH_REMATCH[5]}${BASH_REMATCH[6]}"
    else
      fallback_datetime "$f"
    fi
  fi

  dest_dir="$PROJECT_ASSETS/$date_folder"
  mkdir -p "$dest_dir"

  out_name="$time_str.$out_ext"
  n=1
  while [ -e "$dest_dir/$out_name" ]; do
    n=$((n + 1))
    out_name="${time_str}-$n.$out_ext"
  done

  if [ "$is_video" = "1" ]; then
    cp "$f" "$dest_dir/$out_name"
  else
    "$MAGICK" "$working_file" -resize '2400x2400>' -quality 82 "$dest_dir/$out_name"
    [ -n "$cleanup_tmp" ] && rm -f "$cleanup_tmp"
  fi

  success=$((success + 1))
  last_dest="src/assets/$date_folder"
done

if [ "$success" -gt 0 ] || [ "$skip" -gt 0 ]; then
  /usr/bin/osascript -e "display notification \"$success imported, $skip skipped\" with title \"Israel 2026 Import\" subtitle \"→ $last_dest\""
fi
