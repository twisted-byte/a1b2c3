#!/bin/bash

clear
dialog --msgbox "Welcome to the Game Downloader" 10 50
clear

# Function to display animated title with colors
animate_title() {
    local text="GAME DOWNLOADER"
    local delay=0.03
    local length=${#text}

    echo -ne "\e[1;36m"  # Set color to cyan
    for (( i=0; i<length; i++ )); do
        echo -n "${text:i:1}"
        sleep $delay
    done
    echo -e "\e[0m"  # Reset color
}

# Function to display animated border
animate_border() {
    local char="#"
    local width=50

    for (( i=0; i<width; i++ )); do
        echo -n "$char"
        sleep 0.02
    done
    echo
}

# Main script execution
clear
animate_border
animate_title
animate_border

# Set paths for downloader scripts
PSX_DOWNLOADER="/userdata/system/game-downloader/psx-downloader-menu.sh"
DC_DOWNLOADER="/userdata/system/game-downloader/dc-downloader-menu.sh"

# Check if both scripts exist
if [ ! -f "$PSX_DOWNLOADER" ] || [ ! -f "$DC_DOWNLOADER" ]; then
    dialog --msgbox "One or both downloader scripts not found. Exiting." 10 50
    exit 1
fi

# Show dialog menu
choice=$(dialog --clear --title "Select Game Downloader" \
--menu "Choose a downloader:" 15 50 2 \
1 "PSX Downloader" \
2 "Dreamcast Downloader" \
3>&1 1>&2 2>&3)

# Execute chosen script
case $choice in
    1)
        bash "$PSX_DOWNLOADER"
        ;;
    2)
        bash "$DC_DOWNLOADER"
        ;;
    *)
        dialog --msgbox "No valid option selected. Exiting." 10 50
        ;;
esac

clear
