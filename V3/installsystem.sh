#!/bin/bash

# Define the debug log location
DEBUG_LOG="/userdata/system/game-downloader/debug/install_debug.txt"

# Create the debug directory if it doesn't exist
mkdir -p "$(dirname "$DEBUG_LOG")"

# Redirect all output (stdout and stderr) to the debug log and terminal
exec > >(tee -a "$DEBUG_LOG") 2>&1

# Check for necessary tools
for cmd in curl bash; do
    if ! command -v $cmd &>/dev/null; then
        echo "Error: $cmd is not installed. Please install it and try again."
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
    echo "Error: No scrapers found. Check the script configuration."
    exit 1
fi

# Display menu options
echo "Select a Game System to install:"
i=1
MENU_OPTIONS=()
for system in "${!SCRAPERS[@]}"; do
    echo "[$i] $system"
    MENU_OPTIONS+=("$system")
    ((i++))
done

# Get user choice
read -p "Enter the number of your choice: " choice

# Validate user input
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#MENU_OPTIONS[@]}" ]; then
    echo "Invalid choice. Exiting."
    exit 1
fi

# Map choice to selected system
selected_system="${MENU_OPTIONS[$((choice - 1))]}"
scraper_url="${SCRAPERS[$selected_system]}"

echo "You selected: $selected_system"
echo "Downloading and running the scraper for $selected_system..."

# Download and execute the scraper
curl -Ls "$scraper_url" -o /tmp/scraper.sh
if [ $? -ne 0 ]; then
    echo "Error: Failed to download the scraper for $selected_system."
    exit 1
fi

bash /tmp/scraper.sh
if [ $? -ne 0 ]; then
    echo "Error: Failed to execute the scraper for $selected_system."
    exit 1
fi

# Success message
echo "Installation complete for $selected_system!"
