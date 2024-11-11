#!/bin/bash

# Function to display the main menu
show_main_menu() {
    local choice
    dialog --clear --title "Game Downloader Menu" \
    --menu "Please choose an option:" 15 50 2 \
    1 "PSX Downloader" \
    2 "Dreamcast Downloader" \
    2>&1 >/dev/tty
}

# Function to run PSX Downloader
run_psx_downloader() {
    if [ -f "/userdata/system/game-downloader/psx-downloader-menu.sh" ]; then
        /userdata/system/game-downloader/psx-downloader-menu.sh
    else
        dialog --msgbox "PSX Downloader script not found!" 6 40
    fi
}

# Function to run Dreamcast Downloader
run_dreamcast_downloader() {
    if [ -f "/userdata/system/game-downloader/dc-downloader-menu.sh" ]; then
        /userdata/system/game-downloader/dc-downloader-menu.sh
    else
        dialog --msgbox "Dreamcast Downloader script not found!" 6 40
    fi
}

# Main menu loop
while true; do
    choice=$(show_main_menu)

    case $choice in
        1) run_psx_downloader ;;
        2) run_dreamcast_downloader ;;
        *)
            dialog --msgbox "Invalid option!" 6 40
            ;;
    esac
done
