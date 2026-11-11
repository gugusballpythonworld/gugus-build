#!/usr/bin/env bash
# Opens every page of the Android app in sample-data mode and saves a screenshot, upright and then sideways.
DEVICE="$1"; APK="$2"
OUT="$GITHUB_WORKSPACE/shots/$DEVICE"; mkdir -p "$OUT"
PKG=com.gugusreptilecare
adb install -r "$APK" > /dev/null
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0
adb shell cmd uimode night no || true
snap() { adb exec-out screencap -p > "$OUT/$1.png"; }

# Signed out: the sign-in screen.
adb shell am start -S -n $PKG/.MainActivity > /dev/null; sleep 10; snap "portrait-signin"

# Warm-up run.
adb shell am start -S -n $PKG/.MainActivity --ez demo true > /dev/null; sleep 12

SPECS="0: 1: 2: 3: 4: 2:feeding 2:growth 2:climate 2:food 2:morph 2:card 2:photos 2:plans 2:wrapped 2:groups 2:share 2:suggest 2:settings 2:account 2:region 2:trash 2:learn 2:profile 2:vet 2:vets 2:admin 2:people 2:activity"
for orient in portrait landscape; do
  if [ "$orient" = landscape ]; then adb shell settings put system user_rotation 1; else adb shell settings put system user_rotation 0; fi
  sleep 2
  for spec in $SPECS; do
    tab="${spec%%:*}"; open="${spec#*:}"
    if [ -n "$open" ]; then
      adb shell am start -S -n $PKG/.MainActivity --ez demo true --ei tab "$tab" --es open "$open" > /dev/null
    else
      adb shell am start -S -n $PKG/.MainActivity --ez demo true --ei tab "$tab" > /dev/null
    fi
    sleep 7
    snap "$orient-tab$tab-${open:-main}"
  done
done
adb shell settings put system user_rotation 0
ls "$OUT" | wc -l
