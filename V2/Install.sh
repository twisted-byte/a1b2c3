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

    # Create the directory if it doesn't exist
    mkdir -p "$(dirname "$dest")" >/dev/null 2>&1

    # Attempt to download the file
    if ! curl -L "$url" -o "$dest" >/dev/null 2>&1; then
        dialog --msgbox "Error downloading $url. Please check your network connection or the URL." 7 50
        exit 1
    fi
}

# Create all necessary directories
mkdir -p /userdata/system/game-downloaderV2/debug >/dev/null 2>&1
mkdir -p /userdata/roms/ports/images >/dev/null 2>&1
mkdir -p /userdata/roms/ports/videos >/dev/null 2>&1
mkdir -p /userdata/system/services >/dev/null 2>&1
mkdir -p /userdata/roms/ports >/dev/null 2>&1

# Define the path to the gamelist.xml
GAMELIST="/userdata/roms/ports/gamelist.xml"

# Ensure the gamelist.xml file exists with basic XML structure if it doesn't
if [[ ! -f "$GAMELIST" ]]; then
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><gameList></gameList>" > "$GAMELIST"
fi

# Main execution
clear
animate_title
display_controls

# Download the four files and save them in the Images folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/images/Game%20Downloader%20Wheel.png" "/userdata/roms/ports/images/Game_Downloader_Wheel.png"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/images/Game%20Downloader%20Video.mp4" "/userdata/roms/ports/videos/GameDownloader-video.mp4"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/images/Game%20Downloader%20Icon.png" "/userdata/roms/ports/images/Game_Downloader_Icon.png"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/images/Game%20Download%20Box%20Art.png" "/userdata/roms/ports/images/Game_Downloader_Box_Art.png"

# Download and save BackgroundDownloader.sh locally (always replace)
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/V2/BackgroundDownloader.sh" "/userdata/system/services/download.sh"

# Convert download.sh to Unix format and set proper permissions
dos2unix /userdata/system/services/download.sh >/dev/null 2>&1
chmod +x /userdata/system/services/download.sh >/dev/null 2>&1
chmod 777 /userdata/system/services/download.sh >/dev/null 2>&1 

# Rename the file to remove the .sh extension
mv /userdata/system/services/download.sh /userdata/system/services/Background_Game_Downloader >/dev/null 2>&1

# Enable and start the service in the background
batocera-services enable Background_Game_Downloader >/dev/null 2>&1
batocera-services start Background_Game_Downloader &>/dev/null &

# Download Launcher and save it as GameDownloaderV2.sh in Ports folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/V2/Launcher.sh" "/userdata/roms/ports/GameDownloaderV2.sh"

# Make the downloaded GameDownloaderV2.sh executable
chmod +x /userdata/roms/ports/GameDownloaderV2.sh >/dev/null 2>&1

# Define URL for the scraper script
SCRAPER="https://raw.githubusercontent.com/DTJW92/game-downloader/main/V2/Scraper.sh"

# Run scraper script directly from GitHub
echo "Running scrapers..."
if ! bash <(curl -s "$SCRAPER") >/dev/null 2>&1; then
    dialog --msgbox "Error running scrapers." 7 50
    exit 1
fi

# Download bkeys.txt and save it as GameDownloaderV2.sh.keys in the Ports folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/V2/Keys.txt" "/userdata/roms/ports/GameDownloaderV2.sh.keys"

# Create a new XML entry to add with additional fields
NEW_ENTRY="<game>
    <path>./GameDownloaderV2.sh</path>
    <name>Game Downloader V2</name>
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