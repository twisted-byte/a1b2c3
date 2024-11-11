#!/bin/bash

# URL of the directory containing the .chd files
BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"

# Function to fetch and filter .chd file list
fetch_chd_list() {
    echo "Fetching .chd file list from $BASE_URL"  # Debug output
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
    # Check if the destination directory exists, create if not
    if [ ! -d "$DEST_DIR" ]; then
        mkdir -p "$DEST_DIR"
        echo "Created directory: $DEST_DIR"  # Debug output
    fi

    local all_file="$DEST_DIR/psx-links-all.txt"
    > "$all_file"  # Clear the all file

    # Create a file for each letter A-Z, check if it exists
    for letter in {a..z}; do
        local file="$DEST_DIR/psx-links-$letter.txt"

        # Create file if it doesn't exist and clear it if it does
        touch "$file"
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
echo "Starting the process..."  # Debug output
files=($(fetch_chd_list))
echo "Found ${#files[@]} .chd files"  # Debug output

# List the files being processed
echo "Extracting game titles:"
for file in "${files[@]}"; do
    echo "Processing: $file"  # Debug output
done

titles=$(extract_game_titles "${files[@]}")

# Write the links to filtered .txt files
write_filtered_files "${files[@]}"

echo "Links have been saved to the corresponding files in $DEST_DIR."  # Debug output
