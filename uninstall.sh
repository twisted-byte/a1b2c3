#!/bin/bash

# Function to display log messages with timestamp
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

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

# Stop and disable the service directly
log "Disabling and stopping the Background_Game_Downloader service..."
batocera-services disable Background_Game_Downloader > /dev/null 2>&1
batocera-services stop Background_Game_Downloader > /dev/null 2>&1
log "Service Background_Game_Downloader disabled and stopped."

# Remove the game-downloader directory
log "Checking for game-downloader directory at $GMD_DIR..."
if [[ -d "$GMD_DIR" ]]; then
    rm -rf "$GMD_DIR" && log "Removed directory $GMD_DIR"
else
    log "Directory $GMD_DIR not found."
fi

# Remove GameDownloader.sh and GameDownloader.sh.keys from Ports
log "Checking for $GAME_DOWNLOADER_SH in Ports..."
if [[ -f "$GAME_DOWNLOADER_SH" ]]; then
    rm "$GAME_DOWNLOADER_SH" && log "Removed $GAME_DOWNLOADER_SH"
else
    log "$GAME_DOWNLOADER_SH not found."
fi

log "Checking for $GAME_DOWNLOADER_KEYS in Ports..."
if [[ -f "$GAME_DOWNLOADER_KEYS" ]]; then
    rm "$GAME_DOWNLOADER_KEYS" && log "Removed $GAME_DOWNLOADER_KEYS"
else
    log "$GAME_DOWNLOADER_KEYS not found."
fi

# Remove Background_Game_Downloader service file if it exists
log "Checking for Background_Game_Downloader service file..."
if [[ -f "$BG_DOWNLOADER_SERVICE" ]]; then
    rm "$BG_DOWNLOADER_SERVICE" && log "Removed $BG_DOWNLOADER_SERVICE"
else
    log "$BG_DOWNLOADER_SERVICE not found."
fi

# Restart EmulationStation to remove the entry in Ports
log "Reloading game entries in EmulationStation..."
curl -s http://127.0.0.1:1234/reloadgames && log "Game entries reloaded." || log "Failed to reload game entries."

log "Uninstallation complete. The Game Downloader app has been removed from Ports."
