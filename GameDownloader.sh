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
PS2_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/ps2-downloader-menu.sh"
DC_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-downloader-menu.sh"
UPDATER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Updater.sh"
DOWNLOAD_MANAGER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/DownloadManager.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/uninstall.sh"

# Define local file paths
PSX_MENU="/userdata/system/game-downloader/psx-downloader-menu.sh"
PS2_MENU="/userdata/system/game-downloader/ps2-downloader-menu.sh"
DC_MENU="/userdata/system/game-downloader/dc-downloader-menu.sh"
UPDATER="/userdata/system/game-downloader/Updater.sh"
DOWNLOAD_MANAGER="/userdata/system/game-downloader/DownloadManager.sh"
UNINSTALL_SCRIPT="/userdata/system/game-downloader/uninstall.sh"

# Function to download and update a script if needed, with a simple infobox
download_if_needed() {
    local remote_url="$1"
    local local_file="$2"
    
    # Show a simple loading infobox
    dialog --infobox "Downloading and updating scripts. Please wait..." 5 50
    sleep 2  # Allow time for the infobox to display

    # Get the remote file's timestamp
    remote_timestamp=$(curl -sI "$remote_url" | grep -i '^Last-Modified:' | sed 's/Last-Modified: //')
    
    # Check if the remote timestamp is newer than the local file's timestamp
    if [[ -f "$local_file" ]]; then
        local_timestamp=$(stat -c %y "$local_file" | sed 's/\([0-9]*-[0-9]*-[0-9]*\).*/\1/')
        if [[ "$remote_timestamp" == "$local_timestamp" ]]; then
            return 0  # No need to download, local is up to date
        fi
    fi

    # Download the latest version if the file is outdated or missing
    wget -q -O "$local_file" "$remote_url"
}

# Show infobox and background the download tasks
dialog --infobox "Checking for script updates..." 5 50
download_if_needed "$PSX_MENU_URL" "$PSX_MENU" &
download_if_needed "$PS2_MENU_URL" "$PS2_MENU" &
download_if_needed "$DC_MENU_URL" "$DC_MENU" &
download_if_needed "$UPDATER_URL" "$UPDATER" &
download_if_needed "$DOWNLOAD_MANAGER_URL" "$DOWNLOAD_MANAGER" &
download_if_needed "$UNINSTALL_URL" "$UNINSTALL_SCRIPT" &

# Wait for all background downloads to complete
wait

# Ensure the scripts have the correct permissions
chmod +x "$PSX_MENU" &> /dev/null
chmod +x "$PS2_MENU" &> /dev/null
chmod +x "$DC_MENU" &> /dev/null
chmod +x "$UPDATER" &> /dev/null
chmod +x "$DOWNLOAD_MANAGER" &> /dev/null
chmod +x "$UNINSTALL_SCRIPT" &> /dev/null

# Main dialog menu
dialog --clear --backtitle "Game Downloader" \
       --title "Select a System" \
       --menu "Choose an option:" 15 50 8 \
       1 "PSX Downloader" \
       2 "PS2 Downloader" \
       3 "Dreamcast Downloader" \
       4 "Run Updater" \
       5 "Run Download Manager" \
       6 "Uninstall Game Downloader" 2>/tmp/game-downloader-choice

# Read user choice
choice=$(< /tmp/game-downloader-choice)
rm /tmp/game-downloader-choice

# Act based on choice
case $choice in
    1)
        "$PSX_MENU"
        ;;
    2)
        "$PS2_MENU"
        ;;
    3)
        "$DC_MENU"
        ;;
    4)
        "$UPDATER"
        ;;
    5)
        "$DOWNLOAD_MANAGER"
        ;;
    6)
        # Run the uninstall script
        "$UNINSTALL_SCRIPT"
        ;;
    *)
        dialog --infobox "Exiting..." 10 50
        sleep 2
        ;;
esac

# Clear screen on exit
clear

# Run the curl command to reload the games (output suppressed)
curl http://127.0.0.1:1234/reloadgames &> /dev/null
