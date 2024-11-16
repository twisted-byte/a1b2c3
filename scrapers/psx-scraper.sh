#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/link/PSX"
ROM_DIR="/userdata/roms/psx"  # Fixed missing closing quote
EXT=".chd"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Function to decode URL (ASCII decode)
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Clear all the text files before writing new data
clear_all_files() {
    rm -f "$DEST_DIR"/*.txt
    echo "All game list files have been cleared."
}

# Clear all text files before starting
clear_all_files

# Fetch the page content
page_content=$(curl -s "$BASE_URL")

# Parse .chd links and decode them
game_urls=($(echo "$page_content" | grep -oP "(?<=href=\")[^\"]*${EXT}"))

# Get the total number of links
total_links=${#game_urls[@]}

# Function to show progress
show_progress() {
    local processed=$1
    local total=$2
    local percent=$(( (processed * 100) / total ))
    echo $percent
}

# Start the dialog gauge
(
    echo "0"  # Start at 0%
    for i in "${!game_urls[@]}"; do
        game_url="${game_urls[$i]}"

        # Decode the URL and check for the region tags and (En) in the decoded text
        decoded_name=$(decode_url "$game_url")

        if [[ "$decoded_name" =~ Europe ]]; then
            # Process games matching the "Europe" criteria

            # Format the entry with backticks around the decoded name
            quoted_name="\`$decoded_name\`"

            # Get the first character of the decoded file name
            first_char="${decoded_name:0:1}"

            # Append to AllGames.txt with both quoted decoded name and original URL
            echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/AllGames.txt"
            
            # Save to the appropriate letter-based file
            if [[ "$first_char" =~ [a-zA-Z] ]]; then
                first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')
                echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/${first_char}.txt"
            elif [[ "$first_char" =~ [0-9] ]]; then
                echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/#.txt"
            else
                echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/other.txt"
            fi
        fi

        # Update the progress
        show_progress $((i + 1)) "$total_links"
        sleep 0.1  # Optional: Slow it down slightly to make the progress more visible
    done

    echo "100"  # End at 100%
) | dialog --title "Scraping Dreamcast Games" --gauge "Please wait while scraping..." 10 70 0

echo "Scraping complete!"
