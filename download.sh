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

    # Download the file with progress and update the status file with percentage
    wget -c "$url" -O "$output_path" --progress=dot 2>&1 | \
    awk '/[0-9]+%/ {gsub(/[^\x0-9%]/, ""); print $1}' | while read -r progress; do
        echo "$progress" > "$status_file"
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