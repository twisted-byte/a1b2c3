#!/bin/bash

# Set the display environment variable for GUI-based applications
export DISPLAY=:0.0

# Main entry: specify download file
download_file="/userdata/system/game-downloader/download.txt"

# Correct directory where the download status files are stored
STATUS_DIR="/userdata/system/game-downloader/status"
mkdir -p "$STATUS_DIR"

# Function to display download status with Dialog
check_downloads() {
    if [[ -s "$download_file" ]]; then
        # If download.txt is not empty, downloads are still processing
        dialog --infobox "Downloads are still processing." 10 50
        sleep 5
    else
        # If download.txt is empty, all downloads are processed
        dialog --infobox "All downloads processed! Update your game list to see your new games! Don't forget to scrape for artwork!" 15 50
        sleep 5
    fi
}

# Start showing download progress
check_downloads
sleep 3

# Optionally, call GameDownloader.sh after progress is done
bash /tmp/GameDownloader.sh
