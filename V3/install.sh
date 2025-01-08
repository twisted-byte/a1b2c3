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

    # Create the directory if it doesn't exist
    mkdir -p "$(dirname "$dest")" >/dev/null 2>&1

    # Attempt to download the file
    if ! curl -L "$url" -o "$dest" >/dev/null 2>&1 || [ ! -f "$dest" ]; then
        dialog --msgbox "Error downloading $url. Please check your network connection or the URL." 7 50
        exit 1
    fi
}

# Create all necessary directories
mkdir -p /userdata/system/game-downloader/debug \
         /userdata/roms/ports/images \
         /userdata/roms/ports/videos \
         /userdata/system/services \
         /userdata/roms/ports

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
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/videos/Game%20Downloader%20Video.mp4" "/userdata/roms/ports/videos/GameDownloader-video.mp4"
download_file "https://github.com/DTJW92/game-downloader/raw/main/images/bgd-logo.png" "/userdata/roms/ports/images/Game_Downloader_Icon.png"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/images/Game%20Download%20Box%20Art.png" "/userdata/roms/ports/images/Game_Downloader_Box_Art.png"

# Download and save download.sh locally (always replace)
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/download.sh" "/userdata/system/game-downloader/download.sh"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/Background_Game_Downloader" "/userdata/system/services/Background_Game_Downloader"

# Convert download.sh to Unix format and set proper permissions
dos2unix /userdata/system/game-downloader/download.sh >/dev/null 2>&1
chmod +x /userdata/system/game-downloader/download.sh >/dev/null 2>&1
chmod 777 /userdata/system/game-downloader/download.sh >/dev/null 2>&1 
dos2unix /userdata/system/services/Background_Game_Downloader >/dev/null 2>&1
chmod +x /userdata/system/services/Background_Game_Downloader >/dev/null 2>&1
chmod 777 /userdata/system/services/Background_Game_Downloader >/dev/null 2>&1 

# Ensure the script is executable
chmod +x /userdata/system/services/Background_Game_Downloader >/dev/null 2>&1

# Enable and start the service in the background
batocera-services enable Background_Game_Downloader >/dev/null 2>&1
batocera-services start Background_Game_Downloader &>/dev/null

# Download GMD.sh and save it as GameDownloader.sh in Ports folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/Display.sh" "/userdata/roms/ports/GameDownloader.sh"

# Make the downloaded GameDownloader.sh executable
chmod +x /userdata/roms/ports/GameDownloader.sh >/dev/null 2>&1

# Download bkeys.txt and save it as GameDownloader.sh.keys in the Ports folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/bkeys.txt" "/userdata/roms/ports/GameDownloader.sh.keys"

# Ensure the gamelist.xml file exists with basic XML structure if it doesn't
if [[ ! -f "$GAMELIST" || ! -s "$GAMELIST" ]]; then
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><gamelist></gamelist>" > "$GAMELIST"
fi

curl -L -o /usr/bin/xmlstarlet https://github.com/DTJW92/batocera-unofficial-addons/raw/refs/heads/main/app/xmlstarlet
chmod +x /usr/bin/xmlstarlet

curl http://127.0.0.1:1234/reloadgames

xmlstarlet ed -s "/gameList" -t elem -n "game" -v "" \
  -s "/gameList/game[last()]" -t elem -n "path" -v "./GameDownloader.sh" \
  -s "/gameList/game[last()]" -t elem -n "name" -v "Game Downloader" \
  -s "/gameList/game[last()]" -t elem -n "image" -v "./images/Game_Downloader_Icon.png" \
  -s "/gameList/game[last()]" -t elem -n "video" -v "./videos/GameDownloader-video.mp4" \
  -s "/gameList/game[last()]" -t elem -n "marquee" -v "./images/Game_Downloader_Wheel.png" \
  -s "/gameList/game[last()]" -t elem -n "thumbnail" -v "./images/Game_Downloader_Box_Art.png" \
  -s "/gameList/game[last()]" -t elem -n "lang" -v "en" \
  /userdata/roms/ports/gamelist.xml > /userdata/roms/ports/gamelist.xml.tmp && mv /userdata/roms/ports/gamelist.xml.tmp /userdata/roms/ports/gamelist.xml



# Refresh Batocera games list via localhost
curl http://127.0.0.1:1234/reloadgames >/dev/null 2>&1
echo "Game list has been updated."
