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
SCRIPTS=("GMD.sh" "GMD-Updater.sh" "GameDownloader.sh" "psx-scraper.sh" "dc-scraper.sh" "ps2-scraper.sh" "psx-downloader-menu.sh" "dc-downloader-menu.sh" "ps2-downloader-menu.sh")
KEYS=("GMD.sh.keys" "GMD-Updater.sh.keys")

# Remove scripts from Ports directory
for script in "${SCRIPTS[@]:0:2}"; do
    if [[ -f "$PORTS_DIR/$script" ]]; then
        rm "$PORTS_DIR/$script"
        echo "Removed $PORTS_DIR/$script"
    fi
done

# Remove key files from Ports directory
for key in "${KEYS[@]}"; do
    if [[ -f "$PORTS_DIR/$key" ]]; then
        rm "$PORTS_DIR/$key"
        echo "Removed $PORTS_DIR/$key"
    fi
done

# Remove GameDownloader scripts from game-downloader directory
for script in "${SCRIPTS[@]:2}"; do
    if [[ -f "$GMD_DIR/$script" ]]; then
        rm "$GMD_DIR/$script"
        echo "Removed $GMD_DIR/$script"
    fi
done

# Force-remove the game-downloader directory
if [[ -d "$GMD_DIR" ]]; then
    rm -rf "$GMD_DIR" && echo "Removed directory $GMD_DIR"
fi

# Restart EmulationStation to remove the entry in Ports
curl http://127.0.0.1:1234/reloadgames

echo "Uninstallation complete. The Game Downloader app has been removed from Ports."
