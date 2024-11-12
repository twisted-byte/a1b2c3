#!/bin/bash

# Use the variables from the original script
BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/dc-chd-zstd-redump/dc-chd-zstd/"
DEST_DIR="/userdata/system/game-downloader/dclinks"
DOWNLOAD_DIR="/userdata/roms/dreamcast"  # Update this to your desired download directory
ALLGAMES_FILE="$DEST_DIR/AllGames.txt"  # File containing the full list of games with URLs
DEBUG_LOG="$DEST_DIR/debug.txt"  # Log file to capture debug information

# Ensure the download directory and log file exist
mkdir -p "$DOWNLOAD_DIR"
touch "$DEBUG_LOG"

# Function to log debug messages
log_debug() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$DEBUG_LOG"
}

# Function to show Dreamcast game download options
show_dc_menu() {
    # Check if the links file exists and is not empty
    if [ ! -s "$ALLGAMES_FILE" ]; then
        dialog --msgbox "No Dreamcast game links found. Please run the scraper first." 6 50
        exit 1
    fi

    # Create menu options from links file
    local menu=()
    local idx=1
    while IFS= read -r line; do
        game_name=$(echo "$line" | cut -d '|' -f 1)
        menu+=("$idx" "$game_name")
        ((idx++))
    done < "$ALLGAMES_FILE"

    # Show dialog menu for game selection
    choice=$(dialog --clear --title "Dreamcast Game Downloader" \
        --menu "Select a Dreamcast game to download:" 15 50 10 "${menu[@]}" \
        3>&1 1>&2 2>&3)

    # If a game is selected, download it
    if [[ -n "$choice" ]]; then
        game_url=$(sed -n "${choice}p" "$ALLGAMES_FILE" | cut -d '|' -f 2-)
        download_dc_game "$game_url"
    fi
}

# Function to download the selected game
download_dc_game() {
    local game_url="$1"
    local file_name=$(basename "$game_url")
    local destination="$DOWNLOAD_DIR/$file_name"

    # Confirm download if the file doesn't exist
    if [ ! -f "$destination" ]; then
        dialog --yesno "Download $file_name?" 6 40
        if [ $? -eq 0 ]; then
            mkdir -p "$DOWNLOAD_DIR"
            log_debug "Starting download: $file_name"
            curl -L "$game_url" -o "$destination" || dialog --msgbox "Download failed!" 6 40
            log_debug "Download completed: $file_name"
        fi
    else
        dialog --msgbox "$file_name already exists." 6 40
    fi
}

# Start the Dreamcast menu loop
while true; do
    show_dc_menu
done
