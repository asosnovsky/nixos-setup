#!/bin/sh
set -e

_SCREEN_RECORD_DIR="$HOME/Videos/ScreenRecordings"
mkdir -p "$_SCREEN_RECORD_DIR"


if pgrep -x "wf-recorder" > /dev/null; then
    last_cmd=$(pgrep -x "wf-recorder" -a)
    filepath="${last_cmd##* -f }"
    filepath="${filepath%% *}"
    pgrep -x "wf-recorder" && pkill -INT -x wf-recorder
    notify-send -h string:wf-recorder:record -t 5000 "Finished Recording. Saved at $filepath."
    echo $filepath | xclip -selection clipboard
    exit 0
fi

dims=$(slurp)
notify-send -h string:wf-recorder:record -t 1000 "Recording in:" "<span color='#90a4f4' font='26px'><i><b>3</b></i></span>"

sleep 1

notify-send -h string:wf-recorder:record -t 1000 "Recording in:" "<span color='#90a4f4' font='26px'><i><b>2</b></i></span>"

sleep 1

notify-send -h string:wf-recorder:record -t 950 "Recording in:" "<span color='#90a4f4' font='26px'><i><b>1</b></i></span>"

sleep 1

dateTime=$(date +%Y-%m-%d-%H_%M_%S)
wf-recorder --bframes max_b_frames -g "${dims}" -f $_SCREEN_RECORD_DIR/$dateTime.mp4