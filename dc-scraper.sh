#!/bin/bash

# Base URL and destination directory
BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/dc-chd-zstd-redump/dc-chd-zstd/"
DEST_DIR="/userdata/system/game-downloader/dclinks"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Function to decode URL (ASCII decode)
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Clear all text files before writing new data
rm -f "$DEST_DIR"/*.txt

# Fetch the page content
page_content=$(curl -s "$BASE_URL")

# Parse .chd links, decode them, and check for "(UK)" or "(Europe)" in the decoded name
echo "$page_content" | grep -oP '(?<=href=")[^"]*\.chd' | while read -r game_url; do
    # Decode the URL and check for the region tags in decoded text
    decoded_name=$(decode_url "$game_url")

    # Only process files that contain "(UK)" or "(Europe)" in the decoded name
    if [[ "$decoded_name" =~ \(UK\) || "$decoded_name" =~ \(Europe\) ]]; then
        # Format the entry with backticks around the decoded name
        quoted_name="\`$decoded_name\`"

        # Get the first character of the decoded file name
        first_char="${decoded_name:0:1}"
        
        # Append to AllGames.txt with both quoted decoded name and original URL
        echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/AllGames.txt"
        
        # Save to the appropriate letter-based file
        if [[ "$first_char" =~ [a-zA-Z] ]]; then
            first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')
            echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/${first_char}.txt"
        elif [[ "$first_char" =~ [0-9] ]]; then
            echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/#.txt"
        else
            echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/other.txt"
        fi
    fi
done

echo "Scraping complete for (UK) and (Europe) files!"
