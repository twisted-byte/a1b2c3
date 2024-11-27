#!/bin/bash

# Paths to files and logs
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"
DOWNLOAD_PROCESSING="/userdata/system/game-downloader/processing.txt"
DEBUG_LOG="/userdata/system/game-downloader/debug/debug.txt"
LOG_FILE="/userdata/system/game-downloader/download.log"  # Added log file for tracking downloads

# Maximum number of parallel downloads
MAX_PARALLEL=3

# Directories for PC downloads and installer destination
PC_DOWNLOADS_DIR="/userdata/system/game-downloader/pc"
INSTALLERS_DIR="/userdata/roms/windows_installers"

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

# Log download function
log_download() {
    url=$1
    echo "$url" >> "$LOG_FILE"
}

# Function to resume downloads
resume_downloads() {
    if [ -f "$LOG_FILE" ]; then
        while IFS= read -r url; do
            wget -c "$url"
            if [ $? -eq 0 ]; then
                sed -i "\|$url|d" "$LOG_FILE"
            fi
        done < "$LOG_FILE"
    fi
}

# Start resuming downloads
resume_downloads

# Function to process individual downloads
process_download() {
    local game_name="$1"
    local url="$2"
    local folder="$3"

    game_name=$(echo "$game_name" | sed 's/[\"]//g')
    local temp_path="/userdata/system/game-downloader/$game_name"

    # Check for existing partial download
    if [ -f "$temp_path" ]; then
        echo "Resuming partial download for $game_name..."
    else
        echo "$game_name|$url|$folder" >> "$DOWNLOAD_PROCESSING"
        echo "Started download for $game_name... Logging to processing.txt"
        update_queue_file "$DOWNLOAD_QUEUE" "$game_name|$url|$folder"
        echo "Starting new download for $game_name..."
    fi

    # Download with retry and resume logic
    wget --tries=5 -c "$url" -O "$temp_path" >> "$DEBUG_LOG" 2>&1
    if [ $? -ne 0 ]; then
        echo "Download failed for $game_name. Check debug log for details."
        return
    fi

    echo "Download succeeded for $game_name."

    # Handle file based on its extension
    if [[ "$game_name" == *.zip ]]; then
        process_unzip "$game_name" "$temp_path" "$folder"
    elif [[ "$game_name" == *.chd || "$game_name" == *.iso ]]; then
        echo "Skipping extraction for $game_name. Moving file to destination."
        mv "$temp_path" "$folder"
    else
        echo "Unsupported file type for $game_name. Skipping."
        rm "$temp_path"  # Clean up the downloaded file
    fi

    # Remove the line from processing.txt after successful processing
    update_queue_file "$DOWNLOAD_PROCESSING" "$game_name|$url|$folder"
    
    # Remove the URL from download.log after successful download
    sed -i "\|$url|d" "$LOG_FILE"
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
    find "$PC_DOWNLOADS_DIR" -type f -name "*.bin" | while read bin_file; do
        cue_file="${bin_file%.bin}.cue"
        if [ -f "$cue_file" ]; then
            convert_to_iso "$bin_file" "$cue_file"
        fi
    done
}

# Function to convert bin/cue to iso using bchuck
convert_to_iso() {
    local bin_file="$1"
    local cue_file="$2"
    local iso_file="${bin_file%.bin}.iso"

    # Run bchuck conversion
    echo "Converting $bin_file and $cue_file to $iso_file"
    bchuck -c "$cue_file" -o "$iso_file"

    if [ $? -eq 0 ]; then
        echo "Conversion successful: $iso_file"
        # Move ISO to the installers directory
        mv "$iso_file" "$INSTALLERS_DIR"
        echo "Moved $iso_file to $INSTALLERS_DIR"
    else
        echo "Failed to convert $bin_file and $cue_file to ISO."
    fi
}

# Function to adjust parallel downloads dynamically based on system load
adjust_parallel_downloads() {
    local load=$(uptime | awk -F'load average: ' '{print $2}' | cut -d',' -f1 | xargs)
    local max_cpu=$(nproc)

    # Reduce parallel downloads if system load is higher than half CPU count
    if (( $(echo "$load > $max_cpu / 2" | bc -l) )); then
        MAX_PARALLEL=$((MAX_PARALLEL - 1))
        echo "System load high ($load), reducing parallel downloads to $MAX_PARALLEL."
    else
        MAX_PARALLEL=$((MAX_PARALLEL + 1))
        echo "System load low ($load), increasing parallel downloads to $MAX_PARALLEL."
    fi

    # Ensure MAX_PARALLEL stays within reasonable bounds
    MAX_PARALLEL=$((MAX_PARALLEL < 1 ? 1 : MAX_PARALLEL))
    MAX_PARALLEL=$((MAX_PARALLEL > 5 ? 5 : MAX_PARALLEL))  # Cap at 5
}

# Parallel downloads with dynamic adjustment
parallel_downloads() {
    local pids=()  # Array to hold background process IDs

    while IFS='|' read -r game_name url folder; do
        # Adjust parallelism based on system load
        adjust_parallel_downloads

        echo "Starting parallel download for: $game_name | $url | $folder"

        # Move the line to processing.txt and remove from download.txt
        echo "$game_name|$url|$folder" >> "$DOWNLOAD_PROCESSING"
        update_queue_file "$DOWNLOAD_QUEUE" "$game_name|$url|$folder"

        # Launch download in the background
        process_download "$game_name" "$url" "$folder" &

        # Track the background process
        pids+=($!)

        # Wait if reaching the parallel limit
        if [[ ${#pids[@]} -ge $MAX_PARALLEL ]]; then
            wait -n
            pids=($(jobs -rp))
        fi
    done < "$DOWNLOAD_QUEUE"

    # Wait for all remaining processes to finish
    wait
}

# Continuous script loop
while true; do
    echo "Checking for new downloads at $(date)"

    if [[ -f "$DOWNLOAD_QUEUE" && -s "$DOWNLOAD_QUEUE" ]]; then
        parallel_downloads
    else
        echo "No downloads found in queue."
    fi

    # Move and convert PC downloads
    move_iso_files

    # Pause before checking again
    sleep 10
done