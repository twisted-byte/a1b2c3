#!/bin/bash

# URL for the combined game system menu script
COMBINED_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Game-Menu.sh"
UPDATER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Updater.sh"
DOWNLOAD_MANAGER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Downloadcheck.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/uninstall.sh"

# Main dialog menu with loop to keep the menu active until a valid choice is selected
dialog --clear --backtitle "Game Downloader" \
       --title "Select a System" \
       --menu "Choose an option:" 15 50 8 \
       1 "PSX Downloader" \
       2 "PS2 Downloader" \
       3 "Dreamcast Downloader" \
       4 "GBA Downloader" \
       5 "Run Updater" \
       6 "Status Checker" \
       7 "Uninstall Game Downloader" 2>/tmp/game-downloader-choice

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
        bash <(curl -s "$COMBINED_MENU_URL") "PSX"
        ;;
    2)
        bash <(curl -s "$COMBINED_MENU_URL") "PS2"
        ;;
    3)
        bash <(curl -s "$COMBINED_MENU_URL") "Dreamcast"
        ;;
    4)
        bash <(curl -s "$COMBINED_MENU_URL") "GBA"
        ;;
    5)
        bash <(curl -s "$UPDATER_URL")
        ;;
    6)
        bash <(curl -s "$DOWNLOAD_MANAGER_URL")
        ;;
    7)
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
