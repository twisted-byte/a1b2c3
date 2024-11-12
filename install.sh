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

# Ensure necessary directories exist
mkdir -p /userdata/system/game-downloader
mkdir -p /userdata/roms/ports

# Download and install the GMD.sh script for Ports
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/GMD.sh" -o /userdata/roms/ports/GMD.sh

# Download the main GameDownloader script
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/GameDownloader.sh" -o /userdata/system/game-downloader/GameDownloader.sh

# Download the DownloadManager.sh script
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/DownloadManager.sh" -o /userdata/system/game-downloader/DownloadManager.sh

# Download the scraper and menu scripts for PSX, Dreamcast, and PS2
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-scraper.sh" -o /userdata/system/game-downloader/psx-scraper.sh
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-scraper.sh" -o /userdata/system/game-downloader/dc-scraper.sh
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/ps2-scraper.sh" -o /userdata/system/game-downloader/ps2-scraper.sh
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-downloader-menu.sh" -o /userdata/system/game-downloader/psx-downloader-menu.sh
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-downloader-menu.sh" -o /userdata/system/game-downloader/dc-downloader-menu.sh
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/ps2-downloader-menu.sh" -o /userdata/system/game-downloader/ps2-downloader-menu.sh

# Download the Updater.sh script and rename it to GMD-Updater in the Ports folder
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/Updater.sh" -o /userdata/roms/ports/GMD-Updater.sh

# Download bkeys.txt and rename it to GMD.sh.keys in the Ports folder
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/bkeys.txt" -o /userdata/roms/ports/GMD.sh.keys

# Duplicate bkeys.txt and rename it to GMD-Updater.sh.keys in the Ports folder
cp /userdata/roms/ports/GMD.sh.keys /userdata/roms/ports/GMD-Updater.sh.keys

# Set execute permissions for all downloaded scripts
chmod +x /userdata/roms/ports/GMD.sh
chmod +x /userdata/system/game-downloader/GameDownloader.sh
chmod +x /userdata/system/game-downloader/DownloadManager.sh  # Added this line
chmod +x /userdata/system/game-downloader/psx-scraper.sh
chmod +x /userdata/system/game-downloader/dc-scraper.sh
chmod +x /userdata/system/game-downloader/ps2-scraper.sh
chmod +x /userdata/system/game-downloader/psx-downloader-menu.sh
chmod +x /userdata/system/game-downloader/dc-downloader-menu.sh
chmod +x /userdata/system/game-downloader/ps2-downloader-menu.sh
chmod +x /userdata/roms/ports/GMD-Updater.sh

# Run the scraper scripts for PSX, Dreamcast, and PS2
echo "Running PSX scraper..."
/userdata/system/game-downloader/psx-scraper.sh

echo "Running Dreamcast scraper..."
/userdata/system/game-downloader/dc-scraper.sh

echo "Running PS2 scraper..."
/userdata/system/game-downloader/ps2-scraper.sh

# Restart EmulationStation to show the new entry in Ports
curl http://127.0.0.1:1234/reloadgames

echo "Installation complete. You should now see 'GMD', 'GMD-Updater', and 'DownloadManager' in Ports."
