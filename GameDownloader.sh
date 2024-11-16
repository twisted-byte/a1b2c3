#!/bin/bash

# Ensure clear display
clear

# URLs for external scripts
PSX_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-downloader-menu.sh"
PS2_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/ps2-downloader-menu.sh"
DC_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-downloader-menu.sh"
UPDATER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Updater.sh"
DOWNLOAD_MANAGER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Downloadcheck.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/uninstall.sh"
INSTALL_GAME_SYSTEMS_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/install.sh"  # New URL for install script

# Main dialog menu with loop to keep the menu active until a valid choice is selected
dialog --clear --backtitle "Game Downloader" \
       --title "Select a System" \
       --menu "Choose an option:" 15 50 9 \  # Increased the number of options to 9
       1 "Install Game Systems" \  # Move this option to the top
       2 "Run Updater" \
       3 "Status Checker" \
       4 "Uninstall Game Downloader" \
       2>/tmp/game-downloader-choice

choice=$(< /tmp/game-downloader-choice)
rm /tmp/game-downloader-choice

# Check if the user canceled the dialog (no choice selected)
if [ -z "$choice" ]; then
    clear
    dialog --infobox "Thank you for using Game Downloader! Any issues, message DTJW92 on Discord!" 10 50
    sleep 3
    exit 0  # Exit the script when Cancel is clicked or no option is selected
fi

# Execute the corresponding action based on user choice
case $choice in
    1)
        # Run the install game systems script
        bash <(curl -s "$INSTALL_GAME_SYSTEMS_URL")  # Downloads and runs the installation script
        ;;
    2)
        bash <(curl -s "$UPDATER_URL")
        ;;
    3)
        bash <(curl -s "$DOWNLOAD_MANAGER_URL")
        ;;
    4)
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
