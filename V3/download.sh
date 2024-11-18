#!/bin/bash

# Path to the download queue file
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"
DEBUG_LOG="/userdata/system/game-downloader/debug/debug.txt"

# Ensure the debug directory exists
mkdir -p "$(dirname "$DEBUG_LOG")"

if [ -f "$DEBUG_LOG" ]; then
    echo "Clearing debug log for the new session."
    > "$DEBUG_LOG"  # This will clear the file
fi

# Redirect all stdout and stderr to the debug log file
exec > >(tee -a "$DEBUG_LOG") 2>&1

# Log a script start message
echo "Starting game downloader script at $(date)"

# Function to check for an active internet connection
check_internet() {
    echo "Checking internet connection..."
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        echo "Internet connection is active."
        return 0  # Return 0 if connection is successful
    else
        echo "No internet connection found."
        return 1  # Return 1 if connection fails
    fi
}

process_download() {
    local game_name="$1"
    local url="$2"
    local folder="$3"

    game_name=$(echo "$game_name" | sed 's/["]//g')
    local temp_path="/userdata/system/game-downloader/$game_name"

    # Log the line to processing.txt before starting the download
    echo "$game_name|$url|$folder" >> /userdata/system/game-downloader/processing.txt
    echo "Started download for $game_name... Logging to processing.txt"

    # Remove the line from download.txt once it is moved to processing.txt
   grep -v "$game_name|$url|$folder" "$DOWNLOAD_QUEUE" > temp && mv temp "$DOWNLOAD_QUEUE"

    # Start the download with retry logic
    echo "Starting download for $game_name..."
    wget --tries=5 -c "$url" -O "$temp_path" >> "$DEBUG_LOG" 2>&1
    if [ $? -ne 0 ]; then
        echo "Download failed for $game_name. Check debug log for details."
        return
    fi

    echo "Download succeeded for $game_name"
    
    # Check the file extension before unzipping or moving
    if [[ "$game_name" == *.zip ]]; then
        process_unzip "$game_name" "$temp_path" "$folder"
    elif [[ "$game_name" == *.chd || "$game_name" == *.iso ]]; then
        echo "Skipping extraction for $game_name, moving file to destination."
        mv "$temp_path" "$folder"
    else
        # Unsupported file type
        echo "Unsupported file type for $game_name. Skipping."
        rm "$temp_path"  # Clean up the downloaded file
    fi
    # Remove the line from processing.txt after successful processing
    grep -v "$game_name|$url|$folder" /userdata/system/game-downloader/processing.txt > temp && mv temp /userdata/system/game-downloader/processing.txt
}
process_unzip() {
    local game_name="$1"
    local temp_path="$2"
    local folder="$3"

    local game_name_no_ext="${game_name%.zip}"
    local game_folder="/userdata/system/game-downloader/$game_name_no_ext"

    # Check if the directory exists and clean up if necessary
    if [ -d "$game_folder" ]; then
        echo "Directory $game_folder exists. Cleaning up."
        rm -rf "$game_folder"
    fi
    mkdir -p "$game_folder"

    echo "Unzipping $game_name..."
    unzip -q "$temp_path" -d "$game_folder" 
    if [ $? -ne 0 ]; then
        echo "Unzip failed for $game_name"
        return
    fi

    # Move the unzipped files to the target folder
    mv "$game_folder" "$folder"
    echo "Moved unzipped files for $game_name to $folder"

    # Remove the .zip file after successful extraction
    rm "$temp_path"
    echo "Removed .zip file: $temp_path"
}

# Check for internet connection before proceeding
check_internet
if [ $? -ne 0 ]; then
    echo "No internet connection found. Exiting script."
    exit 1  # Exit the script since there's no internet
fi

# Run the script continuously
while true; do
    echo "Checking for new downloads at $(date)"

    # Process each line in download.txt
    if [[ -f "$DOWNLOAD_QUEUE" ]]; then
        while IFS='|' read -r game_name url folder; do
            echo "Reading download entry: $game_name | $url | $folder"

            # Process the download (sequentially)
            process_download "$game_name" "$url" "$folder" &

        done < <(cat "$DOWNLOAD_QUEUE")  # Use a subshell to safely handle the file while reading
    else
        echo "No downloads found in queue."
    fi

    # Wait for a while before checking again for new downloads
    sleep 5
done
