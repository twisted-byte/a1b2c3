#!/bin/bash

# Ensure clear display
clear

# URLs for game system scrapers (store the URLs in an associative array)
declare -A SCRAPERS

SCRAPERS["PSX"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/psx-scraper.sh"
SCRAPERS["PS2"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/ps2-scraper.sh"
SCRAPERS["Xbox"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/xbox-scraper.sh"
SCRAPERS["Dreamcast"]="https://raw.githubusercontent.com/DTJW92/game-downloader/refs/heads/main/scrapers/dc-scraper.sh"
SCRAPERS["Game Boy Advance"]="https://raw.githubusercontent.com/DTJW92/game-downloader/refs/heads/main/scrapers/gba-scraper.sh"

# Create the menu dynamically based on the associative array
MENU_OPTIONS=("0" "Return to Main Menu")  # Add "Return to Main Menu" as the first option
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
rm /tmp/game-downloader-choice

# Check if the user canceled the dialog (no choice selected)
if [ -z "$choice" ]; then
    clear
    exit 0  # Exit the script when Cancel is clicked or no option is selected
fi

# If user selects "Return to Main Menu"
if [ "$choice" -eq 0 ]; then
    exec /tmp/GameDownloader.sh  # Immediately return to the main menu script
    exit 0  # In case exec fails, exit the script
fi

# Find the system name corresponding to the user's choice
selected_system=$(echo "${!SCRAPERS[@]}" | cut -d' ' -f$choice)

# Execute the corresponding scraper based on the user's choice
if [ -n "$selected_system" ]; then
    # Get the URL for the selected system
    scraper_url="${SCRAPERS[$selected_system]}"

    # Download and execute the scraper script
    curl -Ls "$scraper_url" -o /tmp/scraper.sh
    bash /tmp/scraper.sh  # Run the downloaded scraper

else
    # Handle invalid choices
    dialog --msgbox "Invalid option selected. Please try again." 10 50
    clear
    exit 0  # Exit the script if an invalid option is selected
fi

# Clear screen at the end
clear

# Optionally, return to the main menu or run another script after the process
exec /tmp/GameDownloader.sh
