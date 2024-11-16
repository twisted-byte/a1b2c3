#!/bin/bash

# Ensure clear display
clear

# URLs for external scripts
UPDATER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Updater.sh"
DOWNLOAD_MANAGER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Downloadcheck.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/uninstall.sh"
INSTALL_GAME_SYSTEMS_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/installsystem.sh"  # New URL for install script

# Main dialog menu loop
while true; do
    dialog --clear --backtitle "Game Downloader" \
           --title "Select a System" \
           --menu "Choose an option:" 15 50 9 \
           1 "Install Game Systems" \
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
            bash <(curl -s "$INSTALL_GAME_SYSTEMS_URL")  # Downloads and runs the installation script
            break  # Exit the loop after action is completed
            ;;
        2)
            bash <(curl -s "$UPDATER_URL")
            break  # Exit the loop after action is completed
            ;;
        3)
            bash <(curl -s "$DOWNLOAD_MANAGER_URL")
            break  # Exit the loop after action is completed
            ;;
        4)
            bash <(curl -s "$UNINSTALL_URL")
            break  # Exit the loop after action is completed
            ;;
        *)
            # Handle invalid choices
            dialog --msgbox "Invalid option selected. Please try again." 10 50
            clear
            ;;
    esac
done

# Clear screen at the end
clear
