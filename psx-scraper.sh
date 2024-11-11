#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"
DOWNLOAD_DIR="/userdata/roms/psx"  # Update this to your desired download directory

# Function to decode URL (ASCII decode)
decode_url() {
    # Decode percent-encoded URL
    echo -e "$(echo "$1" | sed 's/%/\\x/g' | xargs -0 printf '%b')"
}

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Scrape the game list and save the decoded file names (not full URLs)
curl -s "$BASE_URL" | grep -oP 'href="([^"]+\.chd)"' | sed -E 's/href="(.*)"/\1/' | while read -r game_url; do
    # Decode the URL to get the human-readable file name
    decoded_name=$(decode_url "$game_url")
    # Get the file name from the decoded URL (e.g., AmazingGame.chd)
    file_name=$(basename "$decoded_name")
    # Save the file name to the appropriate letter-based text file
    letter="${file_name:0:1}"  # First letter of the file name
    echo "$file_name" >> "$DEST_DIR/$letter.txt"
done

# Create All Games list as well
curl -s "$BASE_URL" | grep -oP 'href="([^"]+\.chd)"' | sed -E 's/href="(.*)"/\1/' | while read -r game_url; do
    decoded_name=$(decode_url "$game_url")
    file_name=$(basename "$decoded_name")
    echo "$file_name" >> "$DEST_DIR/All_Games.txt"
done

echo "Scraping complete!"
