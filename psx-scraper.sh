#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Function to decode URL-encoded string (ASCII decoding)
decode_url() {
    echo -e "$(echo "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b")"
}

# Initialize empty arrays for each file
declare -A game_lists

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

    # Convert letter to uppercase (to combine lowercase and uppercase into one file)
    letter_upper=$(echo "$letter" | tr 'a-z' 'A-Z')

    # Append the file name to the appropriate letter array
    game_lists["$letter_upper"]+="$file_name"$'\n'
done

# Now overwrite the files with the list of game names for each letter
for letter in "${!game_lists[@]}"; do
    echo -n "${game_lists[$letter]}" > "$DEST_DIR/$letter.txt"  # Overwrite with the entire list of names
done

# Add all decoded games to "All Games.txt" (overwrite to avoid appending)
echo -n "" > "$DEST_DIR/All Games.txt"  # Clear the file first
for game in "${game_lists[@]}"; do
    echo -n "$game" >> "$DEST_DIR/All Games.txt"  # Append all the game names
done

echo "Scraping complete!"
