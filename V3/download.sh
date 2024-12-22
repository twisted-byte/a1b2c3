#!/bin/bash

# Paths to files and logs
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"
DOWNLOAD_PROCESSING="/userdata/system/game-downloader/processing.txt"
DEBUG_LOG="/userdata/system/game-downloader/debug/debug.txt"
SERVICE_STATUS_FILE="/userdata/system/game-downloader/downloader_service_status"

# Maximum number of parallel downloads (initial value)
MAX_PARALLEL=3

# Ensure debug directory exists
mkdir -p "$(dirname "$DEBUG_LOG")"

# Clear debug log for a fresh session
if [ -f "$DEBUG_LOG" ]; then
    echo "Clearing debug log for the new session." >> "$DEBUG_LOG"
    > "$DEBUG_LOG"
fi

# Redirect stdout and stderr to debug log
exec > "$DEBUG_LOG" 2>&1

# Log script start
echo "Starting game downloader script at $(date)"

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

# Function to dynamically adjust the number of parallel downloads based on system load
get_dynamic_parallel_limit() {
    # Get the 1-minute load average
    local load=$(awk '{print $1}' /proc/loadavg)
    local cpu_count=$(nproc)  # Number of CPU cores

    # Calculate the dynamic parallel limit
    local limit=$(echo "$cpu_count / $load" | bc -l)

    # Ensure at least one download runs, and cap at a max limit (e.g., 10)
    if (( $(echo "$limit < 1" | bc -l) )); then
        limit=1
    elif (( $(echo "$limit > 10" | bc -l) )); then
        limit=10
    fi

    # Convert to an integer (round down)
    echo "${limit%.*}"
}

# Function to resume downloads
resume_downloads() {
    if [ -f "$DOWNLOAD_PROCESSING" ]; then
        while IFS='|' read -r game_name url folder; do
            # Check if the process is already downloading this file
            if ps aux | grep -F "$url" | grep -v "grep" > /dev/null; then
                echo "Skipping ongoing download for: $url"
                continue
            fi

            # Check if the temporary file exists (indicates a partial download)
            local temp_path="/userdata/system/game-downloader/$game_name"
            if [ -f "$temp_path" ]; then
                echo "Resuming download for $game_name from $url..."
                wget -c "$url" -O "$temp_path"
                if [ $? -eq 0 ]; then
                    echo "Resumed and completed download for $game_name."
                    # Remove entry from processing.txt after successful download
                    update_queue_file "$DOWNLOAD_PROCESSING" "$game_name|$url|$folder"
                    # Proceed with file handling (unzip or move)
                    process_download "$game_name" "$url" "$folder"
                else
                    echo "Failed to resume download for $game_name."
                fi
            fi
        done < "$DOWNLOAD_PROCESSING"
    else
        echo "No downloads to resume in $DOWNLOAD_PROCESSING."
    fi
}

# Start resuming downloads
resume_downloads

process_download() {
    local game_name="$1"
    local url="$2"
    local folder="$3"

    local temp_path="/userdata/system/game-downloader/$game_name"

    mkdir -p "$(dirname "$temp_path")"

    # Start or resume download
    if [ -f "$temp_path" ]; then
        echo "Resuming partial download for $game_name..."
    else
        echo "Starting new download for $game_name..."
    fi

    # Log progress in processing.txt
    echo "$game_name|$url|$folder" >> "$DOWNLOAD_PROCESSING"

    wget --tries=5 -c "$url" -O "$temp_path" >> "$DEBUG_LOG" 2>&1
    if [ $? -ne 0 ]; then
        echo "Download failed for $game_name. Check debug log for details."
        return
    fi

    echo "Download completed for $game_name."

    # Handle the downloaded file
    if [[ "$game_name" == *.zip ]]; then
        process_unzip "$game_name" "$temp_path" "$folder"
    elif [[ "$game_name" == *.chd || "$game_name" == *.iso ]]; then
        mv "$temp_path" "$folder"
        echo "Moved $game_name to $folder."
    else
        echo "Unsupported file type for $game_name. Skipping."
        rm "$temp_path"
    fi

    # Remove entry from processing.txt after successful processing
    update_queue_file "$DOWNLOAD_PROCESSING" "$game_name|$url|$folder"
}

# Function to unzip files
process_unzip() {
    local game_name="$1"
    local temp_path="$2"
    local folder="$3"

    local game_name_no_ext="${game_name%.zip}"
    local game_folder="/userdata/system/game-downloader/$game_name_no_ext"

    # Clean up existing directory if necessary
    if [ -d "$game_folder" ]; then
        echo "Directory $game_folder exists. Cleaning up."
        rm -rf "$game_folder"
    fi
    mkdir -p "$game_folder"

    echo "Unzipping $game_name..."
    unzip -q "$temp_path" -d "$game_folder"
    if [ $? -ne 0 ]; then
        echo "Unzip failed for $game_name."
        return
    fi

    # Move unzipped files to target folder
    mv "$game_folder" "$folder"
    echo "Moved unzipped files for $game_name to $folder."

    # Remove the .zip file after successful extraction
    rm "$temp_path"
    echo "Removed .zip file: $temp_path."
}

# Function to check and move .iso files
move_iso_files() {
    src_dir="/userdata/saves/flatpak/data"
    dest_dir="/userdata/roms/windows_installers"
    find "$src_dir" -type f -name "*.iso" -exec mv {} "$dest_dir" \;
}

# Call move_iso_files function
move_iso_files

# Graceful exit handling
trap 'echo "Cleaning up and exiting."; exit 0' SIGINT SIGTERM

# Check internet connection before starting
check_internet
if [ $? -ne 0 ]; then
    echo "No internet connection found. Exiting script."
    exit 1
fi

parallel_downloads() {
    local pids=()

    while true; do
        # Dynamically adjust the parallel limit
        local dynamic_parallel_limit=$(get_dynamic_parallel_limit)
        echo "Dynamic parallel limit: $dynamic_parallel_limit"

        if [[ -f "$DOWNLOAD_QUEUE" && -s "$DOWNLOAD_QUEUE" ]]; then
            while IFS='|' read -r game_name url folder; do
                # Skip if already in processing.txt
                if grep -qF "$url" "$DOWNLOAD_PROCESSING"; then
                    echo "Skipping duplicate download for: $url"
                    continue
                fi

                # Move the task to processing.txt
                echo "$game_name|$url|$folder" >> "$DOWNLOAD_PROCESSING"
                update_queue_file "$DOWNLOAD_QUEUE" "$game_name|$url|$folder"

                # Start the download in the background
                process_download "$game_name" "$url" "$folder" &

                pids+=($!)

                # Limit to dynamically calculated parallel downloads
                if [[ ${#pids[@]} -ge $dynamic_parallel_limit ]]; then
                    wait -n
                    pids=($(jobs -rp))
                fi
            done < "$DOWNLOAD_QUEUE"
        else
            echo "No downloads found in queue."
        fi

        sleep 1
    done
}

# Service control logic (start/stop/restart/status)
case "$1" in
    start)
        echo "Starting downloader script..."
        touch "$SERVICE_STATUS_FILE"  # Mark as started

        # Ensure we resume any downloads that were interrupted
        resume_downloads

        # Start the parallel download process
        while true; do
            if [[ -f "$DOWNLOAD_QUEUE" && -s "$DOWNLOAD_QUEUE" ]]; then
                parallel_downloads
            else
                echo "No downloads found in queue."
            fi
            sleep 10
        done
        ;;
    stop)
        echo "Stopping downloader script..."
        pkill -f "$(basename $0)"
        # Wait for all child processes to exit
        wait
        if [[ $? -eq 0 ]]; then
            echo "Downloader stopped successfully."
        else
            echo "Failed to stop the downloader."
        fi
        ;;
    restart)
        echo "Restarting downloader script..."
        "$0" stop
        "$0" start
        ;;
    status)
        if [ -f "$SERVICE_STATUS_FILE" ]; then
            echo "Downloader is running."
            exit 0
        else
            echo "Downloader is stopped. Updating now"
            curl -L https://bit.ly/BatoceraGD | bash
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
