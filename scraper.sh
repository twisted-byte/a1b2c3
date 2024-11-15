#!/bin/bash

# Define base URLs and destination directory for all systems
declare -A BASE_URLS=(
    ["psx"]="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
    ["dc"]="https://myrient.erista.me/files/Internet%20Archive/chadmaster/dc-chd-zstd-redump/dc-chd-zstd/"
    ["ps2"]="https://myrient.erista.me/files/Redump/Sony%20-%20PlayStation%202/"
    ["gba"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Game%20Boy%20Advance/"
)

DEST_DIR="/userdata/system/game-downloader/links"  # Common links directory for all systems

# Function to decode URL (ASCII decode)
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Function to find the first alphanumeric character
find_first_alnum() {
    # Extract the first alphanumeric character (A-Z, a-z, 0-9) from the decoded name
    echo "$1" | sed -n 's/[^a-zA-Z0-9]*\([a-zA-Z0-9]\).*/\1/p'
}

# Function to scrape a game system
scrape_game_system() {
    local system=$1
    local base_url=${BASE_URLS[$system]}
    local system_dir="$DEST_DIR/$system"  # Create a subfolder for each system in the links directory
    local allgames_file="$system_dir/AllGames.txt"

    # Ensure the destination directory for this system exists
    mkdir -p "$system_dir"

    # Initialize arrays to hold the game data for this system
    local game_data=()

    # Clear old data files for this system
    rm -f "$allgames_file"
    for letter in {A..Z}; do
        rm -f "$system_dir/$letter.txt"
    done
    rm -f "$system_dir/#.txt"

    # Scrape and collect game data
    curl -s "$base_url" | grep -oP 'href="([^"]+\.chd)"' | sed -E 's/href="(.*)"/\1/' | while read -r game_url; do
        # Extract file name from the URL
        file_name=$(basename "$game_url")
        
        # Decode the file name
        decoded_name=$(decode_url "$file_name")
        
        # Encase the decoded name in backticks for formatting
        quoted_name="\`$decoded_name\`"
        
        # Prepare the full game data
        game_entry="$quoted_name|$base_url$game_url"
        
        # Add to the general game list
        game_data+=("$game_entry")
        
        # Find the first alphanumeric character
        first_alnum=$(find_first_alnum "$decoded_name")
        
        # If an alphanumeric character is found, write to the corresponding file
        if [[ "$first_alnum" =~ [a-zA-Z] ]]; then
            first_alnum=$(echo "$first_alnum" | tr 'a-z' 'A-Z')  # Capitalize the letter
            echo "$game_entry" >> "$system_dir/$first_alnum.txt"
        elif [[ "$first_alnum" =~ [0-9] ]]; then
            echo "$game_entry" >> "$system_dir/#.txt"
        fi
    done

    # Write all game data to the AllGames file
    printf "%s\n" "${game_data[@]}" > "$allgames_file"

    echo "Scraping and writing complete for $system!"
}

# Scrape each game system and batch write the results
for system in "${!BASE_URLS[@]}"; do
    scrape_game_system "$system"
done

echo "All systems have been scraped and batch written to the 'links' directory."
