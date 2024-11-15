#!/bin/bash

# Predefined systems and configurations
declare -A SYSTEMS
SYSTEMS=(
    ["Nintendo Game Boy Advance"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Game%20Boy%20Advance/"
    ["PSX"]="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
    ["PS2"]="https://myrient.erista.me/files/Redump/Sony%20-%20PlayStation%202/"
    ["Dreamcast"]="https://myrient.erista.me/files/Internet%20Archive/chadmaster/dc-chd-zstd-redump/dc-chd-zstd/"
["Nintendo 64"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Nintendo%2064%20(BigEndian)/"
)

# List of file extensions to scrape
FILE_EXTENSIONS=(".chd" ".zip" ".iso")  # Add other extensions as needed

# Destination directory (can be adjusted for different systems)
DEST_DIR_BASE="/userdata/system/game-downloaderV2/links"

# Function to decode URL (ASCII decode)
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Function to clear all the text files before writing new data
clear_all_files() {
    rm -f "$DEST_DIR"/*.txt
    echo "All game list files have been cleared."
}

# Loop through each system and scrape accordingly
for SYSTEM in "${!SYSTEMS[@]}"; do
    # Set the base URL and destination directory based on the system
    BASE_URL="${SYSTEMS[$SYSTEM]}"
    DEST_DIR="$DEST_DIR_BASE/$SYSTEM"

    # Ensure the destination directory exists
    mkdir -p "$DEST_DIR"

    echo "Starting scrape for $SYSTEM..."

    # Clear all text files before starting new scrape
    clear_all_files

    # Fetch the page content
    page_content=$(curl -s "$BASE_URL")

    # Loop through each file extension
    for EXT in "${FILE_EXTENSIONS[@]}"; do
        # Parse links with the current file extension, decode them, and check for region tags and exclude "(Demo)"
        echo "$page_content" | grep -oP "(?<=href=\")[^\"]*$EXT" | while read -r game_url; do
            # Decode the URL and check for the region tags in decoded text
            decoded_name=$(decode_url "$game_url")

            # Check if decoded name contains "Europe" or "UK", and does not contain "Demo"
            if [[ ("$decoded_name" =~ Europe || "$decoded_name" =~ UK) && ! "$decoded_name" =~ Demo ]]; then

                # Format the entry with backticks around the decoded name
                quoted_name="\`$decoded_name\`"

                # Get the first character of the decoded file name
                first_char="${decoded_name:0:1}"
                
                # Append to AllGames.txt with both quoted decoded name and original URL
                echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/AllGames.txt"
                
                # Save to the appropriate letter-based file
                if [[ "$first_char" =~ [a-zA-Z] ]]; then
                    first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')
                    echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/${first_char}.txt"
                elif [[ "$first_char" =~ [0-9] ]]; then
                    echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/#.txt"
                else
                    echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/other.txt"
                fi
            fi # Closing the 'if' block
        done
    done

    echo "Scraping complete for $SYSTEM!"
done
