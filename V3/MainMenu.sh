#!/bin/bash

# Ensure clear display
clear

# Set debug flag
DEBUG=true

# Function to log debug messages
log_debug() {
    if [ "$DEBUG" = true ]; then
        local message="$1"
        # Ensure the directory exists
        mkdir -p /userdata/system/game-downloader/debug
        # Append the message with timestamp to the log file
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> /userdata/system/game-downloader/debug/menu_debug.txt
    fi
}

# Log the start of the script
log_debug "Script started."

# URLs for external scripts
UPDATER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/Updater.sh"
DOWNLOAD_MANAGER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/Downloadcheck.sh"
UNINSTALL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/uninstall.sh"
INSTALL_GAME_SYSTEMS="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/installsystem.sh"  # New URL for install script
SELECT_SYSTEM="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/SystemMenu.sh"
# Main dialog menu loop
while true; do
    log_debug "Displaying menu."
    
    dialog --clear --backtitle "Game Downloader" \
           --title "Select a System" \
           --menu "Choose an option:" 15 50 9 \
           1 "Install Game Systems" \
           2 "Select a Game System" \
           2 "Run Updater" \
           3 "Status Checker" \
           4 "Uninstall Game Downloader" \
           2>/tmp/game-downloader-choice

    choice=$(< /tmp/game-downloader-choice)
    rm /tmp/game-downloader-choice

    # Log the user's choice
    log_debug "User selected option: $choice"

    # Check if the user canceled the dialog (no choice selected)
    if [ -z "$choice" ]; then
        log_debug "User canceled the dialog."
        clear
        dialog --infobox "Thank you for using Game Downloader! Any issues, message DTJW92 on Discord!" 10 50
        sleep 3
        exit 0  # Exit the script when Cancel is clicked or no option is selected
    fi

    # Execute the corresponding action based on user choice
    case $choice in
        1)
            log_debug "Running Install Game Systems script."
            bash <(curl -s "$INSTALL_GAME_SYSTEMS_URL")  # Downloads and runs the installation script
            log_debug "Install Game Systems script completed."
            break  # Exit the loop after action is completed
            ;;
        2)
            log_debug "Running system select script."
            bash <(curl -s "$SELECT_SYSTEM")
            log_debug " script completed."
            break  # Exit the loop after action is completed
            ;;
        3)
            log_debug "Running updater script."
            bash <(curl -s "$UPDATER")
            log_debug " script completed."
            break  # Exit the loop after action is completed
            ;;
        4)
            log_debug "Running download manager script."
            bash <(curl -s "$DOWNLOAD_MANAGER")
            log_debug " script completed."
            break  # Exit the loop after action is completed
            ;;
        5)
            log_debug "Running Uninstall script."
            bash <(curl -s "$UNINSTALL")
            log_debug " script completed."
            break  # Exit the loop after action is completed
            ;;
            
        *)
            log_debug "Invalid option selected."
            # Handle invalid choices
            dialog --msgbox "Invalid option selected. Please try again." 10 50
            clear
            ;;
    esac
done

# Log the end of the script
log_debug "Script completed."

# Clear screen at the end

