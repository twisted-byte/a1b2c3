#!/bin/bash

# Directory where the download status files are stored
STATUS_DIR="/userdata/system/game-downloader/status"
mkdir -p "$STATUS_DIR"

# Function to download a single game with a specific target folder
download_game() {
    local decoded_name="$1"
    local url="$2"
    local folder="$3"
    local file_name="$(basename "$url")"
    local output_path="$folder/$file_name"
    local status_file="$STATUS_DIR/$file_name.status"

    # Log any errors during wget to the debug file
    wget -c "$url" -O "$output_path" --progress=dot 2>&1 | \
    awk '/[0-9]%/ {gsub(/[\.\%]/,""); print $1}' | while read -r progress; do
        echo "$progress" > "$status_file"
    done

    if [ $? -ne 0 ]; then
        echo "Error: Failed to download $url" >> /userdata/system/game-downloader/debug/download-debug.txt
    fi

    echo "100" > "$status_file"  # Mark as complete

    # Check if the downloaded file is a zip and extract it
    if [[ "$file_name" =~ \.zip$ ]]; then
        unzip -o "$output_path" -d "$folder" >> /userdata/system/game-downloader/debug/download-debug.txt 2>&1
        if [ $? -ne 0 ]; then
            echo "Error: Failed to unzip $output_path" >> /userdata/system/game-downloader/debug/download-debug.txt
        fi
        rm "$output_path"
    fi
}

# Constantly check and process new downloads
while true; do
    download_file="/userdata/system/game-downloader/download.txt"

    if [[ -f "$download_file" ]]; then
        while IFS='|' read -r game_name url folder; do
            file_name="$(basename "$url")"

            # Initialize status file
            echo "0" > "$STATUS_DIR/$file_name.status"

            # Download the game in the background and log errors
            nohup bash -c "download_game \"$game_name\" \"$url\" \"$folder\"" >> /userdata/system/game-downloader/debug/download-debug.txt 2>&1 &
            
            # Wait for a short time before checking the next line
            sleep 1
        done < "$download_file"
    fi

    # Wait for a while before re-checking the download file
    sleep 5
done
