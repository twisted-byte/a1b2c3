#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"
DOWNLOAD_DIR="/userdata/roms/psx"  # Update this to your desired download directory
ALLGAMES_FILE="$DEST_DIR/AllGames.txt"  # File containing the full list of games with URLs
DEBUG_LOG="$DEST_DIR/debug.txt"  # Log file to capture debug information

# Ensure the download directory and log file exist
mkdir -p "$DOWNLOAD_DIR"
touch "$DEBUG_LOG"

# Function to log debug messages
log_debug() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$DEBUG_LOG"
}

# Function to show a dialog spinner
show_spinner() {
    (
        echo '0'   # Initial value (0%)
        for i in {1..100}; do
            echo \$i
            sleep 0.1
        done
        echo '100'   # End value (100%)
    ) | dialog --title 'Updating...' --gauge 'Please wait while updating...' 10 70 0
}

# Start the update process in the background
{
    curl -Ls https://bit.ly/bgamedownloader | bash > /dev/null 2>&1
} &

# Show the spinner while the update process is running
show_spinner

# Wait for the background update process to finish
wait

# Notify user when update is complete
dialog --msgbox 'Update Complete!' 10 50
