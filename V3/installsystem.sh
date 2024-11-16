#!/bin/bash

# Define the debug log location
DEBUG_LOG="/userdata/system/game-downloader/debug/install_debug.txt"

# Create the debug directory if it doesn't exist
mkdir -p "$(dirname "$DEBUG_LOG")"

# Redirect all output (stdout and stderr) to the debug log
exec >"$DEBUG_LOG" 2>&1

# Ensure clear display
clear

# Check for necessary tools
for cmd in dialog curl bash; do
    if ! command -v $cmd &>/dev/null; then
        dialog --msgbox "Error: $cmd is not installed. Please install it and try again." 10 50
        exit 1
    fi
done

# Define scraper URLs in an associative array
declare -A SCRAPERS=(
    ["PSX"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/psx-scraper.sh"
    ["PS2"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/ps2-scraper.sh"
    ["Xbox"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/xbox-scraper.sh"
    ["Dreamcast"]="https://raw.githubusercontent.com/DTJW92/game-downloader/refs/heads/main/scrapers/dc-scraper.sh"
    ["GBA"]="https://raw.githubusercontent.com/DTJW92/game-downloader/refs/heads/main/scrapers/gba-scraper.sh"
)

# Validate scrapers
if [ ${#SCRAPERS[@]} -eq 0 ]; then
    dialog --msgbox "Error: No scrapers found. Check the script configuration." 10 50
    exit 1
fi

# Construct menu dynamically
MENU_OPTIONS=()
i=1
for system in "${!SCRAPERS[@]}"; do
    MENU_OPTIONS+=("$i" "$system")
    ((i++))
done

# Main dialog menu
dialog --clear --backtitle "Game System Installer" \
       --title "Select a Game System" \
       --menu "Choose an option:" 15 50 9 \
       "${MENU_OPTIONS[@]}" \
       2>/tmp/game-downloader-choice

choice=$(< /tmp/game-downloader-choice)
rm -f /tmp/game-downloader-choice

# Exit if no choice is made
if [ -z "$choice" ]; then
    dialog --msgbox "No option selected. Exiting." 10 50
    clear
    exit 0
fi

# Map the choice to the selected system
selected_system=$(for key in "${!SCRAPERS[@]}"; do echo "$key"; done | sed -n "${choice}p")

# Validate the selected system
if [ -z "$selected_system" ]; then
    dialog --msgbox "Invalid selection. Please try again." 10 50
    exit 1
fi

# Get the corresponding scraper URL
scraper_url="${SCRAPERS[$selected_system]}"

# Download and run the selected scraper
dialog --infobox "Downloading and running $selected_system scraper..." 10 50
curl -Ls "$scraper_url" -o /tmp/scraper.sh
if [ $? -ne 0 ]; then
    dialog --msgbox "Error: Failed to download the scraper for $selected_system." 10 50
    exit 1
fi

bash /tmp/scraper.sh
if [ $? -ne 0 ]; then
    dialog --msgbox "Error: Failed to execute the scraper for $selected_system." 10 50
    exit 1
fi

# Success message
dialog --msgbox "Installation complete for $selected_system!" 10 50
clear
