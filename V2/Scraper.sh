#!/bin/bash

# Define base URLs and destination directory for all systems
declare -A BASE_URLS=(
    ["psx"]="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
    ["dc"]="https://myrient.erista.me/files/Internet%20Archive/chadmaster/dc-chd-zstd-redump/dc-chd-zstd/"
    ["ps2"]="https://myrient.erista.me/files/Redump/Sony%20-%20PlayStation%202/"
    ["gba"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Game%20Boy%20Advance/"
)

# Define filtering rules for each system
declare -A FILTER_RULES=(
    ["psx"]='.*'  # No specific filtering for PSX
    ["dc"]='\(.*Europe.*\|.*UK.*\)'  # DC filter for (En) English, Europe, Australia
    ["ps2"]='\(.*Europe.*\|.*UK.*\)' # No specific filtering for PS2
    ["gba"]='\(.*Europe.*\|.*UK.*\)'  # Filter for (En) English games in GBA
)


# Define file extensions for each system
declare -A FILE_EXTENSIONS=(
    ["psx"]='.chd'  # PSX games are in .chd format
    ["dc"]='.chd'   # DC games are in .chd format
    ["ps2"]='.zip'  # PS2 games are in .iso format
    ["gba"]='.zip'  # GBA games are in .zip format
)

DEST_DIR="/userdata/system/game-downloaderV2/links"  # Common links directory for all systems

# Function to decode URL (ASCII decode)
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Function to find the first alphanumeric character
find_first_alnum() {
    echo "$1" | sed -n 's/[^a-zA-Z0-9]*\([a-zA-Z0-9]\).*/\1/p'
}

# Function to scrape a game system
scrape_game_system() {
    local system=$1
    local base_url=${BASE_URLS[$system]}
    local filter_rule=${FILTER_RULES[$system]}  # Get the filtering rule for the system
    local file_extension=${FILE_EXTENSIONS[$system]}  # Get the file extension for the system
    local system_dir="$DEST_DIR/$system"  # Create a subfolder for each system in the links directory
    local allgames_file="$system_dir/AllGames.txt"

    # Delete the entire 'links' folder and recreate it
    rm -rf "$DEST_DIR"
    mkdir -p "$DEST_DIR"  # Ensure the destination directory exists

    # Initialize arrays to hold the game data for this system
    local game_data=()

    # Scrape and collect game data
    curl -s "$base_url" | grep -oP "href=\"([^\"]+${file_extension})\"" | sed -E 's/href="(.*)"/\1/' | while read -r game_url; do
        # Extract file name from the URL
        file_name=$(basename "$game_url")
        
        # Decode the file name
        decoded_name=$(decode_url "$file_name")
        
        # Check if the game matches the filtering rule
        if [[ "$decoded_name" =~ $filter_rule ]]; then
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
