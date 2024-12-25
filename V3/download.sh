#!/bin/bash

# Paths to files and logs
DOWNLOAD_QUEUE="/userdata/system/game-downloader/download.txt"
DOWNLOAD_PROCESSING="/userdata/system/game-downloader/processing.txt"
DEBUG_LOG="/userdata/system/game-downloader/debug/debug.txt"
SERVICE_STATUS_FILE="/userdata/system/game-downloader/downloader_service_status"

# Maximum number of parallel downloads (initial value)
MAX_PARALLEL=3

# Systems to keep as .zip
KEEP_AS_ZIP_SYSTEMS=("arcade" "mame" "atari2600" "atari5200" "atari7800" "fba" "cps1" "cps2" "cps3" "neogeo" "nes" "snes" "n64" "gb" "gbc" "gba" "mastersystem" "megadrive" "gamegear" "pcengine" "supergrafx" "ngp" "ngpc" "scummvm" "msx" "zxspectrum" "gameandwatch" "sg1000")

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

install_7zz(){
    # Paths and URLs
    INSTALL_DIR="/userdata/system/game-downloader/bin"
    BINARY_URL="https://github.com/DTJW92/game-downloader/raw/refs/heads/main/V3/7zz"
    BINARY_NAME="7zz"
    BINARY_PATH="$INSTALL_DIR/$BINARY_NAME"

    # Ensure the install directory exists
    mkdir -p "$INSTALL_DIR"

    # Check if 7zz is already in the system path
    if command -v "$BINARY_NAME" &> /dev/null; then
        echo "$BINARY_NAME is already installed and in the PATH."
        return
    fi

    echo "Downloading $BINARY_NAME..."

    # Download the 7zz binary
    curl -L "$BINARY_URL" -o "$BINARY_PATH"
    if [ $? -ne 0 ]; then
        echo "Failed to download $BINARY_NAME."
        exit 1
    fi

    # Make the binary executable
    chmod +x "$BINARY_PATH"

    # Check if the binary is executable
    if [ ! -x "$BINARY_PATH" ]; then
        echo "Failed to make $BINARY_NAME executable."
        exit 1
    fi

    echo "$BINARY_NAME installed successfully at $BINARY_PATH."

    # Create a symlink in /usr/bin if desired (ensure it doesn't already exist)
    if [ ! -L "/usr/bin/$BINARY_NAME" ]; then
        ln -s "$BINARY_PATH" "/usr/bin/$BINARY_NAME"
        echo "Symlink created in /usr/bin."
    else
        echo "Symlink already exists in /usr/bin."
    fi
}


install_extract_xiso() {
    local binary_url="https://github.com/DTJW92/game-downloader/raw/main/V3/extract-xiso"
    local install_dir="/userdata/system/game-downloader/bin"
    local binary_name="extract-xiso"
    local binary_path="$install_dir/$binary_name"

    # Check if extract-xiso is already in the system path
    if command -v extract-xiso &> /dev/null; then
        echo "extract-xiso is already installed and in the PATH."
        return
    fi

    # Ensure the install directory exists
    mkdir -p "$install_dir"

    echo "Downloading extract-xiso..."

    # Download the binary
    curl -L "$binary_url" -o "$binary_path"
    if [ $? -ne 0 ]; then
        echo "Failed to download extract-xiso."
        return 1
    fi

    # Make the binary executable
    chmod +x "$binary_path"

    # Check if the binary is executable
    if [ ! -x "$binary_path" ]; then
        echo "Failed to make extract-xiso executable."
        return 1
    fi

    echo "extract-xiso installed successfully at $binary_path."

    # Create symlink to /usr/bin if desired (ensure it doesn't already exist)
    if [ ! -L "/usr/bin/$binary_name" ]; then
        ln -s "$binary_path" "/usr/bin/$binary_name"
        echo "Symlink created in /usr/bin."
    else
        echo "Symlink already exists in /usr/bin."
    fi
}

# Call the function to install binarys
install_extract_xiso
install_7zz

# Function to update queue files safely
update_queue_file() {
    local file="$1"
    local line_to_exclude="$2"
    awk -v pattern="$line_to_exclude" '!index($0, pattern)' "$file" > temp && mv temp "$file"
}

# Function to dynamically adjust the number of parallel downloads based on system load
get_dynamic_parallel_limit() {
    local load=$(awk '{print $1}' /proc/loadavg)
    local cpu_count=$(nproc)
    local limit=$(echo "$cpu_count / $load" | bc -l)
    if (( $(echo "$limit < 1" | bc -l) )); then
        limit=1
    elif (( $(echo "$limit > 10" | bc -l) )); then
        limit=10
    fi
    echo "${limit%.*}"
}

# Extract the system name from the folder path
get_system_from_folder() {
    local folder="$1"
    echo "$(basename "$folder")"
}

# Function to unzip files
# Define a separate log file for unzip process
UNZIP_DEBUG_LOG="/userdata/system/game-downloader/debug/unzip_debug.txt"

process_unzip() {
    local game_name="$1"
    local temp_path="$2"
    local folder="$3"
    local system="$4"

    # Redirecting output of unzip specific logs to the new log file
    exec > "$UNZIP_DEBUG_LOG" 2>&1

    if [[ " ${KEEP_AS_ZIP_SYSTEMS[@]} " =~ " ${system} " ]]; then
        echo "System $system is configured to keep files as .zip. Moving $game_name as is."
        mv "$temp_path" "$folder"
        return
    fi

    local game_name_no_ext="${game_name%.zip}"
    local game_folder="/userdata/system/game-downloader/$game_name_no_ext"

    if [ -d "$game_folder" ]; then
        echo "Directory $game_folder exists. Cleaning up."
        rm -rf "$game_folder"
    fi
    mkdir -p "$game_folder"

    echo "Unzipping $game_name for system $system..."
    unzip -q "$temp_path" -d "$game_folder"
    if [ $? -ne 0 ]; then
        echo "Unzip failed for $game_name."
        return
    fi

    local iso_file=$(find "$game_folder" -type f -name "*.iso" | head -n 1)
    
    if [ -n "$iso_file" ]; then
        echo "Extracted .iso file: $iso_file"

        if [ "$system" == "xbox" ]; then
            echo "Using extract-xiso to rewrite Xbox game to .xiso format."
            extract-xiso -r "$iso_file" "$folder"
            if [ $? -eq 0 ]; then
                echo "Xbox game successfully rewritten to .xiso."
            else
                echo "extract-xiso failed for $game_name."
            fi
        elif [ "$system" == "ps3" ]; then
            echo "Extracting PS3 ISO to a folder with .ps3 extension."
            local ps3_folder="${game_folder}.ps3"

            # Create the PS3 folder and extract
            mkdir -p "$ps3_folder"
            7zz x "$iso_file" -o"$ps3_folder"
            if [ $? -ne 0 ]; then
                echo "Extraction failed for $iso_file."
                return
            fi

            echo "PS3 ISO extracted to $ps3_folder"

            # Remove the original ISO after extraction (optional)
            rm "$iso_file"
            echo "Removed original ISO file: $iso_file"

            # Move the folder to the final destination
            mv "$ps3_folder" "$folder"
            echo "Moved extracted PS3 folder to $folder"
        else
            mv "$iso_file" "$folder"
            echo "Moved unzipped .iso for $game_name to $folder."
        fi
    else
        mv "$game_folder" "$folder"
        echo "Moved unzipped folder for $game_name to $folder."
    fi

    # Remove the temporary folder created during unzip
    rm -rf "$game_folder"
    echo "Removed temporary unzip folder: $game_folder"

    # Remove the original .zip file
    rm "$temp_path"
    echo "Removed .zip file: $temp_path."
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
            else
                echo "Starting new download for $game_name from $url..."
            fi

            # Call process_download to handle the download and file processing
            process_download "$game_name" "$url" "$folder"
        done < "$DOWNLOAD_PROCESSING"
    else
        echo "No downloads to resume in $DOWNLOAD_PROCESSING."
    fi
}

process_download() {
    local game_name="$1"
    local url="$2"
    local folder="$3"

    local system=$(get_system_from_folder "$folder")
    local temp_path="/userdata/system/game-downloader/$game_name"
    local final_game_path="$folder/$game_name"

    # Skip if the game already exists in the ROM folder
    if [ -f "$final_game_path" ]; then
        echo "$game_name already exists in the ROM folder. Skipping download."
        # Remove the skipped line from download.txt
        update_queue_file "$DOWNLOAD_QUEUE" "$game_name|$url|$folder"
        return
    fi

    if [ -f "$temp_path" ]; then
        echo "Resuming partial download for $game_name..."
    else
        echo "Starting new download for $game_name..."
    fi

    echo "$game_name|$url|$folder" >> "$DOWNLOAD_PROCESSING"

    wget --tries=5 -c "$url" -O "$temp_path" >> "$DEBUG_LOG" 2>&1
    if [ $? -ne 0 ]; then
        echo "Download failed for $game_name. Check debug log for details."
        return
    fi

    echo "Download completed for $game_name."

    # Handling .zip files by calling the unzip function
    if [[ "$game_name" == *.zip ]]; then
        process_unzip "$game_name" "$temp_path" "$folder" "$system"
    elif [[ "$game_name" == *.iso ]]; then
        mv "$temp_path" "$folder"
        echo "Moved .iso for $game_name to $folder."
    elif [[ "$game_name" == *.chd ]]; then
        mv "$temp_path" "$folder"
        echo "Moved $game_name to $folder."
    else
        echo "Unsupported file type for $game_name. Skipping."
        rm "$temp_path"
    fi

    update_queue_file "$DOWNLOAD_PROCESSING" "$game_name|$url|$folder"
}


# Function to check and move .iso files
move_iso_files() {
    src_dir="/userdata/saves/flatpak/data"
    dest_dir="/userdata/roms/windows_installers"
    find "$src_dir" -type f -name "*.iso" -exec mv {} "$dest_dir" \;
}
parallel_downloads() {
    local pids=()

    while true; do
        # Dynamically adjust the parallel limit
        local dynamic_parallel_limit=$(get_dynamic_parallel_limit)

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

# Call move_iso_files function
move_iso_files

# Check internet connection before starting
check_internet
if [ $? -ne 0 ]; then
    echo "No internet connection found. Exiting script."
    exit 1
fi

resume_downloads
parallel_downloads &

wait
