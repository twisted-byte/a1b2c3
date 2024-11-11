#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Scrape the game list and save the file names (not full URLs)
curl -s "$BASE_URL" | grep -oP 'href="([^"]+\.chd)"' | sed -E 's/href="(.*)"/\1/' | while read -r game_url; do
    # Get the file name from the URL (e.g., AmazingGame.chd)
    file_name=$(basename "$game_url")
    
    # Get the first character of the file name
    first_char="${file_name:0:1}"
    
    # Always append to AllGames.txt
    echo "$file_name" >> "$DEST_DIR/AllGames.txt"
    
    # Ensure letter files are capitalized and save them to the appropriate letter-based file
    if [[ "$first_char" =~ [a-zA-Z] ]]; then
        first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')  # Capitalize if it's a letter
        # Save to the capitalized letter-based text file (e.g., A.txt, B.txt)
        echo "$file_name" >> "$DEST_DIR/${first_char}.txt"
    elif [[ "$first_char" =~ [0-9] ]]; then
        # Save all number-prefixed files to a single #.txt (e.g., 1.txt, 2.txt)
        echo "$file_name" >> "$DEST_DIR/#.txt"
    else
        # Handle other cases (if needed) – for now, ignoring symbols, etc.
        echo "$file_name" >> "$DEST_DIR/other.txt"
    fi
done

echo "Scraping complete!"
