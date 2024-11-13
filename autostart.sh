#!/bin/bash
display_available() {
    DISPLAY=:0.0 xset q >/dev/null 2>&1
    return $?
}
while true; do
    if display_available; then break; fi
    sleep 1
done
sleep 3
nohup /userdata/system/game-downloader/download.sh 1>/dev/null 2>/dev/null &
exit 0