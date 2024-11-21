#!/bin/bash

# Base URL and destination directory
BASE_URLS=("https://myrient.erista.me/files/Redump/Apple%20-%20Macintosh/")
DEST_DIR="/userdata/system/game-downloader/links/Apple Macintosh"
ROM_DIR="/userdata/roms/macintosh"
EXT=".zip"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Function to decode URL (ASCII decode)
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Function to scrape a given base URL
scrape_url() {
    local base_url="$1"

    # Fetch the page content
    local response=$(wget -q -O - "$base_url")
    if [[ $? -ne 0 || -z "$response" ]]; then
        echo "Error: Failed to fetch content from $base_url"
        return
    fi

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
            continue
        fi

        # Add the entry to the target file and master list
        echo "$quoted_name|$base_url$game_url|$ROM_DIR" >> "$target_file"
        echo "$quoted_name|$base_url$game_url|$ROM_DIR" >> "$DEST_DIR/AllGames.txt"
    done
}

# Iterate over each base URL and scrape it
for url in "${BASE_URLS[@]}"; do
    scrape_url "$url"
done
