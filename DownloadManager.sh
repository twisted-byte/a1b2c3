#!/bin/bash

# Directory where the download status files are stored
STATUS_DIR="/userdata/system/game-downloader/status"
mkdir -p "$STATUS_DIR"
echo "DEBUG: STATUS_DIR is set to $STATUS_DIR" >> /userdata/system/game-downloader/debug.log

# Function to download a single game with a specific target folder
download_game() {
    local decoded_name="$1"
    local url="$2"
    local folder="$3"
    local file_name="$(basename "$url")"
    local output_path="$folder/$file_name"
    local status_file="$STATUS_DIR/$file_name.status"
    
    echo "DEBUG: Starting download for $file_name from $url" >> /userdata/system/game-downloader/debug.log

    # Start download and update progress
    wget -c "$url" -O "$output_path" --progress=dot 2>&1 | \
    awk '/[0-9]%/ {gsub(/[\.\%]/,""); print $1}' | while read -r progress; do
        echo "DEBUG: Download progress for $file_name: $progress%" >> /userdata/system/game-downloader/debug.log
        echo "$progress" > "$status_file"
    done

    # Mark as complete
    echo "100" > "$status_file"
    echo "DEBUG: Download completed for $file_name" >> /userdata/system/game-downloader/debug.log

    # Check if the downloaded file is a zip and extract it
    if [[ "$file_name" =~ \.zip$ ]]; then
        echo "DEBUG: Extracting $file_name to $folder" >> /userdata/system/game-downloader/debug.log
        unzip -o "$output_path" -d "$folder"
        rm "$output_path"  # Remove the zip file after extraction
    fi
}

# Read download links from file and start concurrent downloads
start_downloads() {
    local download_file="$1"
    local folder="$2"

    # Read URLs from the provided file
    mapfile -t downloads < "$download_file"

    echo "DEBUG: Starting downloads from $download_file" >> /userdata/system/game-downloader/debug.log
    for entry in "${downloads[@]}"; do
        decoded_name=$(echo "$entry" | cut -d '|' -f 1)
        url=$(echo "$entry" | cut -d '|' -f 2)
        folder=$(echo "$entry" | cut -d '|' -f 3)

        file_name="$(basename "$url")"
        echo "DEBUG: Initializing download status for $file_name" >> /userdata/system/game-downloader/debug.log
        echo "0" > "$STATUS_DIR/$file_name.status"  # Initialize progress status
        nohup bash -c "download_game \"$decoded_name\" \"$url\" \"$folder\"" &>/dev/null &
    done
}

# Function to display download status with Dialog
show_download_progress() {
    while true; do
        clear
        progress_text="Downloading:\n"
        any_progress=false
        # Check the status of all downloads
        for status_file in "$STATUS_DIR"/*.status; do
            if [[ -f "$status_file" ]]; then
                file_name=$(basename "$status_file" .status)
                progress=$(<"$status_file")
                decoded_name=$(grep -F "$file_name" "$download_file" | cut -d '|' -f 1)
                progress_text="$progress_text$decoded_name: $progress%\n"
                any_progress=true
            fi
        done

        if $any_progress; then
            dialog --clear --title "Download Progress" --msgbox "$progress_text" 15 50
        else
            dialog --clear --title "Download Progress" --msgbox "Nothing downloading currently!" 15 50
            break
        fi
        sleep 2
    done
}

# Main entry
download_file="/userdata/system/game-downloader/download.txt"
download_folder="/userdata/roms/ps2"

start_downloads "$download_file" "$download_folder"
show_download_progress

echo "All downloads complete!" >> /userdata/system/game-downloader/debug.log
