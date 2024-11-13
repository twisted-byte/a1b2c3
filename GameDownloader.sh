#!/bin/bash

# Ensure clear display
clear

# URLs for external scripts
PSX_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-downloader-menu.sh"
PS2_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/ps2-downloader-menu.sh"
DC_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-downloader-menu.sh"
UPDATER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Updater.sh"
DOWNLOAD_MANAGER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/DownloadManager.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/uninstall.sh"

# Main dialog menu with loop to keep the menu active until a valid choice is selected
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
    *)
        # Handle invalid choices
        dialog --msgbox "Invalid option selected. Please try again." 10 50
        clear
        exit 0  # Exit the script if an invalid option is selected
        ;;
esac

# Clear screen at the end
clear

# Run the curl command to reload the games (output suppressed)
curl http://127.0.0.1:1234/reloadgames &> /dev/null
