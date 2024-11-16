#!/bin/bash

# Ensure clear display
clear

# URLs for external scripts
UPDATER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/Updater.sh"
DOWNLOAD_MANAGER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Downloadcheck.sh"
UNINSTALL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/uninstall.sh"
INSTALL_GAME_SYSTEMS="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/installsystem.sh"
SELECT_SYSTEM="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/SystemMenu.sh"
# Main dialog menu with loop to keep the menu active until a valid choice is selected
dialog --clear --backtitle "Game Downloader" \
       --title "Select a System" \
       --menu "Choose an option:" 15 50 9 \  # Increased the number of options to 9
       1 "Install Game Systems" \ 
       2 "Select a Game System" \ 
       3 "Run Updater" \
       4 "Status Checker" \
       5 "Uninstall Game Downloader" \
       2>/tmp/game-downloader-choice

choice=$(< /tmp/game-downloader-choice)

case $choice in
    1)
        # Run the install game systems script
        bash <(curl -s "$INSTALL_GAME_SYSTEMS")  # Downloads and runs the installation script
        ;;
    2)
        bash <(curl -s "$SELECT_SYSTEM")
        ;;
    3)
        bash <(curl -s "$UPDATER")
        ;;
    4)
        bash <(curl -s "$DOWNLOAD_MANAGER")
        ;;
    5)
        bash <(curl -s "$UNINSTALL_URL")
        ;;
    *)
        # Handle invalid choices
        dialog --msgbox "Invalid option selected. Please try again." 10 50
        clear
        exit 0  # Exit the script if an invalid option is selected
        ;;
esac

# Clear screen at the end
clear
