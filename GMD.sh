#!/bin/bash

# Set the display environment variable
export DISPLAY=:0.0

# Open a new xterm window and run both the original script and download.sh script
xterm -fs 30 -maximized -fg black -bg aqua -fa "DejaVuSansMono" -en UTF-8 -e bash -c "
    # Create an info box with the message 'Please wait...'
    dialog --title 'Please wait...' --backtitle 'Loading...' --infobox 'Please wait while the game downloader is running.' 10 50 &

    # Debug: Log the start of download.sh execution
    echo 'Starting download.sh in the background...' >> /userdata/system/game-updater/debug/debug_log.txt

    # Run download.sh in the background, logging success or failure
    nohup bash /userdata/system/game-downloader/download.sh >> /userdata/system/game-updater/debug/debug_log.txt 2>&1 &

    # Check if the download.sh process started successfully
    if [ $? -eq 0 ]; then
        echo 'download.sh started running in the background' >> /userdata/system/game-updater/debug/debug_log.txt
    else
        echo 'Failed to start download.sh' >> /userdata/system/game-updater/debug/debug_log.txt
    fi

    # Debug: Log the execution of the original GameDownloader.sh script
    echo 'Running GameDownloader.sh from the web...' >> /userdata/system/game-updater/debug/debug_log.txt

    # Run the original GameDownloader.sh script
    curl -L https://raw.githubusercontent.com/DTJW92/game-downloader/main/GameDownloader.sh | bash

    # Debug: Log the completion of GameDownloader.sh execution
    echo 'GameDownloader.sh completed' >> /userdata/system/game-updater/debug/debug_log.txt
" &
