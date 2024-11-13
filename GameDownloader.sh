#!/bin/bash

# Log file for debugging and error logging
LOG_FILE="/userdata/system/game-downloader/debug/dialog-debug.log"

# Ensure clear display
clear

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
    echo "$(date) - Error: dialog is not installed" >> "$LOG_FILE"
    dialog --msgbox "Error: dialog is not installed. Please install it and try again." 10 50
    exit 1
fi

# Function to start download.sh in the background with nohup
start_download() {
    # Run download.sh using nohup, sending output to a log file
    nohup bash /userdata/system/game-downloader/download.sh >> /userdata/system/game-updater/debug/debug_log.txt 2>&1 &

    # Get the PID of the process and log it
    DOWNLOAD_PID=$!
    echo "$(date) - download.sh started in the background with PID: $DOWNLOAD_PID" >> "$LOG_FILE"
}

# Main dialog menu with loop to keep the menu active until a valid choice is selected
while true; do
    dialog --clear --backtitle "Game Downloader" \
           --title "Select a System" \
           --menu "Choose an option:" 15 50 8 \
           1 "PSX Downloader" \
           2 "PS2 Downloader" \
           3 "Dreamcast Downloader" \
           4 "Run Updater" \
           5 "Run Download Manager" \
           6 "Uninstall Game Downloader" \
           7 "Exit" 2>/tmp/game-downloader-choice  # Adding an "Exit" option

    choice=$(< /tmp/game-downloader-choice)
    rm /tmp/game-downloader-choice

    # Log the user's choice
    echo "$(date) - User selected option: $choice" >> "$LOG_FILE"

    # Handle the "Exit" option
    if [ "$choice" -eq 7 ]; then
        echo "$(date) - User selected Exit, exiting the script." >> "$LOG_FILE"
        dialog --msgbox "Exiting the Game Downloader. Goodbye!" 10 50
        clear
        break
    fi

    # Handle user canceling the menu
    if [ $? -ne 0 ]; then
        echo "$(date) - User canceled the dialog, exiting." >> "$LOG_FILE"
        clear
        break  # Exit if the user cancels
    fi

    # Execute the selected menu option
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
            echo "$(date) - Invalid choice selected, exiting." >> "$LOG_FILE"
            dialog --infobox "Exiting..." 10 50
            sleep 2
            break  # Exit if no valid option is selected
            exit 0
            ;;
    esac

    # Start download.sh in the background
    start_download  # Run download.sh in the background
done

# Clear screen on exit
clear

# Run the curl command to reload the games (output suppressed)
curl http://127.0.0.1:1234/reloadgames &> /dev/null
