#!/bin/bash

# Main entry: specify download file
download_file="/userdata/system/game-downloader/processing.txt"

# Correct directory where the download status files are stored
STATUS_DIR="/userdata/system/game-downloader"
mkdir -p "$STATUS_DIR"

# Function to display download status with Dialog
check_downloads() {
    if [[ -s "$download_file" ]]; then
        # If processing.txt is not empty, display all games currently downloading
        game_names=$(cut -d '|' -f 1 "$download_file" | grep -Eo '\w+\.(chd|iso|zip)' | sort -u | tr '\n' '\n')
        dialog --msgbox "Still downloading:\n$game_names" 10 50
    else 
        # If processing.txt is empty, all downloads are processed
        dialog --msgbox "Nothing downloading! Update your game list to see your new games! Don't forget to scrape for artwork!" 10 50
    fi
}

# Start showing download progress
check_downloads

# Optionally, call GameDownloader.sh after progress is done
exec /tmp/GameDownloader.sh
