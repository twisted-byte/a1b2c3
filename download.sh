#!/bin/bash

# Path to the download queue file
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"

# Function to check for an active internet connection
check_internet() {
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        return 0  # Return 0 if connection is successful
    else
        return 1  # Return 1 if connection fails
    fi
}

# Function to process each download
process_download() {
    local game_name="$1"
    local url="$2"
    local folder="$3"

    # Set the temporary download path
    local temp_path="/userdata/system/game-downloader/$game_name"  # Save the file temporarily

    # Ensure that $game_name doesn't have any extra quotes or backticks
    game_name=$(echo "$game_name" | sed 's/["]//g')

    # Start the download using wget without progress bar
    wget -c "$url" -O "$temp_path" >/dev/null 2>&1

    # Check if download was successful
    if [ $? -ne 0 ]; then
        return 1  # Download failed
    else
        # Check if the file is a .zip
        if [[ "$temp_path" == *.zip ]]; then
            # Create a temporary folder named after the game
            local game_folder="/userdata/system/game-downloader/$game_name"
            mkdir -p "$game_folder"

            # Unzip the downloaded file into the temporary folder
            unzip -q "$temp_path" -d "$game_folder"

            # Check if the unzip was successful
            if [ $? -ne 0 ]; then
                return 1  # Unzip failed
            fi

            # Move the entire folder to the target folder
            mv "$game_folder" "$folder"
        else
            # If it's not a .zip, just move the downloaded file directly
            mv "$temp_path" "$folder"
        fi

        # Remove the processed line from download.txt
        sed -i "/$game_name|/d" "$DOWNLOAD_QUEUE"
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
    # Check if download.txt exists and has content
    if [[ -f "$DOWNLOAD_QUEUE" ]]; then
        # Process each line in download.txt
        while IFS='|' read -r game_name url folder; do
            # Start the download and wait for completion
            process_download "$game_name" "$url" "$folder"
        done < "$DOWNLOAD_QUEUE"
    fi

    # Wait for a while before checking again for new downloads
    sleep 5
done
