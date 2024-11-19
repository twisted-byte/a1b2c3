#!/bin/bash

# Base URL and destination directory
BASE_URLS="https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20-%20NKit%20RVZ%20[zstd-19-128k]/"
DEST_DIR="/userdata/system/game-downloader/links/Wii"
ROM_DIR="/userdata/roms/wii"
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
    local page_content=$(curl -s "$base_url")

    echo "$page_content" | grep -oP "(?<=href=\")[^\"]*${EXT}" | while read -r game_url; do
        # Decode the URL
        decoded_name=$(decode_url "$game_url")
        
        # Format the entry with backticks around the decoded name
        quoted_name="\`$decoded_name\`"
        # Get the first character of the decoded file name
        first_char="${decoded_name:0:1}"
        
        # Determine the appropriate file based on the first character
        if [[ "$first_char" =~ [a-zA-Z] ]]; then
            first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')
            target_file="$DEST_DIR/${first_char}.txt"
        elif [[ "$first_char" =~ [0-9] ]]; then
            target_file="$DEST_DIR/#.txt"
        else
            target_file="$DEST_DIR/other.txt"
        fi

        # Check if the game already exists in the target file
        if grep -q "$quoted_name" "$target_file"; then
            echo "Skipping $decoded_name as it already exists."
            continue
        fi

        # Save to the appropriate letter-based file
        echo "$quoted_name|$base_url$game_url|$ROM_DIR" >> "$target_file"
    done
}

# Iterate over each base URL and scrape it
for url in "${BASE_URLS[@]}"; do
    scrape_url "$url"
done

echo "Scraping complete!"
