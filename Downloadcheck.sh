#!/bin/bash

# File containing the list of downloads
download_file="/userdata/system/game-downloader/download.txt"

# Ensure the download.txt file exists; if not, create it as an empty file
if [[ ! -f "$download_file" ]]; then
    touch "$download_file"
fi

# Function to check if there are any ongoing downloads
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

# Call the function to check and display the status
check_downloads
