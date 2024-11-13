#!/bin/bash

# Directory for the status files
STATUS_DIR="/userdata/system/game-downloader/status"
mkdir -p "$STATUS_DIR"

# Path to the download queue file
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"

# Flag to handle termination signal
terminate_script=false

# Function to handle the stop signal
handle_stop_signal() {
    echo "Stop signal received. Terminating the script..."
    terminate_script=true
}

# Trap SIGTERM to handle batocera-services stop
trap 'handle_stop_signal' SIGTERM

# Function to check for an active internet connection
check_internet() {
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        return 0  # Return 0 if connection is successful
    else
        return 1  # Return 1 if connection fails
    fi
}

# Function to stop the service if there's no internet connection
stop_service() {
    batocera-services stop Background_Game_Downloader
}

# Function to process each download
process_download() {
    local game_name="$1"
    local url="$2"
    local folder="$3"

    # Set the temporary download path
    local temp_path="/tmp/$game_name"  # Save the file temporarily in /tmp

    # Ensure that $game_name doesn't have any extra quotes or backticks
    game_name=$(echo "$game_name" | sed 's/[`"]//g')

    # Start the download using wget without progress bar
    wget -c "$url" -O "$temp_path" >/dev/null 2>&1

    # Check if download was successful
    if [ $? -ne 0 ]; then
        return 1  # Download failed
    else
        # Move the downloaded file to the target folder (now that it's complete)
        mv "$temp_path" "$folder"

        # Remove the processed line from download.txt
        sed -i "/$game_name|/d" "$DOWNLOAD_QUEUE"
        return 0  # Success
    fi
}

# Check for internet connection before proceeding
check_internet
if [ $? -ne 0 ]; then
    # Stop the service if there's no internet
    stop_service
    exit 0  # Exit the script since there's no connection
fi

# Run the script continuously
while [[ "$terminate_script" = false ]]; do
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

# Clean exit message
echo "Script terminated gracefully."
