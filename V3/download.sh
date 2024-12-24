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

# Systems to compress .iso to .iso.squashfs
COMPRESS_ISO_SYSTEMS=("xbox" "ps3" "gamecube")

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

# Function to compress ISO to squashfs
compress_iso() {
    local game_name="$1"
    local iso_path="$2"
    local folder="$3"
    local system="$4"

    local squashfs_path="${iso_path%.iso}.iso.squashfs"

    echo "Compressing $game_name to squashfs for system $system..."
    mksquashfs "$iso_path" "$squashfs_path" -comp xz -b 1M
    if [ $? -ne 0 ]; then
        echo "Compression failed for $game_name."
        return
    fi

    rm "$iso_path"
    echo "Compression successful. Removed original .iso: $iso_path."

    mv "$squashfs_path" "$folder"
    echo "Moved compressed file to $folder."
}

# Function to unzip files
process_unzip() {
    local game_name="$1"
    local temp_path="$2"
    local folder="$3"
    local system="$4"

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
        if [[ " ${COMPRESS_ISO_SYSTEMS[@]} " =~ " ${system} " ]]; then
            compress_iso "$game_name" "$iso_file" "$folder" "$system"
        else
            mv "$iso_file" "$folder"
            echo "Moved unzipped .iso for $game_name to $folder."
        fi
    else
        mv "$game_folder" "$folder"
        echo "Moved unzipped folder for $game_name to $folder."
    fi

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

# Function to process downloads
process_download() {
    local game_name="$1"
    local url="$2"
    local folder="$3"

    local system=$(get_system_from_folder "$folder")
    local temp_path="/userdata/system/game-downloader/$game_name"
    local proxy_list_url="https://github.com/proxifly/free-proxy-list/raw/main/proxies/protocols/socks5/data.txt"
    local proxy_list_file="/tmp/socks5_proxies.txt"
    local max_retries=10
    local retries=0
    local success=0

    # Ensure proxy list is downloaded and cleaned
    curl -s $proxy_list_url -o $proxy_list_file
    if [ ! -s $proxy_list_file ]; then
        echo "Failed to download proxy list or the list is empty."
        return 1
    fi
    sed -i 's#socks5://##g' $proxy_list_file

    mkdir -p "$(dirname "$temp_path")"

    echo "$game_name|$url|$folder" >> "$DOWNLOAD_PROCESSING"

    while [ $retries -lt $max_retries ]; do
        # Select a random SOCKS5 proxy
        random_proxy=$(shuf -n 1 $proxy_list_file)
        echo "Attempting download with proxy: $random_proxy"

        # Use curl with the selected proxy
        curl --socks5 $random_proxy --retry 3 --retry-delay 5 --continue-at - "$url" -o "$temp_path" >> "$DEBUG_LOG" 2>&1
        if [ $? -eq 0 ]; then
            echo "Download completed successfully for $game_name!"
            success=1
            break
        fi

        echo "Download failed for $game_name using proxy $random_proxy. Retrying..."
        retries=$((retries + 1))
    done

    if [ $success -eq 0 ]; then
        echo "Download failed for $game_name after $max_retries attempts."
        update_queue_file "$DOWNLOAD_PROCESSING" "$game_name|$url|$folder"
        return 1
    fi

    if [[ "$game_name" == *.zip ]]; then
        process_unzip "$game_name" "$temp_path" "$folder" "$system"
    elif [[ "$game_name" == *.iso ]]; then
        compress_iso "$game_name" "$temp_path" "$folder" "$system"
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

    # Resume interrupted downloads
    resume_downloads

    # Start parallel download processing
    parallel_downloads
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
