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
    if ! curl -L "$url" -o "$dest" >/dev/null 2>&1; then
        dialog --msgbox "Error downloading $url. Please check your network connection or the URL." 7 50
        exit 1
    fi
}

# Create all necessary directories
mkdir -p /userdata/system/game-downloader/debug >/dev/null 2>&1
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
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/videos/Game%20Downloader%20Video.mp4" "/userdata/roms/ports/videos/GameDownloader-video.mp4"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/images/Game%20Downloader%20Icon.png" "/userdata/roms/ports/images/Game_Downloader_Icon.png"
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/images/Game%20Download%20Box%20Art.png" "/userdata/roms/ports/images/Game_Downloader_Box_Art.png"
# Download and save download.sh locally (always replace)
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/download.sh" "/userdata/system/services/download.sh"
# Convert download.sh to Unix format and set proper permissions
dos2unix /userdata/system/services/download.sh >/dev/null 2>&1
chmod +x /userdata/system/services/download.sh >/dev/null 2>&1
chmod 777 /userdata/system/services/download.sh >/dev/null 2>&1 

# Rename the file to remove the .sh extension
mv /userdata/system/services/download.sh /userdata/system/services/Background_Game_Downloader >/dev/null 2>&1

# Ensure the script is executable
chmod +x /userdata/system/services/Background_Game_Downloader >/dev/null 2>&1

# Enable and start the service in the background
batocera-services enable Background_Game_Downloader >/dev/null 2>&1
batocera-services start Background_Game_Downloader &>/dev/null &

# Download GMD.sh and save it as GameDownloader.sh in Ports folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/Display.sh" "/userdata/roms/ports/GameDownloader.sh"

# Make the downloaded GameDownloader.sh executable
chmod +x /userdata/roms/ports/GameDownloader.sh >/dev/null 2>&1

# Download bkeys.txt and save it as GameDownloader.sh.keys in the Ports folder
download_file "https://raw.githubusercontent.com/DTJW92/game-downloader/main/bkeys.txt" "/userdata/roms/ports/GameDownloader.sh.keys"

# Refresh Batocera games list via localhost
echo "Refreshing Batocera games list using localhost..."
curl -X POST http://localhost:1234/reloadgames >/dev/null 2>&1

# Ensure the gamelist.xml file exists with basic XML structure if it doesn't
if [[ ! -f "$GAMELIST" || ! -s "$GAMELIST" ]]; then
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><gamelist></gamelist>" > "$GAMELIST"
fi

# New game entry to add
NEW_ENTRY="<game>
    <path>./GameDownloader.sh</path>
    <name>Game Downloader</name>
    <image>./images/Game_Downloader_Icon.png</image>
    <video>./videos/GameDownloader-video.mp4</video>
    <marquee>./images/Game_Downloader_Wheel.png</marquee>
    <thumbnail>./images/Game_Downloader_Box_Art.png</thumbnail>
    <lang>en</lang>
</game>"
# Check if the game entry already exists in gamelist.xml
if grep -q "<path>./GameDownloader.sh</path>" "$GAMELIST"; then
    # Replace the existing entry based on path
    sed -i "/<path>\\.\\/GameDownloader\\.sh<\\/path>/,/<\\/game>/c\\
$NEW_ENTRY" "$GAMELIST"
    echo "Replaced existing entry for Game Downloader based on path."
else
    # Append the new entry right before the closing </gamelist> tag if it exists
    if grep -q "</gamelist>" "$GAMELIST"; then
        sed -i "s|</gamelist>|$NEW_ENTRY\n</gamelist>|" "$GAMELIST"
        echo "Appended new 'Game Downloader' entry before closing </gamelist>."
    else
        # If no </gamelist> tag is found (e.g., malformed file), we force a clean structure
        echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?><gamelist>$NEW_ENTRY</gamelist>" > "$GAMELIST"
        echo "Created new gamelist.xml with 'Game Downloader' entry."
    fi
fi

# Refresh Batocera games list via localhost
curl -X POST http://localhost:1234/reloadgames >/dev/null 2>&1
echo "Game list has been updated."
