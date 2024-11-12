#!/bin/bash

# Directory where the download status files are stored
STATUS_DIR="/userdata/system/game-downloader/status"
mkdir -p "$STATUS_DIR"

# Function to download a single game with a specific target folder
download_game() {
    local decoded_name="$1"
    local url="$2"
    local folder="$3"  # Folder passed from the caller
    local file_name="$(basename "$url")"
    local output_path="$folder/$file_name"
    local status_file="$STATUS_DIR/$file_name.status"
    local game_entry="$decoded_name|$url|$folder"

    # Start download and update progress
    wget -c "$url" -O "$output_path" --progress=dot 2>&1 | \
    awk '/[0-9]%/ {gsub(/[\.\%]/,""); print $1}' | while read -r progress; do
        echo "$progress" > "$status_file"
    done

    # Mark as complete
    echo "100" > "$status_file"  # Mark as complete

    # Check if the downloaded file is a zip and extract it
    if [[ "$file_name" =~ \.zip$ ]]; then
        unzip -o "$output_path" -d "$folder"
        rm "$output_path"  # Remove the zip file after extraction
    fi

    # Remove the entry from download.txt
    sed -i "\|$game_entry|d" "/userdata/system/game-downloader/download.txt"

    # Delete the status file
    rm -f "$status_file"
}

# Read download links from file and start concurrent downloads
start_downloads() {
    local download_file="$1"
    
    # Read URLs from the provided file and derive the folder dynamically
    while IFS='|' read -r game_name url folder; do
        file_name="$(basename "$url")"  # Extract the file name from URL
        
        # Initialize progress status file
        echo "0" > "$STATUS_DIR/$file_name.status"
        
        # Download the game in the background and store in the target folder
        nohup bash -c "download_game \"$game_name\" \"$url\" \"$folder\"" &>/dev/null &
    done < "$download_file"
}

# Main entry: specify download file
download_file="/userdata/system/game-downloader/download.txt"

# Start downloads
start_downloads "$download_file"
