#!/bin/bash

# Ensure clear display
clear

# Set debug flag
DEBUG=true

# Function to log debug messages
log_debug() {
    if [ "$DEBUG" = true ]; then
        local message="$1"
        mkdir -p /userdata/system/game-downloader/debug  # Ensure the directory exists
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> /userdata/system/game-downloader/debug/menu_debug.txt
    fi
}

# Log the start of the script
log_debug "Script started."

# URLs for external scripts
declare -A MENU_ITEMS=(
    [1]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/installsystem.sh"  # Install Game Systems
    [2]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/SystemMenu.sh"      # Select a Game System
    [3]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/search.sh"          # Search for a Game
    [4]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/Updater.sh"         # Run Updater
    [5]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/Downloadcheck.sh"   # Status Checker
    [6]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/uninstall.sh"       # Uninstall Game Downloader
)

# Menu items description
declare -A MENU_DESCRIPTIONS=(
    [1]="Install Game Systems"
    [2]="Select a Game System"
    [3]="Search for a Game"
    [4]="Run Updater"
    [5]="Status Checker"
    [6]="Uninstall Game Downloader"
)

# Main dialog menu loop
while true; do
    log_debug "Displaying menu."

 # Define the order explicitly
MENU_ORDER=(1 2 3 4 5 6 7)  # Add 7 (Exit) at the end explicitly

# Dynamically build menu options in the correct order
MENU_OPTIONS=()
for key in "${MENU_ORDER[@]}"; do
    if [ "$key" -eq 7 ]; then
        MENU_OPTIONS+=("$key" "Exit")  # Add Exit option
    else
        MENU_OPTIONS+=("$key" "${MENU_DESCRIPTIONS[$key]}")
    fi
done
    # Display menu
    dialog --clear --backtitle "Game Downloader" \
           --title "Select a System" \
           --menu "Choose an option:" 15 50 9 \
           "${MENU_OPTIONS[@]}" \
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

    # Exit logic for option 7
    if [ "$choice" -eq 7 ]; then
        log_debug "Exit selected. Ending script."
        clear
        dialog --infobox "Thank you for using Game Downloader! Any issues, please reach out to DTJW92 on Discord!" 10 50
        sleep 3
        
        # Get the parent terminal emulator and close it if applicable
        TERMINAL_EMULATOR=$(ps -o comm= -p $PPID)
        if [[ "$TERMINAL_EMULATOR" == "xterm" ]]; then
            log_debug "Closing xterm terminal."
            kill -9 "$PPID"
        else
            log_debug "No xterm process found or another terminal emulator detected."
        fi

        exit 0
    fi

    # Execute the corresponding script for the selected option
    if [[ -n "${MENU_ITEMS[$choice]}" ]]; then
        log_debug "Running script for option $choice."
        bash <(curl -s "${MENU_ITEMS[$choice]}")
        log_debug "Script for option $choice completed."
    else
        log_debug "Invalid option selected: $choice."
        dialog --msgbox "Invalid option selected. Please try again." 10 50
    fi
done
