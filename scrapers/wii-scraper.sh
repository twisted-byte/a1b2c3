#!/bin/bash

# Base URLs and destination directory
BASE_URLS=("https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20-%20NKit%20RVZ%20[zstd-19-128k]/")
DEST_DIR="/userdata/system/game-downloader/links/Wii"
ROM_DIR="/userdata/roms/wii"
EXT=".zip"
LOG_FILE="$DEST_DIR/scrape_log.txt"

# Ensure the destination directory and log file exist
mkdir -p "$DEST_DIR"
touch "$LOG_FILE"

# Function to decode URL (ASCII decode)
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Function to scrape a given base URL
scrape_url() {
    local base_url="$1"
    echo "Scraping URL: $base_url" | tee -a "$LOG_FILE"

    # Fetch the page content with verbose logging
    local response=$(wget -q -O - "$base_url")
    if [[ $? -ne 0 || -z "$response" ]]; then
        echo "Error: Failed to fetch content from $base_url" | tee -a "$LOG_FILE"
        return
    fi

    # Print the raw response to the terminal for debugging
    echo "Raw content from $base_url:" | tee -a "$LOG_FILE"
    echo "$response" | tee -a "$LOG_FILE"

    # Extract game file URLs matching the extension
    echo "$response" | grep -oP "(?<=href=\")[^\"]*${EXT}" | while read -r game_url; do
        # Decode the URL
        local decoded_name=$(decode_url "$game_url")
        local quoted_name="\`$decoded_name\`"
        local first_char="${decoded_name:0:1}"

        # Determine the target file based on the first character
        if [[ "$first_char" =~ [a-zA-Z] ]]; then
            first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')
            target_file="$DEST_DIR/${first_char}.txt"
        elif [[ "$first_char" =~ [0-9] ]]; then
            target_file="$DEST_DIR/#.txt"
        else
            target_file="$DEST_DIR/other.txt"
        fi
        # Ensure the target file exists
        [ -f "$target_file" ] || touch "$target_file"

        # Check if the game already exists in the target file
        if grep -qF "$quoted_name" "$target_file"; then
            echo "Skipping $decoded_name as it already exists." | tee -a "$LOG_FILE"
            continue
        fi

        # Add the entry to the target file and master list
        echo "$quoted_name|$base_url$game_url|$ROM_DIR" >> "$target_file"
        echo "$quoted_name|$base_url$game_url|$ROM_DIR" >> "$DEST_DIR/AllGames.txt"
        echo "Added: $decoded_name" | tee -a "$LOG_FILE"
    done
}

# Iterate over each base URL and scrape it
for url in "${BASE_URLS[@]}"; do
    scrape_url "$url"
done

echo "Scraping complete!" | tee -a "$LOG_FILE"
