#!/bin/bash

# Set the display environment variable
export DISPLAY=:0.0

# Run the script silently in the background with an info box dialog
(
    # Create an info box with the message "Please wait..."
    dialog --title "Please wait..." --backtitle "Loading..." --infobox "Please wait while the game downloader is running." 10 50 &
    
    # Run the download and script execution silently, redirecting output to /dev/null
    curl -L https://raw.githubusercontent.com/DTJW92/game-downloader/main/GameDownloader.sh | bash > /dev/null 2>&1
) &

# Wait a little to ensure dialog shows up first
sleep 1
