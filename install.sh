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

# Download and save download.sh locally in the Game Downloader folder (always replace)
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/download.sh" "/userdata/system/game-downloader/download.sh"
chmod +x /userdata/system/game-downloader/download.sh

# Convert download.sh to Unix format and set proper permissions
dos2unix /userdata/system/game-downloader/download.sh
chmod 777 /userdata/system/game-downloader/download.sh

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

# Ensure custom.sh exists
if [ ! -f /userdata/system/custom.sh ]; then
    touch /userdata/system/custom.sh
fi

# Check if the line already exists in custom.sh
if ! grep -q "/userdata/system/game-downloader/download.sh &" /userdata/system/custom.sh; then
    # Append the location of download.sh to custom.sh with & for background execution
    echo "/userdata/system/game-downloader/download.sh &" >> /userdata/system/custom.sh
else
    echo "Line already exists in custom.sh, skipping append."
fi

echo "Installation complete. 'Game Downloader' should now be available in Ports. Batocera will need to reboot to initiate the background downloader."

# Confirm with the user before rebooting
dialog --title "Reboot Now?" --yesno "Batocera needs to reboot to initiate the background downloader, would you like to reboot Batocera now?" 7 50
if [ $? -eq 0 ]; then
    reboot  # Reboot command with sudo for Batocera
else
    echo "You can manually reboot later to complete the setup."
fi
