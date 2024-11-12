#!/bin/bash

# Ensure clear display
clear

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
    dialog --msgbox "Error: dialog is not installed. Please install it and try again." 10 50
    exit 1
fi

# Define the URLs to fetch the menu scripts from GitHub
PSX_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-downloader-menu.sh"
DC_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-downloader-menu.sh"

# Define local file paths
PSX_MENU="/userdata/system/game-downloader/psx-downloader-menu.sh"
DC_MENU="/userdata/system/game-downloader/dc-downloader-menu.sh"

# Function to download and update a script if needed
download_if_needed() {
    local remote_url="$1"
    local local_file="$2"
    
    # Get the remote file's timestamp
    remote_timestamp=$(curl -sI "$remote_url" | grep -i '^Last-Modified:' | sed 's/Last-Modified: //')
    
    # Check if the remote timestamp is newer than the local file's timestamp
    if [[ -f "$local_file" ]]; then
        local_timestamp=$(stat -c %y "$local_file" | sed 's/\([0-9]*-[0-9]*-[0-9]*\).*/\1/')
        if [[ "$remote_timestamp" == "$local_timestamp" ]]; then
            return 0  # No need to download, local is up to date
        fi
    fi

    # If not up-to-date or file doesn't exist, download the latest version
    curl -L "$remote_url" -o "$local_file"
}

# Download and update the PSX and Dreamcast menu scripts if necessary
dialog --infobox "Checking for script updates..." 5 50
download_if_needed "$PSX_MENU_URL" "$PSX_MENU"
download_if_needed "$DC_MENU_URL" "$DC_MENU"

# Ensure the scripts have the correct permissions
chmod +x "$PSX_MENU" &> /dev/null
chmod +x "$DC_MENU" &> /dev/null

# Main dialog menu
dialog --clear --backtitle "Game Downloader" \
       --title "Select a System" \
       --menu "Choose an option:" 15 50 4 \
       1 "PSX Downloader" \
       2 "Dreamcast Downloader" 2>/tmp/game-downloader-choice

# Read user choice
choice=$(< /tmp/game-downloader-choice)
rm /tmp/game-downloader-choice

# Act based on choice
case $choice in
    1)
        "$PSX_MENU"
        ;;
    2)
        "$DC_MENU"
        ;;
    *)
        dialog --msgbox "No valid option selected." 10 50
        ;;
esac

# Clear screen on exit
clear

# Run the curl command to reload the games (output suppressed)
curl http://127.0.0.1:1234/reloadgames &> /dev/null
