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
}

# Read download links from file and start concurrent downloads
start_downloads() {
    local download_file="$1"
    
    # Read URLs from the provided file and derive the folder dynamically
    while IFS='|' read -r game_name url folder; do
        file_name="$(basename "$url")"  # Extract the file name from URL
        
        # Display the game name in the download manager
        echo "$game_name"
        
        # Initialize progress status file
        echo "0" > "$STATUS_DIR/$file_name.status"
        
        # Download the game in the background and store in the target folder
        nohup bash -c "wget -c \"$url\" -O \"$folder/$file_name\" --progress=dot 2>&1 | \
                        awk '/[0-9]%/ {gsub(/[\.\%]/,\"\"); print \$1}' | while read -r progress; do \
                        echo \$progress > \"$STATUS_DIR/$file_name.status\"; done" &>/dev/null &
    done < "$download_file"
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
                decoded_name=$(grep -F "$file_name" "$download_file" | cut -d '|' -f 1)  # Get the decoded name
                progress_text="$progress_text$decoded_name: $progress%\n"
                any_progress=true
            fi
        done

        # If there's ongoing downloads, show progress
        if $any_progress; then
            dialog --clear --title "Download Progress" --msgbox "$progress_text" 15 50
        else
            # Show a message when no downloads are active, with a Cancel button
            dialog --clear --title "Download Progress" --msgbox "Nothing downloading currently!" 10 50
            break
        fi
        sleep 2  # Refresh every 2 seconds
    done

}

# Main entry: specify download file
download_file="/userdata/system/game-downloader/download.txt"

# Start downloads and show progress
start_downloads "$download_file"
show_download_progress

    # Return to GameDownloader.sh after exit
exec /userdata/system/game-downloader/GameDownloader.sh
  
echo "All downloads complete!"
