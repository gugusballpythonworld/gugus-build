#!/usr/bin/env bash
# Opens every page of the Android app in sample-data mode and saves a screenshot, upright and then sideways.
DEVICE="$1"; APK="$2"
OUT="$GITHUB_WORKSPACE/shots/$DEVICE"; mkdir -p "$OUT"
PKG=com.gugusreptilecare
adb install -r -g "$APK" > /dev/null
# Answer the permission questions up front, so a system box never covers the next screenshots.
for perm in ACCESS_COARSE_LOCATION ACCESS_FINE_LOCATION POST_NOTIFICATIONS CAMERA READ_MEDIA_IMAGES; do adb shell pm grant $PKG android.permission.$perm 2>/dev/null || true; done
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0
adb shell cmd uimode night no || true
# Named by the real shape of the picture: a tablet's natural direction can be sideways.
snap() { adb exec-out screencap -p > "$OUT/tmp.png"; python3 -c "import struct,sys;d=open(sys.argv[1],'rb').read(24);w,h=struct.unpack('>II',d[16:24]);print('landscape' if w>h else 'portrait')" "$OUT/tmp.png" > "$OUT/shape"; mv "$OUT/tmp.png" "$OUT/$(cat "$OUT/shape")-${1#*-}.png"; rm -f "$OUT/shape"; }

# Signed out: the sign-in screen.
adb shell am start -S -n $PKG/.MainActivity > /dev/null; sleep 10; snap "portrait-signin"

# Warm-up run.
adb shell am start -S -n $PKG/.MainActivity --ez demo true > /dev/null; sleep 12

SPECS="0: 1: 2: 3: 4: 2:feeding 2:growth 2:climate 2:food 2:morph 2:card 2:photos 2:plans 2:wrapped 2:groups 2:share 2:suggest 2:settings 2:account 2:region 2:trash 2:learn 2:profile 2:vet 2:admin 2:people 2:activity 2:vets"
for orient in portrait landscape; do
  if [ "$orient" = landscape ]; then R=1; else R=0; fi
  adb shell settings put system user_rotation $R
  adb shell cmd window user-rotation lock $R || true
  # The phone emulator ignores rotation, so give it a sideways screen size instead (same layout the app gets when turned).
  if [ "$DEVICE" = phone ]; then if [ $R = 1 ]; then adb shell wm size 2400x1080; else adb shell wm size reset; fi; fi
  sleep 3
  for spec in $SPECS; do
    tab="${spec%%:*}"; open="${spec#*:}"
    if [ -n "$open" ]; then
      adb shell am start -S -n $PKG/.MainActivity --ez demo true --ei tab "$tab" --es open "$open" > /dev/null
    else
      adb shell am start -S -n $PKG/.MainActivity --ez demo true --ei tab "$tab" > /dev/null
    fi
    sleep 12
    snap "$orient-tab$tab-${open:-main}"
  done
done
adb shell settings put system user_rotation 0
adb shell wm size reset || true
adb logcat -b crash -d > "$OUT/crash.log" 2>&1 || true
ls "$OUT" | wc -l
