#!/bin/bash
# Main entry: specify download file
download_file="/userdata/system/game-downloader/download.txt"

# Directory where the download status files are stored
STATUS_DIR="/userdata/system/game-downloader/download.txt"
mkdir -p "$STATUS_DIR"

# Function to display download status with Dialog
check_downloads() {
    if [[ -s "$download_file" ]]; then
        # If download.txt is not empty, downloads are still processing
        dialog --clear --title "Download Status" --infobox "Downloads are still processing." 10 50
        sleep 5
    else
        # If download.txt is empty, all downloads are processed
        dialog --clear --title "Download Status" --infobox "All downloads processed! Update your game list to see your new games! Don't forget to scrape for artwork!" 15 50
        sleep 5
    fi
}



# Start showing download progress
show_download_progress

# Optionally, call GameDownloader.sh after progress is done
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/GameDownloader.sh" | bash
