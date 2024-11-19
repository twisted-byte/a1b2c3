#!/bin/bash

# Base URL and destination directory
BASE_URLS="https://myrient.erista.me/files/Redump/IBM%20-%20PC%20compatible/"
DEST_DIR="/userdata/system/game-downloader/links/PC"
ROM_DIR="/userdata/roms/windows_installers"
EXT=".zip"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Function to decode URL (ASCII decode)
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Clear all the text files before writing new data
clear_all_files() {
    rm -f "$DEST_DIR"/*.txt
}

# Clear all text files before starting
clear_all_files

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
        
        # Check if the game already exists in AllGames.txt
        if grep -q "$quoted_name" "$DEST_DIR/AllGames.txt"; then
            echo "Skipping $decoded_name as it already exists."
            continue
        fi
        
        # Append to AllGames.txt with both quoted decoded name and original URL
        echo "$quoted_name|$base_url$game_url|$ROM_DIR" >> "$DEST_DIR/AllGames.txt"
        
        # Save to the appropriate letter-based file
        if [[ "$first_char" =~ [a-zA-Z] ]]; then
            first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')
            echo "$quoted_name|$base_url$game_url|$ROM_DIR" >> "$DEST_DIR/${first_char}.txt"
        elif [[ "$first_char" =~ [0-9] ]]; then
            echo "$quoted_name|$base_url$game_url|$ROM_DIR" >> "$DEST_DIR/#.txt"
        else
            echo "$quoted_name|$base_url$game_url|$ROM_DIR" >> "$DEST_DIR/other.txt"
        fi
    done
}

# Iterate over each base URL and scrape it
for url in "${BASE_URLS[@]}"; do
    scrape_url "$url"
done

echo "Scraping complete!"
