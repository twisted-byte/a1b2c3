#!/bin/bash

# URL of the directory containing the .chd files
BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psx-links"

# Function to fetch and filter .chd file list
fetch_chd_list() {
    curl -s "$BASE_URL" | grep -oP 'href="\K[^"]*' | grep -E "\.chd$" | sort
}

# Function to decode percent-encoded characters (URL decoding)
decode_url() {
    # Use sed to decode any URL-encoded characters (e.g., %20, %21, etc.)
    echo "$1" | sed 's/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g' | xargs -0 printf "%b"
}

# Function to extract clean, decoded game titles from file names
extract_game_titles() {
    local files=("$@")
    declare -A title_to_file_map=()
    for file in "${files[@]}"; do
        # Strip the .chd extension
        title=$(basename "$file" .chd)
        
        # Decode any URL-encoded characters
        title=$(decode_url "$title")
        
        # Remove any content inside parentheses, including the parentheses
        title=$(echo "$title" | sed 's/([^)]*)//g')
        
        # Map the cleaned title to the file
        title_to_file_map["$title"]="$file"
    done

    # Return the title-to-file map
    echo "${!title_to_file_map[@]}"
}

# Function to write games into categorized files (based on first letter)
write_filtered_files() {
    local all_file="$DEST_DIR/psx-links-all.txt"
    > "$all_file"  # Clear the all file

    # Create a file for each letter A-Z
    for letter in {a..z}; do
        local file="$DEST_DIR/psx-links-$letter.txt"
        > "$file"  # Clear the specific letter file

        # Filter titles starting with the current letter and write to file
        for title in "${!title_to_file_map[@]}"; do
            if [[ "${title,,}" =~ ^$letter ]]; then
                echo "${BASE_URL}${title_to_file_map[$title]}" >> "$file"
                echo "${BASE_URL}${title_to_file_map[$title]}" >> "$all_file"  # Also add to the "all" file
            fi
        done
    done
}

# Main process
files=($(fetch_chd_list))
titles=$(extract_game_titles "${files[@]}")

# Write the links to filtered .txt files
write_filtered_files "${files[@]}"

echo "Links have been saved to the corresponding files in $DEST_DIR."
