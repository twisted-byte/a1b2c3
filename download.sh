#!/bin/bash

# Path to the download queue file
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"
DEBUG_LOG="/userdata/system/game-downloader/debug/debug.txt"

# Ensure the debug directory exists
mkdir -p "$(dirname "$DEBUG_LOG")"

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

# Function to process each download
process_download() {
    local game_name="$1"
    local url="$2"
    local folder="$3"

    # Log the download attempt
    echo "Processing download for game: $game_name"
    echo "URL: $url"
    echo "Target folder: $folder"

    # Set the temporary download path
    local temp_path="/userdata/system/game-downloader/$game_name"  # Save the file temporarily

    # Ensure that $game_name doesn't have any extra quotes or backticks
    game_name=$(echo "$game_name" | sed 's/["]//g')

    # Start the download using wget without progress bar
    wget -c "$url" -O "$temp_path" >/dev/null 2>&1
    local wget_exit_code=$?
    echo "wget exit code: $wget_exit_code"

    # Check if download was successful
    if [ $wget_exit_code -ne 0 ]; then
        echo "Download failed for $game_name"
        return 1  # Download failed
    else
        echo "Download succeeded for $game_name"

        # Check if the file is a .zip
        if [[ "$temp_path" == *.zip ]]; then
            echo "File is a zip, proceeding to unzip."

            # Remove .zip extension from game_name for folder creation if present
            game_name_no_ext="${game_name%.zip}"

            # Create a temporary folder named after the game without the .zip extension
            local game_folder="/userdata/system/game-downloader/$game_name_no_ext"
            mkdir -p "$game_folder"

            # Unzip the downloaded file into the temporary folder
            unzip -q "$temp_path" -d "$game_folder"
            local unzip_exit_code=$?
            echo "unzip exit code: $unzip_exit_code"

            # Check if the unzip was successful
            if [ $unzip_exit_code -ne 0 ]; then
                echo "Unzip failed for $game_name"
                return 1  # Unzip failed
            fi

            # Move the entire folder to the target folder
            mv "$game_folder" "$folder"
            echo "Moved unzipped files for $game_name to $folder"
        else
            # If it's not a .zip, just move the downloaded file directly
            mv "$temp_path" "$folder"
            echo "Moved downloaded file for $game_name to $folder"
        fi

        # Remove the processed line from download.txt
        sed -i "/$game_name|/d" "$DOWNLOAD_QUEUE"
        echo "Removed $game_name from download queue"
        return 0  # Success
    fi
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

    # Check if download.txt exists and has content
    if [[ -f "$DOWNLOAD_QUEUE" ]]; then
        # Process each line in download.txt
        while IFS='|' read -r game_name url folder; do
            echo "Reading download entry: $game_name | $url | $folder"
            
            # Start the download and wait for completion
            process_download "$game_name" "$url" "$folder"
        done < "$DOWNLOAD_QUEUE"
    else
        echo "No downloads found in queue."
    fi

    # Wait for a while before checking again for new downloads
    sleep 5
done