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

# Function to download files and handle errors
download_file() {
    local url=$1
    local dest=$2
    if ! curl -L "$url" -o "$dest"; then
        dialog --msgbox "Error downloading $url. Please check your network connection or the URL." 7 50
        exit 1
    fi
}

# Main execution
clear
animate_title
display_controls

# Download and save download.sh locally (always replace)
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/download.sh" "/userdata/system/services/download.sh"

# Convert download.sh to Unix format and set proper permissions
dos2unix /userdata/system/services/download.sh
chmod +x /userdata/system/services/download.sh  # Ensure it's executable
chmod 777 /userdata/system/services/download.sh  # Set read/write/execute permissions

# Rename the file to remove the .sh extension (optional, since you want to avoid .sh)
mv /userdata/system/services/download.sh /userdata/system/services/Background_Game_Downloader

# Ensure the script is executable
chmod +x /userdata/system/services/Background_Game_Downloader  # Make sure the service script is executable

# Enable and start the service
batocera-services enable Background_Game_Downloader
batocera-services start Background_Game_Downloader

# Download GMD.sh and save it as GameDownloader.sh in Ports folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/GMD.sh" "/userdata/roms/ports/GameDownloader.sh"

# Make the downloaded GameDownloader.sh executable
chmod +x /userdata/roms/ports/GameDownloader.sh

# Define URLs for the scraper scripts
PSX_SCRAPER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-scraper.sh"
DC_SCRAPER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-scraper.sh"
PS2_SCRAPER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/ps2-scraper.sh"

# Run scraper scripts directly from GitHub
echo "Running PSX scraper..."
if ! bash <(curl -s "$PSX_SCRAPER") >/dev/null 2>&1; then
    dialog --msgbox "Error running PSX scraper." 7 50
    exit 1
fi

echo "Running Dreamcast scraper..."
if ! bash <(curl -s "$DC_SCRAPER") >/dev/null 2>&1; then
    dialog --msgbox "Error running Dreamcast scraper." 7 50
    exit 1
fi

echo "Running PS2 scraper..."
if ! bash <(curl -s "$PS2_SCRAPER") >/dev/null 2>&1; then
    dialog --msgbox "Error running PS2 scraper." 7 50
    exit 1
fi

# Download bkeys.txt and save it as GameDownloader.sh.keys in the Ports folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/bkeys.txt" "/userdata/roms/ports/GameDownloader.sh.keys"

echo "Installation complete. 'Game Downloader' should now be available in Ports."
echo "Batocera will initiate the background downloader automatically, you should find a toggle switch for it within Main Menu -> System Settings -> Services."