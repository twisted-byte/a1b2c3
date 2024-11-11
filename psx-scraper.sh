#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Function to decode URL-encoded string (ASCII decoding)
decode_url() {
    echo -e "$(echo "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b")"
}

# Scrape the game list and save the decoded file names (not full URLs)
curl -s "$BASE_URL" | grep -oP 'href="([^"]+\.chd)"' | sed -E 's/href="(.*)"/\1/' | while read -r game_url; do
    # Decode the game name from the URL
    decoded_name=$(decode_url "$game_url")
    # Get the file name (e.g., AmazingGame.chd)
    file_name=$(basename "$decoded_name")
    
    # Get the first letter or number of the file name
    letter="${file_name:0:1}"

    # If the first character is a digit, use #.txt instead of the digit-based text files
    if [[ "$letter" =~ ^[0-9]$ ]]; then
        letter="#"
    fi

    # Append the decoded file names to the appropriate letter-based text file
    echo "$file_name" > "$DEST_DIR/$letter.txt"  # Using '>' to replace the file
done

# Add all decoded games to "All Games.txt" (appending to avoid overwriting the entire file)
curl -s "$BASE_URL" | grep -oP 'href="([^"]+\.chd)"' | sed -E 's/href="(.*)"/\1/' | while read -r game_url; do
    # Decode the game name from the URL
    decoded_name=$(decode_url "$game_url")
    file_name=$(basename "$decoded_name")
    echo "$file_name" > "$DEST_DIR/All Games.txt"  # Using '>' to replace the file
done

echo "Scraping complete!"
