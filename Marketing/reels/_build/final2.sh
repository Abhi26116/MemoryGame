set -e
B=/Users/mac/MemoryGame/Marketing/reels/_build
CUT=$1
if [ "$CUT" = "12" ]; then DUR=12.00; PEND=9.80; OUT=/Users/mac/MemoryGame/Marketing/reels/memory_match_reel_12s.mp4
else DUR=21.90; PEND=18.30; OUT=/Users/mac/MemoryGame/Marketing/reels/memory_match_reel_v1.mp4; fi
ffmpeg -nostdin -v error \
 -i $B/bg$CUT.mp4 \
 -i $B/plate$CUT.mp4 \
 -i $B/plate_mask2.png \
 -i $B/plate_frame2.png \
 -framerate 30 -i $B/ovf$CUT/f%04d.png \
 -f lavfi -t $DUR -i anullsrc=channel_layout=stereo:sample_rate=44100 \
 -filter_complex "\
[1:v]format=rgba[p];[p][2:v]alphamerge[pm];\
[0:v][pm]overlay=90:468:enable='between(t,0,$PEND)'[s1];\
[s1][3:v]overlay=0:0:enable='between(t,0,$PEND)'[s2];\
[s2][4:v]overlay=0:0,format=yuv420p[v]" \
 -map "[v]" -map 5:a \
 -c:v libx264 -preset slow -crf 18 -profile:v high -level 4.0 -pix_fmt yuv420p -r 30 -g 60 \
 -c:a aac -b:a 128k -ar 44100 -ac 2 -movflags +faststart -t $DUR "$OUT" -y
ls -lh "$OUT"; ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT"
