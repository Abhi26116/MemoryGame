#!/bin/bash
# Build a Memory Match Instagram reel from the v1.1 App Store preview footage.
#
#   bash Marketing/reels/_build/make_reel.sh 12    -> memory_match_reel_12s.mp4 (12.0s)
#   bash Marketing/reels/_build/make_reel.sh v1    -> memory_match_reel_v1.mp4  (21.9s)
#   bash Marketing/reels/_build/make_reel.sh all
#
# Pipeline: style2.py (palette, sticker type, plate, background) -> anim.py
# (frame-by-frame overlay: pop-ins, countdown ring, confetti, flash) ->
# reel2.py (sprites + per-cut timeline) -> build2.sh (gameplay plate track) ->
# final2.sh (composite + encode). Edit the timeline in reel2.py to change beats.
set -e
B="$(cd "$(dirname "$0")" && pwd)"
cd /Users/mac/MemoryGame
SRC=AppStoreScreenshots_v1.1/preview/MemoryMatch_preview_iPhone_886x1920.mp4

one() {
  CUT=$1
  echo "== building $CUT"
  # still used for the "all cards face down" quiz beat (src 6.15s)
  ffmpeg -nostdin -v error -ss 6.15 -i "$SRC" -frames:v 1 -vf "crop=820:929:32:808" "$B/freeze2.png" -y
  python3 - <<PY
import sys, os; sys.path.insert(0, "$B")
import style2 as st
st.rounded_mask(st.PW, st.PH, st.RAD).save("$B/plate_mask2.png")
st.plate_frame_png().save("$B/plate_frame2.png")
PY
  bash "$B/build2.sh" "$CUT"
  python3 "$B/reel2.py" bg "$CUT"
  python3 "$B/reel2.py" ov "$CUT"
  bash "$B/final2.sh" "$CUT"
  rm -rf "$B/bgf$CUT" "$B/ovf$CUT" "$B/p$CUT" "$B/bg$CUT.mp4" "$B/plate$CUT.mp4"
}

case "${1:-all}" in
  12) one 12 ;;
  v1) one v1 ;;
  all) one 12; one v1 ;;
  *) echo "usage: make_reel.sh [12|v1|all]"; exit 1 ;;
esac
# cover frame for the Instagram cover picker
ffmpeg -nostdin -v error -ss 1.1 -i Marketing/reels/memory_match_reel_12s.mp4 \
  -frames:v 1 -q:v 2 Marketing/reels/reel_cover.jpg -y 2>/dev/null || true
echo "Done -> Marketing/reels/"
