#!/bin/bash

# Path to the debug log file
DEBUG_LOG="/userdata/system/game-downloader/debug/download_debug.txt"

# Log all outputs for debugging
exec > >(tee -i "$DEBUG_LOG")
exec 2>&1

# Directory for the status files
STATUS_DIR="/userdata/system/game-downloader/status"
mkdir -p "$STATUS_DIR"

# Path to the download queue file
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"

# Log the start of the script
echo "Starting download.sh script at $(date)"

# Max number of concurrent background jobs
MAX_JOBS=3
current_jobs=0

# Function to check for an active internet connection
check_internet() {
    echo "Checking for an internet connection..."
    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        echo "Internet connection is active."
        return 0  # Return 0 if connection is successful
    else
        echo "No internet connection detected. Stopping the service..."
        return 1  # Return 1 if connection fails
    fi
}

# Function to stop the service if there's no internet connection
stop_service() {
    echo "Stopping game downloader service due to no internet connection."
    batocera-services stop download
}

# Function to process each download
process_download() {
    local game_name="$1"
    local url="$2"
    local folder="$3"

    # Set the status file path (using game_name as the file name)
    local status_file="$STATUS_DIR/$game_name.status"

    # Log initial status
    echo "Starting download for $game_name from $url" >> "$DEBUG_LOG"

    # Use the game name as the file name for saving the downloaded file
    local output_path="$folder/$game_name"  # Save the file using the game_name as the filename

    # Start the download using wget with progress bar
    wget -c "$url" -O "$output_path" --progress=bar:force 2>&1 | \
    while IFS= read -r line; do
        # Extract the percentage progress from wget's output
        progress=$(echo "$line" | grep -oP '\d+(?=%)')

        # If we successfully get the progress, update the status file
        if [[ -n "$progress" ]]; then
            echo "$progress" > "$status_file"  # Update the status file with current progress
        fi
    done

    # Check if download was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download $url" >> "$DEBUG_LOG"
    else
        # Mark download as complete
        echo "100" > "$status_file"

        # Move the downloaded file to the target folder (already saved with the correct name)
        mv "$output_path" "$folder"

        # Delete the status file once download is complete
        rm -f "$status_file"

        # Remove the processed line from download.txt
        sed -i "/$game_name|/d" "$DOWNLOAD_QUEUE"
    fi
}

# Wait until the number of background jobs is less than MAX_JOBS
wait_for_free_slot() {
    while [ "$current_jobs" -ge "$MAX_JOBS" ]; do
        sleep 1  # Wait for 1 second before checking again
    done
}

# Check for internet connection before proceeding
check_internet
if [ $? -ne 0 ]; then
    # Stop the service if there's no internet
    stop_service
    echo "$(date) - No internet connection. The script will now stop." >> "$DEBUG_LOG"
    exit 0  # Exit the script since there's no connection
fi

# Run the script continuously
while true; do
    # Check if download.txt exists and has content
    if [[ -f "$DOWNLOAD_QUEUE" ]]; then
        # Process each line in download.txt
        while IFS='|' read -r game_name url folder; do
            wait_for_free_slot  # Wait for a free slot for a background job

            # Start the download in the background
            process_download "$game_name" "$url" "$folder" &

            # Increment the background job count
            ((current_jobs++))

            # Monitor background jobs and decrease count when one finishes
            wait -n
            ((current_jobs--))
        done < "$DOWNLOAD_QUEUE"
    fi

    # Wait for a while before checking again for new downloads
    echo "$(date) - Waiting for new downloads..." >> "$DEBUG_LOG"
    sleep 5
done

# Log the end of the script
echo "download.sh completed at $(date)" >> "$DEBUG_LOG"