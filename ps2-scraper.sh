#!/bin/bash

# Base URL and destination directory
BASE_URL="https://myrient.erista.me/files/Redump/Sony%20-%20PlayStation%202/"
DEST_DIR="/userdata/system/game-downloader/ps2links"
DEBUG_LOG="$DEST_DIR/debug.txt"  # Log file to capture debug information

# Ensure the destination directory and log file exist
mkdir -p "$DEST_DIR"
touch "$DEBUG_LOG"

# Function to log debug messages
log_debug() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$DEBUG_LOG"
}

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

# Fetch the page content and log
page_content=$(curl -s "$BASE_URL")
log_debug "Fetched page content from $BASE_URL"

# Parse .zip links, decode them, and check for region tags and ignore "(Demo)"
echo "$page_content" | grep -oP '(?<=href=")[^"]*\.zip' | while read -r game_url; do
    # Decode the URL and check for the region tags in decoded text
    decoded_name=$(decode_url "$game_url")
    log_debug "Decoded name: $decoded_name"

    # Only process files that contain "(En)" or "(Europe)" or "(Europe, Australia)" and do not contain "(Demo)"
    if [[ ("$decoded_name" =~ \(.*[Ee][Nn].*\) || "$decoded_name" =~ \(.*Europe.*\)) && ! "$decoded_name" =~ \(.*Demo.*\) ]]; then
        log_debug "Matched region in decoded name: $decoded_name"

        # Format the entry with backticks around the decoded name
        quoted_name="\`$decoded_name\`"

        # Get the first character of the decoded file name
        first_char="${decoded_name:0:1}"
        
        # Append to AllGames.txt with both quoted decoded name and original URL
        echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/AllGames.txt"
        log_debug "Added to AllGames.txt: $quoted_name|$BASE_URL$game_url"
        
        # Save to the appropriate letter-based file
        if [[ "$first_char" =~ [a-zA-Z] ]]; then
            first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')
            echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/${first_char}.txt"
            log_debug "Added to ${first_char}.txt: $quoted_name|$BASE_URL$game_url"
        elif [[ "$first_char" =~ [0-9] ]]; then
            echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/#.txt"
            log_debug "Added to #.txt: $quoted_name|$BASE_URL$game_url"
        else
            echo "$quoted_name|$BASE_URL$game_url" >> "$DEST_DIR/other.txt"
            log_debug "Added to other.txt: $quoted_name|$BASE_URL$game_url"
        fi
    else
        log_debug "No region match for decoded name: $decoded_name"
    fi
done

log_debug "Scraping complete!"
echo "Scraping complete for files with (En), (Europe), or (Europe, Australia), and excluding (Demo) files!"
