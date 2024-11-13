#!/bin/bash

# Display animated title for uninstaller
animate_title() {
    local text="GAME DOWNLOADER UNINSTALLER"
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
    echo "  This will uninstall the Game Downloader app from Ports."
    echo
    sleep 3  # Delay for 3 seconds
}

# Main execution
clear
animate_title
display_controls

# Define directories and files to remove
GMD_DIR="/userdata/system/game-downloader"
PORTS_DIR="/userdata/roms/ports"
SERVICES_DIR="/userdata/system/services"
GAME_DOWNLOADER_SH="$PORTS_DIR/GameDownloader.sh"
GAME_DOWNLOADER_KEYS="$PORTS_DIR/GameDownloader.sh.keys"
BG_DOWNLOADER_SERVICE="$SERVICES_DIR/Background_Game_Downloader"

# Remove the game-downloader directory
if [[ -d "$GMD_DIR" ]]; then
    rm -rf "$GMD_DIR" && echo "Removed directory $GMD_DIR"
fi

# Remove GameDownloader.sh and GameDownloader.sh.keys from Ports
if [[ -f "$GAME_DOWNLOADER_SH" ]]; then
    rm "$GAME_DOWNLOADER_SH"
    echo "Removed $GAME_DOWNLOADER_SH"
fi

if [[ -f "$GAME_DOWNLOADER_KEYS" ]]; then
    rm "$GAME_DOWNLOADER_KEYS"
    echo "Removed $GAME_DOWNLOADER_KEYS"
fi

# Remove Background_Game_Downloader service
if [[ -f "$BG_DOWNLOADER_SERVICE" ]]; then
    rm "$BG_DOWNLOADER_SERVICE"
    echo "Removed $BG_DOWNLOADER_SERVICE"
fi

# Restart EmulationStation to remove the entry in Ports
curl http://127.0.0.1:1234/reloadgames

echo "Uninstallation complete. The Game Downloader app has been removed from Ports."