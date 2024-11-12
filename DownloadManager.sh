#!/bin/bash

# Directory where the download status files are stored
STATUS_DIR="/userdata/system/game-downloader/status"
mkdir -p "$STATUS_DIR"

# Function to display download status with Dialog
show_download_progress() {
    while true; do
        clear
        progress_text="Downloading:\n"
        any_progress=false
        # Check the status of all downloads
        for status_file in "$STATUS_DIR"/*.status; do
            if [[ -f "$status_file" ]]; then
                file_name=$(basename "$status_file" .status)
                progress=$(<"$status_file")
                decoded_name=$(grep -F "$file_name" "$download_file" | cut -d '|' -f 1)  # Get the decoded name
                progress_text="$progress_text$decoded_name: $progress%\n"
                any_progress=true
            fi
        done

        # If there's ongoing downloads, show progress
        if $any_progress; then
            dialog --clear --title "Download Progress" --msgbox "$progress_text" 15 50
        else
            # Show a message when no downloads are active
            dialog --clear --title "Download Progress" --msgbox "Nothing downloading currently!" 10 50
            break
        fi

        # Exit when the dialog is closed
        if [[ $? -eq 0 ]]; then
            break
        fi
        
        sleep 2  # Refresh every 2 seconds
    done
}

# Main entry: specify download file
download_file="/userdata/system/game-downloader/download.txt"

# Start showing download progress
show_download_progress

# Optionally, call GameDownloader.sh after progress is done
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/GameDownloader.sh" | bash
