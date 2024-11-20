#!/bin/bash

# Ensure clear display
clear

# Set debug flag
DEBUG=false

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
    [1]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/SystemMenu2.sh"  # Select Game Systems
    [2]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/installsystem.sh"      # Install a Game System
    [3]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/search.sh"          # Search for a Game
    [4]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/Updater.sh"         # Run Updater
    [5]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/Downloadcheck.sh"   # Status Checker
    [6]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/uninstall.sh"       # Uninstall Game Downloader
)

# Menu items description
declare -A MENU_DESCRIPTIONS=( 
    [1]="Select a Game Systems"
    [2]="Install a Game System"
    [3]="Search for a Game"
    [4]="Run Updater"
    [5]="Status Checker"
    [6]="Uninstall Game Downloader"
)

# Main dialog menu loop
while true; do
    log_debug "Displaying menu."

    # Define the order explicitly
    MENU_ORDER=(1 2 3 4 5 6)

    # Dynamically build menu options in the correct order
    MENU_OPTIONS=()
    for key in "${MENU_ORDER[@]}"; do
        MENU_OPTIONS+=("$key" "${MENU_DESCRIPTIONS[$key]}")
    done
    
    # Add Exit option after the main menu items
    MENU_OPTIONS+=("7" "Exit")  # Add Exit option after the loop

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
        exit 0  # Exit gracefully
    fi

    # Exit logic for option 7
    if [ "$choice" -eq 7 ]; then
        log_debug "Exit selected. Ending script."
        clear
        dialog --infobox "Thank you for using Game Downloader! Any issues, please reach out to DTJW92 on Discord!" 10 50
        sleep 3
        # Kill the parent process (foreground terminal)
        kill -9 $(ps -o ppid= -p $$)
        exit 0  # Exit gracefully
    fi

    # Execute the corresponding script for the selected option
    if [[ -n "${MENU_ITEMS[$choice]}" ]]; then
        log_debug "Running script for option $choice."
        script_url="${MENU_ITEMS[$choice]}"
        script_path="/tmp/script.sh"

        # Download and execute the script
        curl -s "$script_url" -o "$script_path" && bash "$script_path"
        log_debug "Script for option $choice completed."
    else
        log_debug "Invalid option selected: $choice."
        dialog --msgbox "Invalid option selected. Please try again." 10 50
    fi
done
