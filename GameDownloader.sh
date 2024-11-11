#!/bin/bash

# Define paths to the downloader menu scripts
PSX_DOWNLOADER="/userdata/system/game-downloader/psx-downloader-menu.sh"
DC_DOWNLOADER="/userdata/system/game-downloader/dc-downloader-menu.sh"

# Display main game downloader menu
choice=$(dialog --clear --title "Game Downloader" \
--menu "Choose a game downloader:" 15 50 2 \
1 "PSX Downloader" \
2 "Dreamcast Downloader" \
3>&1 1>&2 2>&3)

# Check if the user made a choice
if [ $? -eq 0 ]; then
    case $choice in
        1)
            # Run the PSX downloader menu if it exists
            if [ -f "$PSX_DOWNLOADER" ]; then
                bash "$PSX_DOWNLOADER"
            else
                dialog --msgbox "PSX Downloader script not found." 6 40
            fi
            ;;
        2)
            # Run the Dreamcast downloader menu if it exists
            if [ -f "$DC_DOWNLOADER" ]; then
                bash "$DC_DOWNLOADER"
            else
                dialog --msgbox "Dreamcast Downloader script not found." 6 40
            fi
            ;;
        *)
            dialog --msgbox "Invalid option." 6 40
            ;;
    esac
else
    # Clear screen and exit if the user canceled
    clear
fi
