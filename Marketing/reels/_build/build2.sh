set -e
cd /Users/mac/MemoryGame
B=/Users/mac/MemoryGame/Marketing/reels/_build
SRC=AppStoreScreenshots_v1.1/preview/MemoryMatch_preview_iPhone_886x1920.mp4
CUT=$1
ENC="-c:v libx264 -preset slow -crf 16 -pix_fmt yuv420p -r 30"
G="crop=820:929:32:808"
WIN="crop=886:1004:0:270"
SEG=$B/p$CUT; mkdir -p $SEG

if [ "$CUT" = "12" ]; then AD=3.60; AF=107; CD=1.40; CF=41; DIN=15.60; DT=3.51; DOUT=2.70; ED=1.40; AIN=1.95
else AD=4.40; AF=131; CD=1.20; CF=35; DIN=7.30; DT=11.60; DOUT=8.00; ED=1.00; AIN=1.15; fi

# A memorize (push-in)
ffmpeg -nostdin -v error -ss $AIN -t $AD -i $SRC -filter_complex \
 "[0:v]$G,scale=1640:1858,zoompan=z='min(1.07,1+0.07*on/$AF)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=900x1020:fps=30,setsar=1[v]" \
 -map "[v]" -t $AD $ENC $SEG/a.mp4 -y
# B flip
ffmpeg -nostdin -v error -ss 5.55 -t 0.70 -i $SRC -filter_complex "[0:v]$G,scale=900:1020,setsar=1[v]" \
 -map "[v]" -t 0.70 $ENC $SEG/b.mp4 -y
# C quiz freeze (push-in)
ffmpeg -nostdin -v error -loop 1 -framerate 30 -t $CD -i $B/freeze2.png -filter_complex \
 "[0:v]scale=1640:1858,zoompan=z='min(1.05,1+0.05*on/$CF)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=900x1020:fps=30,setsar=1[v]" \
 -map "[v]" -t $CD $ENC $SEG/c.mp4 -y
# D gameplay
if [ "$CUT" = "12" ]; then SP=1.3; else SP=1.45; fi
ffmpeg -nostdin -v error -ss $DIN -t $DT -i $SRC -filter_complex \
 "[0:v]$G,setpts=PTS/$SP,scale=900:1020,setsar=1[v]" -map "[v]" -t $DOUT $ENC $SEG/d.mp4 -y
# E reveal/win
if [ "$CUT" = "12" ]; then
  ffmpeg -nostdin -v error -ss 20.40 -t 1.40 -i $SRC -filter_complex "[0:v]$WIN,scale=900:1020,setsar=1[v]" -map "[v]" -t 1.40 $ENC $SEG/e.mp4 -y
  printf "file '%s'\n" $SEG/a.mp4 $SEG/b.mp4 $SEG/c.mp4 $SEG/d.mp4 $SEG/e.mp4 > $SEG/l.txt
else
  ffmpeg -nostdin -v error -ss 18.90 -t 1.00 -i $SRC -filter_complex "[0:v]$G,scale=900:1020,setsar=1[v]" -map "[v]" -t 1.00 $ENC $SEG/e.mp4 -y
  ffmpeg -nostdin -v error -ss 20.20 -t 3.00 -i $SRC -filter_complex "[0:v]$WIN,scale=900:1020,setsar=1[v]" -map "[v]" -t 3.00 $ENC $SEG/f.mp4 -y
  printf "file '%s'\n" $SEG/a.mp4 $SEG/b.mp4 $SEG/c.mp4 $SEG/d.mp4 $SEG/e.mp4 $SEG/f.mp4 > $SEG/l.txt
fi
ffmpeg -nostdin -v error -f concat -safe 0 -i $SEG/l.txt -c copy $B/plate$CUT.mp4 -y
echo -n "plate$CUT "; ffprobe -v error -show_entries format=duration -of csv=p=0 $B/plate$CUT.mp4
