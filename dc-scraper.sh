#!/bin/bash

# Base URL and destination directory
BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/dc-chd-zstd-redump/dc-chd-zstd/"
DEST_DIR="/userdata/system/game-downloader/dclinks"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Function to decode URL (ASCII decode)
decode_url() {
    # Decode percent-encoded string
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Clear all text files before writing new data
clear_all_files() {
    rm -f "$DEST_DIR"/*.txt
    echo "All game list files have been cleared."
}

# Clear all text files before starting
clear_all_files

# Fetch the page content
page_content=$(curl -s "$BASE_URL")

# Parse only .chd links that contain "(UK)" or "(Europe)"
echo "$page_content" | grep -oP '(?<=href=")[^"]*\.(UK|Europe)\.chd' | while read -r game_url; do
    # Get the file name from the URL (e.g., GameName (Europe).chd)
    file_name=$(basename "$game_url")
    
    # Decode the file name if necessary
    decoded_name=$(decode_url "$file_name")
    
    # Encase the decoded name in backticks
    quoted_name="\`$decoded_name\`"
    
    # Get the first character of the decoded file name
    first_char="${decoded_name:0:1}"
    
    # Always append to AllGames.txt with both quoted decoded name and original URL
    echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/AllGames.txt"
    
    # Save to a letter-based file (e.g., A.txt, B.txt) based on the first character of the name
    if [[ "$first_char" =~ [a-zA-Z] ]]; then
        first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')  # Capitalize if it's a letter
        echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/${first_char}.txt"
    elif [[ "$first_char" =~ [0-9] ]]; then
        # Save number-prefixed files to #.txt
        echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/#.txt"
    else
        # Save files with other starting characters to other.txt
        echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/other.txt"
    fi
done

echo "Scraping complete for (UK) and (Europe) files!"
