#!/bin/bash

# Ensure clear display
clear

# URLs for game system scrapers (store the URLs in an associative array)
declare -A SCRAPERS

SCRAPERS["PSX"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/psx-scraper.sh"
SCRAPERS["PS2"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/ps2-scraper.sh"
SCRAPERS["Xbox"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/xbox-scraper.sh"
SCRAPERS["Dreamcast"]="https://raw.githubusercontent.com/DTJW92/game-downloader/refs/heads/main/scrapers/dc-scraper.sh"
SCRAPERS["GBA"]="https://raw.githubusercontent.com/DTJW92/game-downloader/refs/heads/main/scrapers/gba-scraper.sh"

# Create the menu dynamically based on the associative array
MENU_OPTIONS=()
i=1
for system in "${!SCRAPERS[@]}"; do
    MENU_OPTIONS+=("$i" "$system")  # Add option number and system name
    ((i++))  # Increment the option number
done

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
    clear
    dialog --infobox "Thank you for using Game Downloader! Any issues, message DTJW92 on Discord!" 10 50
    sleep 3
    exit 0  # Exit the script when Cancel is clicked or no option is selected
fi

# Find the system name corresponding to the user's choice
selected_system=$(echo "${!SCRAPERS[@]}" | cut -d' ' -f$choice)

# Execute the corresponding scraper based on the user's choice
if [ -n "$selected_system" ]; then
    # Get the URL for the selected system
    scraper_url="${SCRAPERS[$selected_system]}"

    # Function to show the download and execution gauge
    show_download_gauge() {
        local scraper_url="$1"

        # Initialize variables for progress
        download_progress=0
        scrape_progress=0

        (
            # Download the scraper and track the progress
            curl -Ls --progress-bar "$scraper_url" -o /tmp/scraper.sh | \
            while read -r line; do
                # Capture download percentage from curl's progress bar
                if [[ "$line" =~ ^[0-9]+$ ]]; then
                    download_progress=$line
                    # Calculate the overall progress (50% for download)
                    overall_progress=$((download_progress / 2))
                    echo $overall_progress  # Update the gauge with the download progress
                fi
            done

            sleep 1

            # Once download is complete, set progress to 50%
            download_progress=100
            overall_progress=50
            echo $overall_progress
            sleep 1

            # Now, start the scraping process
            bash /tmp/scraper.sh | \
            while read -r line; do
                # Capture scraper progress from the emitted progress
                if [[ "$line" =~ ^[0-9]+$ ]]; then
                    scrape_progress=$line
                fi

                # Combine download progress (50%) and scrape progress (50%)
                overall_progress=$(( (download_progress * 50 + scrape_progress * 50) / 100 ))
                echo $overall_progress  # Update the gauge with combined progress
            done
        ) | dialog --title "Installing $selected_system downloader" --gauge "Please wait while installing..." 10 70 0
    }

    # Show the download and scraping gauge
    show_download_gauge "$scraper_url"

else
    # Handle invalid choices
    dialog --msgbox "Invalid option selected. Please try again." 10 50
    clear
    exit 0  # Exit the script if an invalid option is selected
fi

# Clear screen at the end
clear

# Optionally, run another script after the process
bash /tmp/GameDownloader.sh
