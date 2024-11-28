#!/bin/bash

# Paths to files and logs
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"
DOWNLOAD_PROCESSING="/userdata/system/game-downloader/processing.txt"
DEBUG_LOG="/userdata/system/game-downloader/debug/debug.txt"
LOG_FILE="/userdata/system/game-downloader/download.log"

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

# Function to check for internet connection
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

    if [ -f "$temp_path" ]; then
        echo "Resuming partial download for $game_name..."
    else
        echo "$game_name|$url|$folder" >> "$DOWNLOAD_PROCESSING"
        echo "Starting download for $game_name..."
        update_queue_file "$DOWNLOAD_QUEUE" "$game_name|$url|$folder"
        wget --tries=5 -c "$url" -O "$temp_path"
    fi

    if [ $? -eq 0 ]; then
        echo "Download succeeded for $game_name."
        if [[ "$game_name" == *.zip && ! "$folder" =~ ^/userdata/roms/(psvita|dos|atari2600|atari5200|atari7800) ]]; then
            process_unzip "$game_name" "$temp_path" "$folder"
        else
            mv "$temp_path" "$folder"
        fi
        update_queue_file "$DOWNLOAD_PROCESSING" "$game_name|$url|$folder"
        sed -i "\|$url|d" "$LOG_FILE"
    else
        echo "Download failed for $game_name."
    fi
}

# Function to unzip files
process_unzip() {
    local game_name="$1"
    local temp_path="$2"
    local folder="$3"
    local game_name_no_ext="${game_name%.zip}"
    local game_folder="/userdata/system/game-downloader/$game_name_no_ext"

    rm -rf "$game_folder"
    mkdir -p "$game_folder"
    echo "Unzipping $game_name..."
    unzip -q "$temp_path" -d "$game_folder"
    if [ $? -eq 0 ]; then
        mv "$game_folder" "$folder"
        rm "$temp_path"
    else
        echo "Unzip failed for $game_name."
    fi
}

# Function to move and convert .bin/.cue to .iso
move_iso_files() {
    find "$PC_DOWNLOADS_DIR" -type f -name "*.bin" | while read bin_file; do
        # Identify the folder containing the .bin file
        bin_folder=$(dirname "$bin_file")

        # Locate the .cue file in the same folder as the .bin file
        cue_file=$(find "$bin_folder" -maxdepth 1 -type f -name "*.cue" | head -n 1)

        # If a .cue file exists, process the .bin/.cue pair
        if [ -n "$cue_file" ]; then
            echo "Found matching .cue for $bin_file: $cue_file"
            convert_to_iso "$bin_file" "$cue_file" "$bin_folder"
        else
            echo "No .cue file found for $bin_file. Skipping."
        fi
    done
}

# Function to convert bin/cue to iso using bchunk
convert_to_iso() {
    local bin_file="$1"
    local cue_file="$2"
    local bin_folder="$3"
    
    # Set the base name for the ISO based on the .cue file (remove the .cue extension)
    local iso_base_name="${cue_file%.cue}"
    
    # Run bchunk conversion to create all related files (e.g., .iso01.iso, .iso02.cdr, etc.)
    echo "Converting .bin/.cue pair to $iso_base_name.iso"

    bchunk "$bin_file" "$cue_file" "$iso_base_name"

    if [ $? -eq 0 ]; then
        echo "Conversion successful."

        # Create a subfolder in the installers directory named after the original bin folder
        local install_folder="$INSTALLERS_DIR/$(basename "$bin_folder")"
        mkdir -p "$install_folder"

        # Move all files created by bchunk (e.g., .iso, .cdr) to the new folder
        find "$bin_folder" -type f -name "*.iso*" -o -name "*.cdr" -exec mv {} "$install_folder" \;

        # Check if the move was successful
        if [ $? -eq 0 ]; then
            echo "Moved ISO files to $install_folder"

            # Clean up original .bin, .cue, and the folder containing them after successful move
            rm -f "$bin_file" "$cue_file"
            echo "Removed original files: $bin_file and $cue_file"

            # Only remove the folder if it no longer contains any .bin or .cue files
            if [ -z "$(find "$bin_folder" -type f -name "*.bin" -o -name "*.cue")" ]; then
                rm -rf "$bin_folder"
                echo "Removed original folder: $bin_folder"
            fi
        else
            echo "Failed to move ISO files to $install_folder"
        fi
    else
        echo "Conversion failed for $bin_file using $cue_file"
    fi
}

# Adjust parallel downloads based on system load
adjust_parallel_downloads() {
    local load=$(uptime | awk -F'load average: ' '{print $2}' | cut -d',' -f1 | xargs)
    local max_cpu=$(nproc)

    if (( $(echo "$load > $max_cpu / 2" | bc -l) )); then
        MAX_PARALLEL=$((MAX_PARALLEL - 1))
    else
        MAX_PARALLEL=$((MAX_PARALLEL + 1))
    fi

    MAX_PARALLEL=$((MAX_PARALLEL < 1 ? 1 : MAX_PARALLEL))
    MAX_PARALLEL=$((MAX_PARALLEL > 5 ? 5 : MAX_PARALLEL))
}

# Parallel downloads
parallel_downloads() {
    local pids=()
    while IFS='|' read -r game_name url folder; do
        adjust_parallel_downloads
        process_download "$game_name" "$url" "$folder" &
        pids+=($!)

        if [[ ${#pids[@]} -ge $MAX_PARALLEL ]]; then
            wait -n
            pids=($(jobs -rp))
        fi
    done < "$DOWNLOAD_QUEUE"
    wait
}

# Main loop
while true; do
    echo "Checking for downloads at $(date)"
    if [[ -f "$DOWNLOAD_QUEUE" && -s "$DOWNLOAD_QUEUE" ]]; then
        parallel_downloads
    else
        echo "No downloads found in queue."
    fi
    move_iso_files
    sleep 10
done