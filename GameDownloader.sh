#!/bin/bash

# Ensure clear display
clear

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
    dialog --msgbox "Error: dialog is not installed. Please install it and try again." 10 50
    exit 1
fi

# URLs for external scripts
PSX_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-downloader-menu.sh"
PS2_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/ps2-downloader-menu.sh"
DC_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-downloader-menu.sh"
UPDATER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Updater.sh"
DOWNLOAD_MANAGER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/DownloadManager.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/uninstall.sh"

# Main dialog menu with loop to keep the menu active until a valid choice is selected
while true; do
    dialog --clear --backtitle "Game Downloader" \
           --title "Select a System" \
           --menu "Choose an option:" 15 50 8 \
           1 "PSX Downloader" \
           2 "PS2 Downloader" \
           3 "Dreamcast Downloader" \
           4 "Run Updater" \
           5 "Run Download Manager" \
           6 "Uninstall Game Downloader" 2>/tmp/game-downloader-choice

    choice=$(< /tmp/game-downloader-choice)
    rm /tmp/game-downloader-choice

    # Check if user canceled the dialog
    if [ $? -ne 0 ]; then
        clear
        exit 0  # Exit the script when Cancel is clicked
    fi

    case $choice in
        1)
            bash <(curl -s "$PSX_MENU_URL")
            ;;
        2)
            bash <(curl -s "$PS2_MENU_URL")
            ;;
        3)
            bash <(curl -s "$DC_MENU_URL")
            ;;
        4)
            bash <(curl -s "$UPDATER_URL")
            ;;
        5)
            bash <(curl -s "$DOWNLOAD_MANAGER_URL")
            ;;
        6)
            bash <(curl -s "$UNINSTALL_URL")
            ;;
    esac
done

# Clear screen on exit
clear
