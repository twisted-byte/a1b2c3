#!/bin/bash

# Display animated title for installer
animate_title() {
    local text="GAME DOWNLOADER V2 INSTALLER"
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
    echo "  This will install the Game Downloader V2 app in Ports."
    echo
    sleep 3  # Delay for 3 seconds
}

# Function to download files and handle errors
download_file() {
    local url=$1
    local dest=$2
    if ! curl -L "$url" -o "$dest" >/dev/null 2>&1; then
        dialog --msgbox "Error downloading $url. Please check your network connection or the URL." 7 50
        exit 1
    fi
}

# Create debug directory at the start
mkdir -p /userdata/system/game-downloaderV2/debug >/dev/null 2>&1

# Main execution
clear
animate_title
display_controls

# Download the four files and save them in the Images folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/images/Game%20Downloader%20Wheel.png" "/userdata/roms/ports/images/Game_Downloader_Wheel.png"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/images/Game%20Downloader%20Video.mp4" "/userdata/roms/ports/videos/GameDownloader-video.mp4"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/images/Game%20Downloader%20Icon.png" "/userdata/roms/ports/images/Game_Downloader_Icon.png"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/images/Game%20Download%20Box%20Art.png" "/userdata/roms/ports/images/Game_Downloader_Box_Art.png"

# Download and save download.sh locally (always replace)
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/V2/download.sh" "/userdata/system/services/download.sh"

# Convert download.sh to Unix format and set proper permissions
dos2unix /userdata/system/services/download.sh >/dev/null 2>&1
chmod +x /userdata/system/services/download.sh >/dev/null 2>&1
chmod 777 /userdata/system/services/download.sh >/dev/null 2>&1 

# Rename the file to remove the .sh extension
mv /userdata/system/services/download.sh /userdata/system/services/Background_Game_Downloader >/dev/null 2>&1


# Enable and start the service in the background
batocera-services enable Background_Game_Downloader >/dev/null 2>&1
batocera-services start Background_Game_Downloader &>/dev/null &

# Download GMD.sh and save it as GameDownloader.sh in Ports folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/V2/Display.sh" "/userdata/roms/ports/GameDownloader.sh"

# Make the downloaded GameDownloader.sh executable
chmod +x /userdata/roms/ports/GameDownloader.sh >/dev/null 2>&1

# Define URLs for the scraper scripts
SCRAPER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V2/Scraper.sh"

# Run scraper scripts directly from GitHub
echo "Running scrapers..."
if ! bash <(curl -s "$SCRAPER") >/dev/null 2>&1; then
    dialog --msgbox "Error running scrapers." 7 50
    exit 1
fi

# Download bkeys.txt and save it as GameDownloader.sh.keys in the Ports folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/bkeys.txt" "/userdata/roms/ports/GameDownloader.sh.keys"

# Define the path to the gamelist.xml
GAMELIST="/userdata/roms/ports/gamelist.xml"

# Create a new XML entry to add with additional fields
NEW_ENTRY="<game>
    <path>./GameDownloader.sh</path>
    <name>Game Downloader</name>
    <image>./images/Game_Downloader_Icon.png</image>
    <video>./videos/GameDownloader-video.mp4</video>
    <marquee>./images/Game_Downloader_Wheel.png</marquee>
    <thumbnail>./images/Game_Downloader_Box_Art.png</thumbnail>
    <lang>en</lang>
</game>"

# Append the new entry to the gamelist.xml
echo "$NEW_ENTRY" >> "$GAMELIST" >/dev/null 2>&1

echo "Gamelist.xml has been updated."

echo "Installation complete. Game Downloader should now be available in Ports."
echo "Batocera will initiate the background downloader automatically, you should find a toggle switch for it within Main Menu -> System Settings -> Services."
echo "Rebooting the system for the changes to take effect."
sleep 5
reboot
