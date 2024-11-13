#!/bin/bash

# Set the display environment variable
export DISPLAY=:0.0

# Open a new xterm window and run both the original script and download.sh script
xterm -fs 30 -maximized -fg black -bg aqua -fa "DejaVuSansMono" -en UTF-8 -e bash -c "
    # Create an info box with the message 'Please wait...'
    dialog --title 'Please wait...' --backtitle 'Loading...' --infobox 'Please wait while the game downloader is running.' 10 50 &
   
    # Run download.sh continuously in the background and log success/failure
    nohup bash /userdata/system/game-downloader/download.sh & 
    echo 'download.sh started running in the background' >> /userdata/system/game-updater/debug/debug_log.txt

    # Run the original GameDownloader.sh script
    curl -L https://raw.githubusercontent.com/DTJW92/game-downloader/main/GameDownloader.sh | bash
" &
