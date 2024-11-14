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

# Log function for debugging and tracking
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> /userdata/system/game-downloader/debug_log.txt
}

# Main dialog menu with loop to keep the menu active until a valid choice is selected
dialog --clear --backtitle "Game Downloader" \
       --title "Select a System" \
       --menu "Choose an option:" 15 50 8 \
       1 "PSX Downloader" \
       2 "PS2 Downloader" \
       3 "Dreamcast Downloader" \
       4 "Run Updater" \
       5 "Status Checker" \
       6 "Uninstall Game Downloader" 2>/tmp/game-downloader-choice

choice=$(< /tmp/game-downloader-choice)
rm /tmp/game-downloader-choice

# Check if the user canceled the dialog (no choice selected)
if [ -z "$choice" ]; then
    clear
    dialog --infobox "Thank you for using Game Downloader! Any issues, message DTJW92 on Discord!" 10 50
    log_action "User exited the menu without selecting an option."
    sleep 3
    exit 0  # Exit the script when Cancel is clicked or no option is selected
fi

log_action "User selected option: $choice"

# Execute the corresponding action based on user choice
case $choice in
    1)
        log_action "Executing PSX Downloader..."
        bash <(curl -s "$PSX_MENU_URL") || { dialog --msgbox "Failed to download PSX Downloader. Please try again." 10 50; log_action "Failed to download PSX Downloader"; exit 1; }
        ;;
    2)
        log_action "Executing PS2 Downloader..."
        bash <(curl -s "$PS2_MENU_URL") || { dialog --msgbox "Failed to download PS2 Downloader. Please try again." 10 50; log_action "Failed to download PS2 Downloader"; exit 1; }
        ;;
    3)
        log_action "Executing Dreamcast Downloader..."
        bash <(curl -s "$DC_MENU_URL") || { dialog --msgbox "Failed to download Dreamcast Downloader. Please try again." 10 50; log_action "Failed to download Dreamcast Downloader"; exit 1; }
        ;;
    4)
        log_action "Executing Updater..."
        bash <(curl -s "$UPDATER_URL") || { dialog --msgbox "Failed to download Updater. Please try again." 10 50; log_action "Failed to download Updater"; exit 1; }
        ;;
    5)
        log_action "Executing Status Checker..."
        bash <(curl -s "$DOWNLOAD_MANAGER_URL") || { dialog --msgbox "Failed to download Status Checker. Please try again." 10 50; log_action "Failed to download Status Checker"; exit 1; }
        ;;
    6)
        log_action "Executing Uninstall..."
        bash <(curl -s "$UNINSTALL_URL") || { dialog --msgbox "Failed to download Uninstall script. Please try again." 10 50; log_action "Failed to download Uninstall script"; exit 1; }
        ;;
    *)
        # Handle invalid choices
        dialog --msgbox "Invalid option selected. Please try again." 10 50
        log_action "Invalid option selected by user."
        clear
        exit 0  # Exit the script if an invalid option is selected
        ;;
esac

# Clear screen at the end
log_action "Execution completed for selected option: $choice"
clear
