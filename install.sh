#!/bin/bash

# Get the machine hardware name
architecture=$(uname -m)

# Check if the architecture is x86_64 (AMD/Intel)
if [ "$architecture" != "x86_64" ]; then
    echo "This script only runs on AMD or Intel (x86_64) CPUs, not on $architecture."
    exit 1
fi

# Function to display animated title
animate_title() {
    local text="BATOCERA GAME DOWNLOADER INSTALLER"
    local delay=0.1
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
    echo "  This Will install the Game Downloader Menu with PSX and Dreamcast Downloaders to /userdata/roms/ports."
    echo    
    sleep 5  # Delay for 5 seconds
}

# Main script execution
clear
animate_title
display_controls

# Check if /userdata/roms/ports exists and create it if necessary
if [ ! -d "/userdata/roms/ports" ]; then
    mkdir -p /userdata/roms/ports
fi

# Check if /userdata/system/game-downloader exists and create it if necessary
if [ ! -d "/userdata/system/game-downloader" ]; then
    mkdir -p /userdata/system/game-downloader
fi

# Download the main game downloader menu script (renamed to GameDownloader.sh)
curl -L https://github.com/DTJW92/game-downloader/raw/main/GameDownloader.sh -o /userdata/roms/ports/GameDownloader.sh

# Download PSX downloader menu script
curl -L https://github.com/DTJW92/game-downloader/raw/main/psx-downloader-menu.sh -o /userdata/system/game-downloader/psx-downloader-menu.sh

# Download Dreamcast downloader menu script
curl -L https://github.com/DTJW92/game-downloader/raw/main/dc-downloader-menu.sh -o /userdata/system/game-downloader/dc-downloader-menu.sh

# Set execute permissions for the downloaded scripts
chmod +x /userdata/roms/ports/GameDownloader.sh
chmod +x /userdata/system/game-downloader/psx-downloader-menu.sh
chmod +x /userdata/system/game-downloader/dc-downloader-menu.sh

# Check if /userdata/roms/dreamcast exists and create it if necessary
if [ ! -d "/userdata/roms/dreamcast" ]; then
    mkdir -p /userdata/roms/dreamcast
fi

# Check if /userdata/roms/psx exists and create it if necessary
if [ ! -d "/userdata/roms/psx" ]; then
    mkdir -p /userdata/roms/psx
fi

# Download the Dreamcast and PSX scraper scripts (if applicable)
curl -L https://github.com/DTJW92/game-downloader/raw/main/dc-scraper.sh -o /userdata/system/game-downloader/dc-scraper.sh
curl -L https://github.com/DTJW92/game-downloader/raw/main/psx-scraper.sh -o /userdata/system/game-downloader/psx-scraper.sh

# Set execute permissions for the scraper scripts
chmod +x /userdata/system/game-downloader/dc-scraper.sh
chmod +x /userdata/system/game-downloader/psx-scraper.sh

# Run the scraper scripts for PSX and Dreamcast (if desired)
echo "Running PSX scraper script..."
/userdata/system/game-downloader/psx-scraper.sh

echo "Running Dreamcast scraper script..."
/userdata/system/game-downloader/dc-scraper.sh

# Confirm installation complete
echo "Installation complete! You can now use the Game Downloader menu from /userdata/roms/ports/GameDownloader.sh"
