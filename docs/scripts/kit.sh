#!/bin/zsh
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Vorssaint

# BeaconKit™'s renders (docs/beaconkit.md › Renders): builds the developer variant, copies it into a renderer bundle
# of its own and has it photograph every specimen variant and catalog surface (Sources/Vorssaint/Kit/) in each
# language and theme.
#
#   docs/scripts/kit.sh                          everything: TR + EN, dark + light
#   docs/scripts/kit.sh --only components        one step (components | surfaces | ios)
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
[[ $only == ("components"|"surfaces"|"ios"|"") ]] || { print -u2 "Unknown step: $only (components, surfaces, ios)"; exit 1 }
for language in ${(s:,:)LANGUAGES}; [[ $language == (tr|en) ]] || { print -u2 "Unknown language: $language (tr, en)"; exit 1 }
for theme in ${(s:,:)THEMES}; [[ $theme == (dark|light) ]] || { print -u2 "Unknown theme: $theme (dark, light)"; exit 1 }

mkdir -p docs/logs "$OUT"
LOG=$PWD/docs/logs/kit-render.log
: > "$LOG"

if [[ $only != ios ]]; then
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
grep -q '^  ✘' "$LOG" && mac_failed=1
fi

# MARK: iOS (Beacon): its specimens drawn by the app itself (`-kitExport 1`, ImageRenderer @3x, both themes) once per
# language, and its screens photographed on the simulator with the demo Mac (`-demo 1 -screen …`), both themes.
#   $OUT/export/ios-registry.json, ios-tokens.json
#   $OUT/render/ios/components/<lang>/<theme>/<id>/<variant>.png + manifest.json
#   $OUT/render/ios/screens/<lang>/<theme>/<screen>.png + manifest.json
if [[ -z $only || $only == ios ]] && (( ${#specimens} == 0 )); then
  if ! command -v xcodegen >/dev/null || ! xcrun --sdk iphonesimulator --show-sdk-path >/dev/null 2>&1; then
    echo "! iOS skipped: needs XcodeGen (brew install xcodegen) and Xcode's iOS SDK"
  else
    echo "▸ iOS: building Beacon for the simulator…"
    IOS_LOG=$PWD/docs/logs/kit-ios.log
    : > "$IOS_LOG"
    SIM_NAME="BeaconKit"
    SIM=$(xcrun simctl list devices available -j | python3 -I -c "import json,sys; d=json.load(sys.stdin)['devices']; print(next((x['udid'] for r in d.values() for x in r if x['name']=='$SIM_NAME'), ''))")
    if [[ -z $SIM ]]; then
      RUNTIME=$(xcrun simctl list runtimes -j | python3 -I -c "import json,sys; r=[x['identifier'] for x in json.load(sys.stdin)['runtimes'] if x['platform']=='iOS' and x['isAvailable']]; print(sorted(r)[-1] if r else '')")
      SIM=$(xcrun simctl create "$SIM_NAME" com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro "$RUNTIME")
    fi
    (cd iOS && xcodegen generate --quiet && xcodebuild -project Beacon.xcodeproj -scheme Beacon -destination "platform=iOS Simulator,id=$SIM" \
      -derivedDataPath "$(dirname "$OUT")/ios-dd" build CODE_SIGN_IDENTITY=-) >> "$IOS_LOG" 2>&1 || { tail -20 "$IOS_LOG"; exit 1 }
    APP=$(dirname "$OUT")/ios-dd/Build/Products/Debug-iphonesimulator/Beacon.app
    xcrun simctl boot "$SIM" 2>/dev/null || true
    xcrun simctl bootstatus "$SIM" -b >> "$IOS_LOG" 2>&1
    xcrun simctl status_bar "$SIM" override --time "9:41" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4 2>/dev/null || true
    xcrun simctl uninstall "$SIM" co.ikili.beacon 2>/dev/null || true
    xcrun simctl install "$SIM" "$APP"
    rm -rf "$OUT/render/ios"
    mkdir -p "$OUT/render/ios" "$OUT/export"
    screens=(macs dashboard cpu memory network power disk temperature)
    for language in ${(s:,:)LANGUAGES}; do
      locale=$([[ $language == tr ]] && echo tr_TR || echo en_US)
      echo "▸ iOS ($language): specimens…"
      xcrun simctl launch --console-pty "$SIM" co.ikili.beacon -demo 1 -kitExport 1 -AppleLanguages "($language)" -AppleLocale "$locale" >> "$IOS_LOG" 2>&1 || true
      CONTAINER=$(xcrun simctl get_app_container "$SIM" co.ikili.beacon data)
      [[ -f $CONTAINER/Documents/kit/registry.json ]] || { print -u2 "The iOS export wrote nothing: $IOS_LOG"; exit 1 }
      mkdir -p "$OUT/render/ios/components/$language"
      ditto "$CONTAINER/Documents/kit/components" "$OUT/render/ios/components/$language"
      cp "$CONTAINER/Documents/kit/registry.json" "$OUT/export/ios-registry.json"
      cp "$CONTAINER/Documents/kit/tokens.json" "$OUT/export/ios-tokens.json"
      echo "▸ iOS ($language): screens…"
      for theme in dark light; do
        xcrun simctl ui "$SIM" appearance "$theme"
        for screen in $screens; do
          xcrun simctl terminate "$SIM" co.ikili.beacon 2>/dev/null || true
          args=(-demo 1 -AppleLanguages "($language)" -AppleLocale "$locale")
          [[ $screen != macs ]] && args+=(-screen "$screen")
          xcrun simctl launch "$SIM" co.ikili.beacon "${args[@]}" >> "$IOS_LOG" 2>&1
          sleep 4
          mkdir -p "$OUT/render/ios/screens/$language/$theme"
          xcrun simctl io "$SIM" screenshot "$OUT/render/ios/screens/$language/$theme/$screen.png" >> "$IOS_LOG" 2>&1
        done
      done
      xcrun simctl terminate "$SIM" co.ikili.beacon 2>/dev/null || true
    done
    # One manifest per group, keyed <lang>/<theme>/…, sizes in points (the export's own; the screens' @3x pixels / 3).
    python3 -I - "$OUT/render/ios" <<'PY'
import json, os, struct, sys
root = sys.argv[1]
components = {}
for language in sorted(os.listdir(os.path.join(root, "components"))):
    path = os.path.join(root, "components", language, "manifest.json")
    if os.path.exists(path):
        for key, size in json.load(open(path)).items():
            components[f"{language}/{key}"] = size
        os.remove(path)
json.dump(components, open(os.path.join(root, "components", "manifest.json"), "w"), indent=2, sort_keys=True)
screens = {}
for language in sorted(os.listdir(os.path.join(root, "screens"))):
    for theme in sorted(os.listdir(os.path.join(root, "screens", language))):
        for name in sorted(os.listdir(os.path.join(root, "screens", language, theme))):
            with open(os.path.join(root, "screens", language, theme, name), "rb") as png:
                width, height = struct.unpack(">II", png.read(24)[16:24])
            screens[f"{language}/{theme}/{name[:-4]}"] = {"width": width / 3, "height": height / 3}
json.dump(screens, open(os.path.join(root, "screens", "manifest.json"), "w"), indent=2, sort_keys=True)
print(f"  {len(components)} iOS component images, {len(screens)} iOS screens")
PY
    xcrun simctl shutdown "$SIM" 2>/dev/null || true
    python3 -I - "$OUT/render/rendered.json" "$(git rev-parse HEAD)" <<'PY'
import json, sys, datetime
path, sha = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(path))
except Exception:
    data = {}
data["ios"] = {"sha": sha, "at": datetime.datetime.now(datetime.timezone.utc).isoformat()}
json.dump(data, open(path, "w"), indent=2)
PY
  fi
fi
(( ${mac_failed:-0} )) && exit 1 || exit 0
