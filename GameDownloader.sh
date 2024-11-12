#!/bin/bash

# Ensure clear display
clear

# Suppress standard output and error messages
exec > /dev/null 2>&1

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

# Download the PSX and Dreamcast downloader menu scripts from GitHub
curl -L "$PSX_MENU_URL" -o "$PSX_MENU" &> /dev/null
curl -L "$DC_MENU_URL" -o "$DC_MENU" &> /dev/null

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
