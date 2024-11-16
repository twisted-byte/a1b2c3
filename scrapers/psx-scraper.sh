#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/link/PSX"
ROM_DIR="/userdata/roms/psx"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Function to decode URL (ASCII decode)
decode_url() {
    # Decode percent-encoded string
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Clear all the text files before writing new data
clear_all_files() {
    rm -f "$DEST_DIR"/*.txt
    echo "All game list files have been cleared."
}

# Clear all text files before starting
clear_all_files

# Scrape the game list and save the file names (not full URLs)
curl -s "$BASE_URL" | grep -oP 'href="([^"]+\.chd)"' | sed -E 's/href="(.*)"/\1/' | while read -r game_url; do
    # Get the file name from the URL (e.g., AmazingGame.chd)
    file_name=$(basename "$game_url")

    # Decode the file name (ASCII decode if needed)
    decoded_name=$(decode_url "$file_name")

    # Encase the decoded name in backticks
    quoted_name="\`$decoded_name\`"

    # Get the first character of the decoded file name
    first_char="${decoded_name:0:1}"

    # Always append to AllGames.txt with both quoted decoded name and original URL
    echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/AllGames.txt"

    # Ensure letter files are capitalized and save them to the appropriate letter-based file
    if [[ "$first_char" =~ [a-zA-Z] ]]; then
        first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')  # Capitalize if it's a letter
        # Save to the capitalized letter-based text file (e.g., A.txt, B.txt)
        echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/${first_char}.txt"
    elif [[ "$first_char" =~ [0-9] ]]; then
        # Save all number-prefixed files to a single #.txt (e.g., 1.txt, 2.txt)
        echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/#.txt"
    else
        # Handle other cases (if needed) – for now, ignoring symbols, etc.
        echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/other.txt"
    fi
done

echo "Scraping complete!"
