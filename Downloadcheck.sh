#!/bin/bash

# Define the log file for debugging
LOG_FILE="/userdata/system/game-downloader/debug_log.txt"

# Function to log messages to the log file
log_debug() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Main entry: specify download file
download_file="/userdata/system/game-downloader/download.txt"

# Directory where the download status files are stored
STATUS_DIR="/userdata/system/game-downloader/download.txt"
mkdir -p "$STATUS_DIR"

# Log the download file and status directory setup
log_debug "Download file: $download_file"
log_debug "Status directory: $STATUS_DIR"
log_debug "Creating status directory if it doesn't exist: $STATUS_DIR"

# Function to display download status with Dialog
check_downloads() {
    log_debug "Checking if the download file exists and has content..."

    if [[ -s "$download_file" ]]; then
        log_debug "Download file is not empty, indicating downloads are still processing."
        # If download.txt is not empty, downloads are still processing
        dialog --clear --title "Download Status" --infobox "Downloads are still processing." 10 50
        log_debug "Dialog message displayed: 'Downloads are still processing.'"
        sleep 5
    else
        log_debug "Download file is empty, indicating all downloads are processed."
        # If download.txt is empty, all downloads are processed
        dialog --clear --title "Download Status" --infobox "All downloads processed! Update your game list to see your new games! Don't forget to scrape for artwork!" 15 50
        log_debug "Dialog message displayed: 'All downloads processed!'"
        sleep 5
    fi
}

# Start showing download progress
log_debug "Starting to show download progress..."
check_downloads

# Optionally, call GameDownloader.sh after progress is done
log_debug "Downloading and executing GameDownloader.sh..."
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/GameDownloader.sh" | bash
log_debug "GameDownloader.sh executed."
