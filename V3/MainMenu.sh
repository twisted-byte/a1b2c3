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

# Check if xdvdfs is available; if not, update BGD.
if ! command -v xdvdfs >/dev/null 2>&1; then
    curl -L https://github.com/twisted-byte/a1b2c3/raw/main/V3/Updater.sh | bash || exit 1
fi

# URLs for external scripts
declare -A MENU_ITEMS=( 
    [1]="https://raw.githubusercontent.com/twisted-byte/a1b2c3/main/V3/SystemMenu.sh"  # Select Game Systems
    [2]="https://raw.githubusercontent.com/twisted-byte/a1b2c3/main/V3/installsystem.sh"      # Install a Game System
    [3]="https://raw.githubusercontent.com/twisted-byte/a1b2c3/main/V3/search.sh"          # Search for a Game
    [4]="https://raw.githubusercontent.com/twisted-byte/a1b2c3/main/V3/StatusChecker.sh"         # Run Updater
    [5]="https://raw.githubusercontent.com/twisted-byte/a1b2c3/main/V3/Updater.sh"   # Status Checker
    [6]="https://raw.githubusercontent.com/twisted-byte/a1b2c3/main/V3/uninstall.sh"       # Uninstall Game Downloader
)

# Menu items description
declare -A MENU_DESCRIPTIONS=( 
    [1]="Select a Game Systems"
    [2]="Install a Game System"
    [3]="Search for a Game"
    [4]="Status Checker"
    [5]="Run Updater"
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
height=$(( ${#MENU_OPTIONS[@]} / 2 + 7 ))
dialog --clear --backtitle "Game Downloader" \
       --title "Select a System" \
       --menu "Choose an option:" "$height" 50 9 \
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
        pkill -f "$(basename $0)"
        kill -9 $(ps -o ppid= -p $$)
        exit 0  # Exit gracefully
    fi

# Exit logic for option 7
if [ "$choice" -eq 7 ]; then
    log_debug "Exit selected. Ending script."
    
    # Display exit message using dialog
    dialog --infobox "Thank you for using Game Downloader! Any issues, please reach out to DTJW92 on Discord!" 10 50
    sleep 3  # Allow user to see message

    # Ensure all child processes exit
    trap "exit 0" SIGTERM SIGKILL

    # Kill the script itself and its parent shell
    kill -TERM $$
    
    # If still running, force kill
    kill -9 $$
    
    exit 0
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
