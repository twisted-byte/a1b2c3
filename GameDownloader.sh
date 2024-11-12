#!/bin/bash

# Debugging: log the start of the script
echo "DEBUG: Starting main menu script" >> /userdata/system/game-downloader/debug.log

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

# Check if the choice was valid
if [[ ! -s /tmp/game-downloader-choice ]]; then
    echo "DEBUG: No choice selected or invalid choice" >> /userdata/system/game-downloader/debug.log
    exit 1
fi

# Read user choice
choice=$(< /tmp/game-downloader-choice)
rm /tmp/game-downloader-choice

# Log the choice
echo "DEBUG: User selected option: $choice" >> /userdata/system/game-downloader/debug.log

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
        "$DOWNLOAD_MANAGER"  # Only show the download manager when selected
        ;;
    6)
        "$UNINSTALL_SCRIPT"
        ;;
    *)
        echo "DEBUG: Invalid choice: $choice" >> /userdata/system/game-downloader/debug.log
        dialog --infobox "Exiting..." 10 50
        sleep 2
        ;;
esac

# Clear screen on exit
clear

# Debugging: log the end of the script
echo "DEBUG: Exiting main menu script" >> /userdata/system/game-downloader/debug.log
