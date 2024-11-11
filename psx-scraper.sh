#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Scrape the game list and save the file names (not full URLs)
curl -s "$BASE_URL" | grep -oP 'href="([^"]+\.chd)"' | sed -E 's/href="(.*)"/\1/' | while read -r game_url; do
    # Get the file name from the URL (e.g., AmazingGame.chd)
    file_name=$(basename "$game_url")
    # Save the file name to the appropriate letter-based text file
    letter="${file_name:0:1}"  # First letter of the file name
    echo "$file_name" >> "$DEST_DIR/$letter.txt"
done

echo "Scraping complete!"
