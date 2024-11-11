#!/bin/bash

# URL of the directory containing the .chd files
BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"

# Function to fetch and filter .chd file list
fetch_chd_list() {
    echo "Fetching .chd file list from $BASE_URL"  # Debug output
    local file_list
    file_list=$(curl -s "$BASE_URL" | grep -oP 'href="\K[^"]*' | grep -E "\.chd$" | sort)
    
    if [ -z "$file_list" ]; then
        echo "No .chd files found at $BASE_URL"  # Debug output
        exit 1
    fi

    echo "$file_list"
}

# Function to decode percent-encoded characters (URL decoding)
decode_url() {
    echo "$1" | sed 's/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g' | xargs -0 printf "%b"
}

# Function to extract clean, decoded game titles from file names
extract_game_titles() {
    local files=("$@")
    declare -A title_to_file_map=()
    
    for file in "${files[@]}"; do
        # Strip the .chd extension
        local title=$(basename "$file" .chd)
        
        # Decode any URL-encoded characters
        title=$(decode_url "$title")
        
        # Remove any content inside parentheses, including the parentheses
        title=$(echo "$title" | sed 's/([^)]*)//g')
        
        # Map the cleaned title to the file
        title_to_file_map["$title"]="$file"
    done

    # Return the title-to-file map
    echo "${title_to_file_map[@]}"  # Return the values (file names)
}

# Function to write games into categorized files (based on first letter)
write_filtered_files() {
    local title_to_file_map="$1"
    
    # Check if the destination directory exists, create if not
    if [ ! -d "$DEST_DIR" ]; then
        mkdir -p "$DEST_DIR"
        echo "Created directory: $DEST_DIR"  # Debug output
    fi

    local all_file="$DEST_DIR/psx-links-all.txt"
    > "$all_file"  # Clear the all file

    # Create a file for each letter A-Z
    for letter in {a..z}; do
        local file="$DEST_DIR/psx-links-$letter.txt"
        > "$file"  # Clear the specific letter file

        # Filter titles starting with the current letter and write to file
        for title in ${!title_to_file_map[@]}; do
            if [[ "${title,,}" =~ ^$letter ]]; then
                echo "${BASE_URL}${title_to_file_map[$title]}" >> "$file"
                echo "${BASE_URL}${title_to_file_map[$title]}" >> "$all_file"  # Also add to the "all" file
            fi
        done
    done
}

# Main process
echo "Starting the process..."  # Debug output
files=($(fetch_chd_list))
echo "Found ${#files[@]} .chd files"  # Debug output

# List the files being processed
echo "Extracting game titles:"
for file in "${files[@]}"; do
