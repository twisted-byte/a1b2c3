#!/bin/bash

# Ensure clear display
clear

# Define the debug log file
DEBUG_LOG="/userdata/system/game-downloader/debug/system_menu.txt"

# Function to log messages to the debug file
log_debug() {
    if [ "$DEBUG_ENABLED" = true ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$DEBUG_LOG"
    fi
}

# Function to log errors
log_error() {
    if [ "$DEBUG_ENABLED" = true ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$DEBUG_LOG"
    fi
}

# Log the start of the script
log_debug "Starting the game system installer script."

# Define the initial state of debugging (set to true or false)
DEBUG_ENABLED=true  # Set this to false if you want to disable logging by default

# URLs for game system scrapers (store the URLs in an associative array)
declare -A SCRAPERS

SCRAPERS["PSX"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/psx-scraper.sh"
SCRAPERS["PS2"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/ps2-scraper.sh"
SCRAPERS["Xbox"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/xbox-scraper.sh"
SCRAPERS["Dreamcast"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/dc-scraper.sh"
SCRAPERS["Game Boy Advance"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/gba-scraper.sh"

# Log the scrapers array
log_debug "Scrapers defined: ${!SCRAPERS[@]}"

# Define the predetermined order for the menu
MENU_ORDER=("PSX" "PS2" "Xbox" "Dreamcast" "Game Boy Advance")

# Log the menu order
log_debug "Menu order: ${MENU_ORDER[@]}"

# Create the menu dynamically based on the predetermined order
MENU_OPTIONS=("0" "Return to Main Menu" "9" "Toggle Debug Logging")  # Add option to toggle debug logging
i=1
for system in "${MENU_ORDER[@]}"; do
    MENU_OPTIONS+=("$i" "$system")  # Add option number and system name
    ((i++))  # Increment the option number
done

# Log the menu options
log_debug "Menu options: ${MENU_OPTIONS[@]}"

# Main dialog menu with dynamically generated options
dialog --clear --backtitle "Game System Installer" \
       --title "Select a Game System" \
       --menu "Choose an option:" 15 50 9 \
       "${MENU_OPTIONS[@]}" \
       2>/tmp/game-downloader-choice

choice=$(< /tmp/game-downloader-choice)
rm /tmp/game-downloader-choice

# Log the user's choice
log_debug "User selected: $choice"

# Check if the user canceled the dialog (no choice selected)
if [ -z "$choice" ]; then
    log_debug "User canceled the dialog. Exiting script."
    clear
    exit 0  # Exit the script when Cancel is clicked or no option is selected
fi

# If user selects "Return to Main Menu"
if [ "$choice" -eq 0 ]; then
    log_debug "User selected 'Return to Main Menu'. Returning to the main menu."
    clear
    exec /tmp/GameDownloader.sh  # Execute the main menu script
    exit 0  # In case exec fails, exit the script
fi

# If user selects "Toggle Debug Logging"
if [ "$choice" -eq 9 ]; then
    if [ "$DEBUG_ENABLED" = true ]; then
        DEBUG_ENABLED=false
        dialog --msgbox "Debugging has been disabled." 10 50
        log_debug "Debugging has been disabled by the user."
    else
        DEBUG_ENABLED=true
        dialog --msgbox "Debugging has been enabled." 10 50
        log_debug "Debugging has been enabled by the user."
    fi
    # Return to the menu after toggling
    clear
    exec /tmp/GameDownloader.sh
    exit 0
fi

# Get the selected system based on the user choice
selected_system="${MENU_ORDER[$choice-1]}"  # Adjust for 0-based indexing

# Log the selected system
log_debug "Selected system: $selected_system"

# Check if a valid system was selected
if [ -z "$selected_system" ]; then
    dialog --msgbox "Invalid option selected. Please try again." 10 50
    log_debug "Invalid option selected. Returning to main menu."
    clear
    bash /tmp/GameDownloader.sh  # Return to the main menu
    exit 1
fi

# Get the URL for the selected system
scraper_url="${SCRAPERS[$selected_system]}"

# Log the scraper URL
log_debug "Scraper URL: $scraper_url"

# Inform the user that the installation is starting
dialog --infobox "Installing $selected_system downloader. Please wait..." 10 50

# Log the download process
log_debug "Downloading scraper script for $selected_system."

# Download and execute the scraper script
curl -Ls "$scraper_url" -o /tmp/scraper.sh 2>&1 | tee -a "$DEBUG_LOG"
if [ $? -ne 0 ]; then
    log_error "Failed to download scraper script for $selected_system."
    exit 1
fi

log_debug "Scraper script downloaded to /tmp/scraper.sh."

bash /tmp/scraper.sh 2>&1 | tee -a "$DEBUG_LOG"
if [ $? -ne 0 ]; then
    log_error "$selected_system scraper execution failed."
    exit 1
fi

# Log after script execution
log_debug "$selected_system scraper execution completed."

# Show completion message once the process is done (after the script finishes)
dialog --infobox "Installation complete!" 10 50
log_debug "Installation complete message displayed."

sleep 2  # Display the "Installation complete!" message for a few seconds

# Optionally, return to the main menu or run another script after the process
bash /tmp/GameDownloader.sh
log_debug "Returning to the main menu."
