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
    # Ensure we're in the correct directory before running the script
    cd /userdata/system/game-downloader || { echo "$(date) - Error: Failed to change directory"; exit 1; }

    # Run download.sh using nohup, sending output to a log file and ensuring DISPLAY is passed
    nohup DISPLAY=:0.0 bash /userdata/system/game-downloader/download.sh >> /userdata/system/game-updater/debug/debug_log.txt 2>&1 &

    # Get the PID of the background process and log it
    DOWNLOAD_PID=$!
    echo "$(date) - download.sh started in the background with PID: $DOWNLOAD_PID" >> "$LOG_FILE"

    # Sleep for a moment to give time for the background process to start
    sleep 2

    # Log whether download.sh is still running
    if ps -p $DOWNLOAD_PID > /dev/null; then
        echo "$(date) - download.sh is still running with PID: $DOWNLOAD_PID" >> "$LOG_FILE"
    else
        echo "$(date) - download.sh failed to start or exited unexpectedly" >> "$LOG_FILE"
    fi
}

# Define the URLs to fetch the scripts from GitHub
PSX_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-downloader-menu.sh"
PS2_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/ps2-downloader-menu.sh"
DC_MENU_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-downloader-menu.sh"
UPDATER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/Updater.sh"
DOWNLOAD_MANAGER_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/DownloadManager.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/DTJW92/game-downloader/main/uninstall.sh"

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
           6 "Uninstall Game Downloader" 2>/tmp/game-downloader-choice

    choice=$(< /tmp/game-downloader-choice)
    rm /tmp/game-downloader-choice

    # Log the user's choice
    echo "$(date) - User selected option: $choice" >> "$LOG_FILE"

    # Check if user canceled the dialog
    if [ $? -ne 0 ]; then
        echo "$(date) - User canceled the dialog, exiting." >> "$LOG_FILE"
        clear

        # Kill the xterm window if the dialog is canceled
        kill $$  # This kills the current process (which in this case is the script running inside xterm)

        break  # Exit loop when Cancel is clicked
    fi

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
            break  # Exit loop when no valid choice is selected
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
