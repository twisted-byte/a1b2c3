#!/bin/bash

export HOME="/userdata/system/game-downloader"

# Paths to files and logs
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"
DOWNLOAD_PROCESSING="/userdata/system/game-downloader/processing.txt"
DEBUG_LOG="/userdata/system/game-downloader/debug/debug.txt"
LOG_FILE="/userdata/system/game-downloader/download.log"

# Maximum number of parallel downloads
MAX_PARALLEL=3

if [[ "$1" != "start" ]]; then
  exit 0
fi

# Ensure debug directory exists
mkdir -p "$(dirname "$DEBUG_LOG")"

# Clear debug log for a fresh session
if [ -f "$DEBUG_LOG" ]; then
    echo "Clearing debug log for the new session." >> "$DEBUG_LOG"
    > "$DEBUG_LOG"
fi

# Redirect stdout and stderr to debug log
exec > "$DEBUG_LOG" 2>&1

echo "Starting enhanced game downloader script at $(date)"

# Function to check for active internet connection
check_internet() {
    echo "Checking internet connection..."
    if curl -s --head --connect-timeout 5 http://www.google.com | grep "200 OK" > /dev/null; then
        echo "Internet connection is active."
        return 0
    else
        echo "No internet connection found."
        return 1
    fi
}

# Function to update queue files safely
update_queue_file() {
    local file="$1"
    local line_to_exclude="$2"
    awk -v pattern="$line_to_exclude" '!index($0, pattern)' "$file" > temp && mv temp "$file"
}

# Function to validate checksum if available
validate_checksum() {
    local file_path="$1"
    local checksum_file="$2"

    if [ -f "$checksum_file" ]; then
        local expected_checksum
        expected_checksum=$(cat "$checksum_file")
        local actual_checksum
        actual_checksum=$(sha256sum "$file_path" | awk '{print $1}')

        if [[ "$expected_checksum" == "$actual_checksum" ]]; then
            echo "Checksum validation passed for $file_path."
            return 0
        else
            echo "Checksum validation failed for $file_path."
            return 1
        fi
    else
        echo "No checksum file provided. Skipping validation for $file_path."
        return 0
    fi
}

# Function to process individual downloads
process_download() {
    local game_name="$1"
    local url="$2"
    local folder="$3"
    local checksum_file="$4"

    local temp_path="/userdata/system/game-downloader/$game_name"
    mkdir -p "$(dirname "$temp_path")"

    # Mark the download as "downloading"
    sed -i "s|$game_name|$game_name|downloading|" "$DOWNLOAD_PROCESSING"

    # Resume or start download
    echo "Downloading $game_name..."
    wget --tries=5 -c "$url" -O "$temp_path"
    if [ $? -ne 0 ]; then
        echo "Download failed for $game_name. Logging as incomplete."
        sed -i "s|$game_name|$game_name|incomplete|" "$DOWNLOAD_PROCESSING"
        return 1
    fi

    echo "Download completed for $game_name."

    # Validate checksum
    if ! validate_checksum "$temp_path" "$checksum_file"; then
        echo "Invalid checksum for $game_name. Removing file and marking as incomplete."
        rm "$temp_path"
        sed -i "s|$game_name|$game_name|incomplete|" "$DOWNLOAD_PROCESSING"
        return 1
    fi

    # Handle file types
    if [[ "$game_name" == *.zip ]]; then
        process_unzip "$game_name" "$temp_path" "$folder"
    elif [[ "$game_name" == *.chd || "$game_name" == *.iso ]]; then
        echo "Moving $game_name to $folder."
        mv "$temp_path" "$folder"
    else
        echo "Unsupported file type for $game_name. Skipping."
        rm "$temp_path"
    fi

    # Mark the download as "complete"
    sed -i "s|$game_name|$game_name|complete|" "$DOWNLOAD_PROCESSING"
}

# Function to unzip files
process_unzip() {
    local game_name="$1"
    local temp_path="$2"
    local folder="$3"

    local game_name_no_ext="${game_name%.zip}"
    local game_folder="/userdata/system/game-downloader/$game_name_no_ext"
    mkdir -p "$game_folder"

    echo "Unzipping $game_name..."
    unzip -q "$temp_path" -d "$game_folder"
    if [ $? -ne 0 ]; then
        echo "Unzip failed for $game_name. Removing temporary files."
        rm -rf "$game_folder" "$temp_path"
        return
    fi

    echo "Moving unzipped files to $folder."
    mv "$game_folder" "$folder"
    rm "$temp_path"
}

# Function to requeue incomplete downloads
requeue_incomplete_downloads() {
    echo "Requeuing incomplete downloads..."
    while IFS='|' read -r game_name url folder status; do
        if [[ "$status" == "incomplete" ]]; then
            echo "$game_name|$url|$folder" >> "$DOWNLOAD_QUEUE"
        fi
    done < "$DOWNLOAD_PROCESSING"
    sed -i "/|incomplete/d" "$DOWNLOAD_PROCESSING"
}

# Function to manage parallel downloads
parallel_downloads() {
    local pids=()
    while true; do
        # Requeue incomplete downloads
        requeue_incomplete_downloads

        # Start new downloads if available
        if [[ -f "$DOWNLOAD_QUEUE" && -s "$DOWNLOAD_QUEUE" ]]; then
            while IFS='|' read -r game_name url folder; do
                while [[ ${#pids[@]} -ge $MAX_PARALLEL ]]; do
                    wait -n
                    pids=($(jobs -rp))
                done

                # Log and start download
                echo "$game_name|$url|$folder|incomplete" >> "$DOWNLOAD_PROCESSING"
                update_queue_file "$DOWNLOAD_QUEUE" "$game_name|$url|$folder"
                process_download "$game_name" "$url" "$folder" &
                pids+=($!)
            done < "$DOWNLOAD_QUEUE"
        fi

        # Clean up completed processes
        pids=($(jobs -rp))
        sleep 5
    done
}

# Continuous monitoring loop
check_internet
if [ $? -ne 0 ]; then
    echo "No internet connection. Exiting."
    exit 1
fi

echo "Monitoring download queue..."
parallel_downloads
