#!/bin/bash

# Paths to files and logs
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"
DOWNLOAD_PROCESSING="/userdata/system/game-downloader/processing.txt"
DEBUG_LOG="/userdata/system/game-downloader/debug/debug.txt"
LOG_FILE="/userdata/system/game-downloader/download.log"  # Log file for tracking downloads

# Maximum number of parallel downloads
MAX_PARALLEL=3

# Directories for PC downloads and installer destination
PC_DOWNLOADS_DIR="/userdata/system/game-downloader/pc"
INSTALLERS_DIR="/userdata/roms/windows_installers"

# Ensure directories exist
mkdir -p "$(dirname "$DEBUG_LOG")"
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$PC_DOWNLOADS_DIR"

# Check for bchunk in /usr/bin, download it if not found
check_bchunk() {
    if ! command -v bchunk &> /dev/null; then
        echo "bchunk not found, downloading..."
        wget -q "https://github.com/DTJW92/game-downloader/raw/main/V3/bchunk" -O /usr/bin/bchunk
        chmod +x /usr/bin/bchunk
        echo "bchunk downloaded and installed."
    else
        echo "bchunk already installed."
    fi
}

# Call the function to check for bchunk
check_bchunk

# Clear debug log for a fresh session
if [ -f "$DEBUG_LOG" ]; then
    echo "Clearing debug log for the new session." >> "$DEBUG_LOG"
    > "$DEBUG_LOG"
fi

# Create log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    echo "Creating log file at $LOG_FILE"
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
fi

# Redirect stdout and stderr to debug log
exec > "$DEBUG_LOG" 2>&1

# Log script start
echo "Starting game downloader script at $(date)"

# Function to log downloads
log_download() {
    local url="$1"
    if [ -n "$url" ]; then
        echo "Logging URL to $LOG_FILE: $url"
        echo "$url" >> "$LOG_FILE"
    else
        echo "log_download called with empty URL."
    fi
}

# Function to process downloads
process_download() {
    local game_name="$1"
    local url="$2"
    local folder="$3"
    local temp_path="/userdata/system/game-downloader/$game_name"

    game_name=$(echo "$game_name" | sed 's/[\"]//g')

    if [ ! -f "$temp_path" ]; then
        echo "Starting download for $game_name..."
        wget --tries=5 -c "$url" -O "$temp_path"
        if [ $? -eq 0 ]; then
            echo "Download succeeded for $game_name."
        else
            echo "Download failed for $game_name."
        fi
    else
        echo "Resuming download for $game_name..."
    fi

    # Log download completion
    sed -i "\|$url|d" "$LOG_FILE"
}

# Function to check and move .iso files
move_iso_files() {
    echo "Searching for .bin files in $PC_DOWNLOADS_DIR..."
    find "$PC_DOWNLOADS_DIR" -type f -name "*.bin" | while read bin_file; do
        cue_file="${bin_file%.bin}.cue"
        if [ -f "$cue_file" ]; then
            convert_to_iso "$bin_file" "$cue_file"
        else
            echo "No matching .cue for $bin_file"
        fi
    done
}

# Function to convert bin/cue to iso using bchunk
convert_to_iso() {
    local bin_file="$1"
    local cue_file="$2"
    local iso_file="${bin_file%.bin}.iso"
    echo "Converting $bin_file and $cue_file to $iso_file using bchunk."
    bchunk "$bin_file" "$cue_file" "$iso_file"
    if [ $? -eq 0 ]; then
        echo "Conversion successful: $iso_file"
        mv "$iso_file" "$INSTALLERS_DIR"
    else
        echo "Conversion failed for $bin_file and $cue_file."
    fi
}

# Parallel downloads
parallel_downloads() {
    while IFS='|' read -r game_name url folder; do
        if [[ -n "$game_name" && -n "$url" ]]; then
            echo "Processing download: $game_name | $url | $folder"
            process_download "$game_name" "$url" "$folder"
        fi
    done < "$DOWNLOAD_QUEUE"
}

# Continuous script loop
while true; do
    echo "Checking for new downloads at $(date)"
    if [[ -f "$DOWNLOAD_QUEUE" && -s "$DOWNLOAD_QUEUE" ]]; then
        parallel_downloads
    else
        echo "No downloads found in queue."
    fi

    # Check for .bin files and convert to .iso
    move_iso_files

    # Pause before checking again
    sleep 10
done