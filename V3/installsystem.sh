#!/bin/bash

# Ensure clear display


# Check dependencies
for cmd in dialog curl bash; do
    if ! command -v $cmd &>/dev/null; then
        echo "Error: $cmd is not installed. Please install it and try again."
        exit 1
    fi
done

# URLs for game system scrapers (store the URLs in an associative array)
declare -A SCRAPERS

SCRAPERS["PSX"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/psx-scraper.sh"
SCRAPERS["PS2"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/ps2-scraper.sh"
SCRAPERS["Xbox"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/xbox-scraper.sh"
SCRAPERS["Dreamcast"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/dc-scraper.sh"
SCRAPERS["GBA"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/gba-scraper.sh"

# Create the menu dynamically based on the associative array
MENU_OPTIONS=()
i=1
for system in "${!SCRAPERS[@]}"; do
    MENU_OPTIONS+=("$i" "$system")  # Add option number and system name
    ((i++))  # Increment the option number
done

# Main dialog menu with dynamically generated options
dialog --clear --backtitle "Game System Installer" \
       --title "Select a Game System" \
       --menu "Choose an option:" 15 50 9 \
       "${MENU_OPTIONS[@]}" \
       2>/tmp/game-downloader-choice

choice=$(< /tmp/game-downloader-choice)
rm -f /tmp/game-downloader-choice

# Check if the user canceled the dialog (no choice selected)
if [ -z "$choice" ]; then
    clear
    dialog --infobox "Thank you for using Game Downloader! Any issues, message DTJW92 on Discord!" 10 50
    sleep 3
    exit 0  # Exit the script when Cancel is clicked or no option is selected
fi

# Find the system name corresponding to the user's choice
selected_system=$(for system in "${!SCRAPERS[@]}"; do echo "$system"; done | sed -n "${choice}p")

# Execute the corresponding scraper based on the user's choice
if [ -n "$selected_system" ]; then
    # Get the URL for the selected system
    scraper_url="${SCRAPERS[$selected_system]}"

    # Inform the user that the installation is starting
    dialog --infobox "Installing $selected_system downloader. Please wait..." 10 50
    sleep 2  # Simulate some wait time before the actual installation process

    # Download and execute the scraper script
    curl -Ls "$scraper_url" -o /tmp/scraper.sh
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Error: Failed to download the script for $selected_system." 10 50
        clear
        exit 1
    fi

    bash /tmp/scraper.sh  # Run the downloaded scraper
    if [[ $? -ne 0 ]]; then
        dialog --msgbox "Error: Failed to execute the scraper script for $selected_system." 10 50
        clear
        exit 1
    fi

    # Show completion message once the process is done
    dialog --infobox "Installation complete!" 10 50
    sleep 2  # Display the "Installation complete!" message for a few seconds

else
    # Handle invalid choices
    dialog --msgbox "Invalid option selected. Please try again." 10 50
    clear
    exit 1  # Exit the script if an invalid option is selected
fi

# Clear screen at the end

