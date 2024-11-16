#!/bin/bash

# Base URL and destination directory
BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/dc-chd-zstd-redump/dc-chd-zstd/"
DEST_DIR="/userdata/system/game-downloader/links/Dreamcast"
ROM_DIR="/userdata/roms/dreamcast"  # Fixed missing closing quote
EXT=".chd"

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

        # Log the progress for debugging
        echo "Processing game $i / $total_links"
        progress=$(show_progress $((i + 1)) "$total_links")
        echo "Progress: $progress"
        
        # Update the progress
        echo $progress
        sleep 0.1  # Optional: Slow it down slightly to make the progress more visible
    done

    echo "100"  # End at 100%
) | dialog --title "Scraping Dreamcast Games" --gauge "Please wait while scraping..." 10 70 0

echo "Scraping complete!"
