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
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> /userdata/system/game-downloader/debug/install_debug.txt
    fi
}

# Log the start of the script
log_debug "Script started."

# URLs for game system scrapers (store the URLs in an associative array)
declare -A SCRAPERS

SCRAPERS["PSX"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/psx-scraper.sh"
SCRAPERS["PS2"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/ps2-scraper.sh"
SCRAPERS["Xbox"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/xbox-scraper.sh"
SCRAPERS["Dreamcast"]="https://raw.githubusercontent.com/DTJW92/game-downloader/refs/heads/main/scrapers/dc-scraper.sh"
SCRAPERS["GBA"]="https://raw.githubusercontent.com/DTJW92/game-downloader/refs/heads/main/scrapers/gba-scraper.sh"

# Log the SCRAPERS array content
log_debug "Available scrapers: ${!SCRAPERS[@]}"

# Create the menu dynamically based on the associative array
MENU_OPTIONS=()
i=1
for system in "${!SCRAPERS[@]}"; do
    MENU_OPTIONS+=("$i" "$system")  # Add option number and system name
    ((i++))  # Increment the option number
done

# Log the menu options
log_debug "Menu options generated: ${MENU_OPTIONS[@]}"

# Main dialog menu with dynamically generated options
dialog --clear --backtitle "Game Downloader" \
       --title "Select a Game System" \
       --menu "Choose an option:" 15 50 9 \
       "${MENU_OPTIONS[@]}" \
       2>/tmp/game-downloader-choice

choice=$(< /tmp/game-downloader-choice)
rm /tmp/game-downloader-choice

# Check if the user canceled the dialog (no choice selected)
if [ -z "$choice" ]; then
    log_debug "User canceled the dialog."
    clear
    dialog --infobox "Thank you for using Game Downloader! Any issues, message DTJW92 on Discord!" 10 50
    sleep 3
    exit 0  # Exit the script when Cancel is clicked or no option is selected
fi

# Log the user's choice
log_debug "User selected option: $choice"

# Find the system name corresponding to the user's choice
selected_system=$(echo "${!SCRAPERS[@]}" | cut -d' ' -f$choice)

# Log the selected system
log_debug "Selected system: $selected_system"

# Execute the corresponding scraper based on the user's choice
if [ -n "$selected_system" ]; then
    # Get the URL for the selected system
    scraper_url="${SCRAPERS[$selected_system]}"
    log_debug "Scraper URL for $selected_system: $scraper_url"

    # Function to show the download and execution gauge
    show_download_gauge() {
        local scraper_url="$1"

        # Initialize variables for progress
        download_progress=0
        scrape_progress=0
        overall_progress=0

        # Download the scraper and track the progress
        curl -Ls --progress-bar "$scraper_url" -o /tmp/scraper.sh | \
        while read -r line; do
            # Capture download percentage from curl's progress bar
            if [[ "$line" =~ ^[0-9]+$ ]]; then
                download_progress=$line
                # Calculate the overall progress (50% for download)
                overall_progress=$((download_progress / 2))
                log_debug "Download progress: $download_progress%"
                echo $overall_progress  # Update the gauge with the download progress
            fi
        done

        sleep 1

        # Once download is complete, set progress to 50%
        download_progress=100
        overall_progress=50
        log_debug "Download completed, setting progress to 50%."
        echo $overall_progress
        sleep 1

        # Now, start the scraping process
        bash /tmp/scraper.sh | \
        while read -r line; do
            # Capture scraper progress from the emitted progress (if any)
            if [[ "$line" =~ ^[0-9]+$ ]]; then
                scrape_progress=$line
                log_debug "Scraping progress: $scrape_progress%"
            fi

            # Combine download progress (50%) and scrape progress (50%)
            overall_progress=$(( (download_progress * 50 + scrape_progress * 50) / 100 ))
            log_debug "Combined progress: $overall_progress%"
            echo $overall_progress  # Update the gauge with combined progress
        done
    }

    # Show the download and scraping gauge
    show_download_gauge "$scraper_url"

else
    log_debug "Invalid option selected."
    # Handle invalid choices
    dialog --msgbox "Invalid option selected. Please try again." 10 50
    clear
    exit 0  # Exit the script if an invalid option is selected
fi

# Log the end of the script
log_debug "Script completed successfully."

# Clear screen at the end
clear

# Optionally, run another script after the process
bash /tmp/GameDownloader.sh
