#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"
ALLGAMES_FILE="$DEST_DIR/AllGames.txt"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Initialize arrays to hold the game data
game_data=()
letter_data=()
number_data=()
other_data=()

# Clear old data files
rm -f "$DEST_DIR/AllGames.txt" "$DEST_DIR/letters.txt" "$DEST_DIR/numbers.txt" "$DEST_DIR/other.txt"

# Function to decode URL (ASCII decode)
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Scrape and collect game data
curl -s "$BASE_URL" | grep -oP 'href="([^"]+\.chd)"' | sed -E 's/href="(.*)"/\1/' | while read -r game_url; do
    # Extract file name from the URL
    file_name=$(basename "$game_url")
    
    # Decode the file name
    decoded_name=$(decode_url "$file_name")
    
    # Encase the decoded name in backticks for formatting
    quoted_name="\`$decoded_name\`"
    
    # Prepare the full game data
    game_entry="$quoted_name|$BASE_URL$game_url"
    
    # Add to the general game list
    game_data+=("$game_entry")
    
    # Categorize by first character
    first_char="${decoded_name:0:1}"
    if [[ "$first_char" =~ [a-zA-Z] ]]; then
        first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')
        letter_data+=("$game_entry")
    elif [[ "$first_char" =~ [0-9] ]]; then
        number_data+=("$game_entry")
    else
        other_data+=("$game_entry")
    fi
done

# Write all game data to the AllGames file
printf "%s\n" "${game_data[@]}" > "$ALLGAMES_FILE"

# Write categorized data to separate files
printf "%s\n" "${letter_data[@]}" > "$DEST_DIR/letters.txt"
printf "%s\n" "${number_data[@]}" > "$DEST_DIR/numbers.txt"
printf "%s\n" "${other_data[@]}" > "$DEST_DIR/other.txt"

echo "All game data has been written to files."
