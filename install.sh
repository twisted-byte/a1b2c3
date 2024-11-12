#!/bin/bash

# Display animated title for installer
animate_title() {
    local text="GAME DOWNLOADER INSTALLER"
    local delay=0.03
    local length=${#text}
    for (( i=0; i<length; i++ )); do
        echo -n "${text:i:1}"
        sleep $delay
    done
    echo
}

# Function to display controls
display_controls() {
    echo
    echo "  This will install the Game Downloader app in Ports."
    echo
    sleep 3  # Delay for 3 seconds
}

# Main execution
clear
animate_title
display_controls

# Download and save GameDownloader.sh locally in the Ports folder
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/GMD.sh" -o /userdata/roms/ports/GameDownloader.sh
chmod +x /userdata/roms/ports/GameDownloader.sh

# Define URLs for the scraper scripts
PSX_SCRAPER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-scraper.sh"
DC_SCRAPER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-scraper.sh"
PS2_SCRAPER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/ps2-scraper.sh"

# Run scraper scripts directly from GitHub
echo "Running PSX scraper..."
bash <(curl -s "$PSX_SCRAPER")

echo "Running Dreamcast scraper..."
bash <(curl -s "$DC_SCRAPER")

echo "Running PS2 scraper..."
bash <(curl -s "$PS2_SCRAPER")

# Reload games to reflect changes
curl http://127.0.0.1:1234/reloadgames &> /dev/null

echo "Installation complete. 'Game Downloader' should now be available in Ports."
