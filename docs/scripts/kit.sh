#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint

# BeaconKit™'s renders (docs/beaconkit.md › Renders): builds the developer variant, copies it into a renderer bundle
# of its own and has it photograph every specimen variant and catalog surface (Sources/Vorssaint/Kit/) in each
# language and theme.
#
#   docs/scripts/kit.sh                          everything: TR + EN, dark + light
#   docs/scripts/kit.sh --only components        one step (components | surfaces)
#   docs/scripts/kit.sh --specimen SettingsCard  some specimens (repeatable; the others' images stay)
#   docs/scripts/kit.sh --no-build               the last build
#
#   OUT=~/BeaconKit/kit  LANGUAGES=tr,en  THEMES=dark,light  KIT_ALLOW_1X=1 (a 1x screen, to try only)
#   Output: $OUT/export/registry.json, $OUT/render/{components,surfaces}/…png + manifest.json, $OUT/render/rendered.json
#   (each group's commit and time). Log: docs/logs/kit-render.log.
#
# The renderer is the developer build under another bundle id (co.ikili.beaconkit.renderer), so its preferences (the
# language it switches through) and its Screen Recording permission are its own. Launched with `open`, the permission
# is asked of it, not of whatever started the script: grant it once on the Mac that renders, or the materials come out
# flat (the run says so).
set -euo pipefail
cd "$(dirname "$0")/../.."

OUT=${OUT:-$HOME/BeaconKit/kit}
LANGUAGES=${LANGUAGES:-tr,en}
THEMES=${THEMES:-dark,light}
build=1 only="" specimens=()
while (( $# )); do
  case $1 in
    --only) only=$2; shift ;;
    --specimen) specimens+=(--specimen "$2"); shift ;;
    --no-build) build=0 ;;
    -h|--help) sed -n '5,20p' "$0"; exit 0 ;;
    *) print -u2 "Unknown argument: $1"; exit 1 ;;
  esac
  shift
done
# What a run asks for also comes from the workflow's inputs: only the known values.
[[ $only == ("components"|"surfaces"|"") ]] || { print -u2 "Unknown step: $only (components, surfaces)"; exit 1 }
for language in ${(s:,:)LANGUAGES}; [[ $language == (tr|en) ]] || { print -u2 "Unknown language: $language (tr, en)"; exit 1 }
for theme in ${(s:,:)THEMES}; [[ $theme == (dark|light) ]] || { print -u2 "Unknown theme: $theme (dark, light)"; exit 1 }

mkdir -p docs/logs "$OUT"
LOG=$PWD/docs/logs/kit-render.log
: > "$LOG"

if (( build )); then
  echo "▸ Building the developer variant…"
  ./build.sh --dev >> "$LOG" 2>&1 || { tail -30 "$LOG"; exit 1; }
fi
SOURCE="build/stage.noindex/Vorssaint (Developer).app"
[[ -d $SOURCE ]] || { print -u2 "No developer build at $SOURCE: run without --no-build"; exit 1 }

RENDERER="$(dirname "$OUT")/BeaconKit Renderer.app"
echo "▸ Renderer → $RENDERER"
rm -rf "$RENDERER"
ditto "$SOURCE" "$RENDERER"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier co.ikili.beaconkit.renderer" "$RENDERER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName BeaconKit Renderer" "$RENDERER/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName BeaconKit Renderer" "$RENDERER/Contents/Info.plist" 2>/dev/null || true
# The same identity build.sh signed with, so a permission granted once survives every rebuild.
IDENTITY=$(codesign -dvv "$SOURCE" 2>&1 | sed -n 's/^Authority=//p' | head -1)
codesign --force --deep --strip-disallowed-xattrs --sign "${IDENTITY:--}" "$RENDERER" >> "$LOG" 2>&1
EXECUTABLE=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$RENDERER/Contents/Info.plist")

args=(--kit-render "$OUT" --languages "$LANGUAGES" --themes "$THEMES" "${specimens[@]}")
[[ -n $only ]] && args+=(--only "$only")
echo "▸ Rendering ($LANGUAGES · $THEMES)…"
started=$(date +%s)
# `open` makes the renderer its own responsible process (its own Screen Recording permission); -W waits, and its
# output goes to the log. Keep the display awake while it photographs.
caffeinate -d -i -w $$ &
open -n -W --stdout "$LOG" --stderr "$LOG" "$RENDERER" --args "${args[@]}"
grep -E '^(  ✘|kit-render:|!|[0-9]+ component images)' "$LOG" || true

summary=$(grep -E '^[0-9]+ component images' "$LOG" | tail -1)
[[ -n $summary ]] || { print -u2 "The renderer stopped before it finished: $LOG"; exit 1 }
# Each group rendered in full gets its commit and time, for the site's "Bileşen görüntüleri: <date> · <commit>".
if [[ ${#specimens} -eq 0 ]]; then
  python3 -I - "$OUT/render/rendered.json" "$(git rev-parse HEAD)" "$only" <<'PY'
import json, sys, datetime
path, sha, only = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    data = json.load(open(path))
except Exception:
    data = {}
stamp = {"sha": sha, "at": datetime.datetime.now(datetime.timezone.utc).isoformat()}
for group in ("components", "surfaces"):
    if only in ("", group):
        data[group] = stamp
json.dump(data, open(path, "w"), indent=2)
PY
fi
echo "✓ $summary in $(( $(date +%s) - started )) s → $OUT"
grep -q '^  ✘' "$LOG" && exit 1 || exit 0
