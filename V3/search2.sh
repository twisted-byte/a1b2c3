#!/bin/bash

# Exit on error or undefined variable
set -e
set -u

# Function to search for games and display results in a dialog checklist
search_games() {
    game_name=$(dialog --inputbox "Enter game name to search:" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [ -z "$game_name" ]; then
        clear
        echo "No game name entered. Exiting."
        exit 1
    fi

    # Find and grep for the game name in all .txt files under /userdata/system/game-downloader/links
    results=$(find /userdata/system/game-downloader/links -type f -name "*.txt" -exec grep -Hn "$game_name" {} \;)

    if [ -z "$results" ]; then
        dialog --msgbox "No matching games found!" 8 40
        clear
        exit 1
    fi

    # Prepare a temporary file to store game details (URL and destination)
    temp_file=$(mktemp)

    while IFS= read -r line; do
        file=$(echo "$line" | cut -d: -f1)
        lineno=$(echo "$line" | cut -d: -f2)
        gameline=$(echo "$line" | cut -d: -f3)
        gamename=$(echo "$gameline" | awk -F'|' '{print $1}')
        url=$(echo "$gameline" | awk -F'|' '{print $2}')
        destination=$(echo "$gameline" | awk -F'|' '{print $3}')
        
        # Save game details (URL and destination) to temporary file
        echo "$gamename|$url|$destination" >> "$temp_file"
    done <<< "$results"

    # Show checklist dialog to select games
    selected_games=$(dialog --checklist "Select games to save information:" 15 50 8 --file "$temp_file" 3>&1 1>&2 2>&3 3>&-)
    rm "$temp_file"

    # Process selected games and call download_game function for each
    for game in $selected_games; do
        download_game "$game"
    done

    clear
    echo "Game information saved."
}

# Function to save selected game information (no actual download, just saving details)
download_game() {
    # Pull game information from the temporary file
    game_details="$1"
    
    # Extract the game details
    gamename=$(echo "$game_details" | awk -F'|' '{print $1}')
    url=$(echo "$game_details" | awk -F'|' '{print $2}')
    destination=$(echo "$game_details" | awk -F'|' '{print $3}')

    # Save the game information to download.txt in the /userdata/system/game-downloader directory
    echo "$gamename|$url|$destination" >> /userdata/system/game-downloader/download.txt
}

# Main script execution
search_games
