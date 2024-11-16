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
       --menu "Choose an option:" 15 50 9 \
       1 "Install Game Systems" \
       2 "Select a Game System" \
       3 "Run Updater" \
       4 "Status Checker" \
       5 "Uninstall Game Downloader" \
       2>/tmp/game-downloader-choice

# Debug: Print the chosen option
choice=$(< /tmp/game-downloader-choice)
echo "User choice: $choice"  # Debugging line to check the input

# Check if the choice is empty or invalid
if [[ -z "$choice" || ! "$choice" =~ ^[1-5]$ ]]; then
    dialog --msgbox "Invalid option selected or no choice made. Please try again." 10 50
    clear
    exit 0  # Exit the script if an invalid or no option is selected
fi

# Proceed based on the user's choice
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
        bash <(curl -s "$UNINSTALL")  # Fixed variable name here
        ;;
    *)
        # Handle invalid choices (although this case should never happen now)
        dialog --msgbox "Invalid option selected. Please try again." 10 50
        clear
        exit 0  # Exit the script if an invalid option is selected
        ;;
esac

# Clear screen at the end
clear
