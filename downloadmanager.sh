#!/bin/bash

# Set paths
DOWNLOAD_FILE="/userdata/system/game-downloader/download.txt"
DOWNLOAD_DIR="/userdata/roms/ps2"
TEMP_DIR="/tmp/ps2_download"
STATUS_FILE="/tmp/download_status.txt"  # Temporary file for tracking download status

# Ensure necessary directories exist
mkdir -p "$DOWNLOAD_DIR" "$TEMP_DIR"

# Prepare download status file
: > "$STATUS_FILE"

# Display initial loading screen
dialog --infobox "Loading download queue..." 5 50
sleep 1

# Check if download list exists
if [[ ! -f "$DOWNLOAD_FILE" ]]; then
    dialog --msgbox "Error: download.txt not found!" 10 50
    exit 1
fi

# Read download links into an array
mapfile -t downloads < "$DOWNLOAD_FILE"
total_downloads=${#downloads[@]}

# Function to download a single game
download_game() {
    local url="$1"
    local file_name="$(basename "$url")"
    local output_path="$TEMP_DIR/$file_name"

    # Begin download and track with progress bar
    wget -c "$url" -O "$output_path" --progress=dot 2>&1 | \
    awk '/[0-9]%/ {gsub(/[\.\%]/,""); print $1}' | while read -r progress; do
        echo "$progress" > "$STATUS_FILE.$file_name"
    done

    # Move completed file to download directory
    mv "$output_path" "$DOWNLOAD_DIR"
    echo "100" > "$STATUS_FILE.$file_name"  # Mark as complete
}

# Start downloads concurrently and display progress
for url in "${downloads[@]}"; do
    file_name="$(basename "$url")"
    echo "0" > "$STATUS_FILE.$file_name"  # Initialize progress

    # Download in the background with nohup
    nohup bash -c "download_game \"$url\"" &>/dev/null &
done

# Monitor progress
(
    while :; do
        clear
        # Gather progress of each download
        echo "Downloading games..."
        for url in "${downloads[@]}"; do
            file_name="$(basename "$url")"
            progress=$(cat "$STATUS_FILE.$file_name" 2>/dev/null || echo "0")
            echo "$file_name ($progress%)"
        done
        sleep 1
    done
) | dialog --title "Download Manager" --programbox "Download progress:" 20 70

# Final cleanup and notification
dialog --msgbox "All downloads complete!" 10 50
rm -f "$STATUS_FILE"*  # Remove temporary status files
clear
