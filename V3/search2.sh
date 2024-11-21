#!/bin/bash

# Exit on error or undefined variable
set -e
set -u

# Ensure the debug directory exists
DEBUG_LOG="/userdata/system/game-downloader/debug/search_debug.txt"
mkdir -p "$(dirname "$DEBUG_LOG")"

# Redirect all stdout and stderr to the debug log file
exec > >(tee -a "$DEBUG_LOG") 2>&1

# Log a script start message
echo "Starting search2.sh script at $(date)"

# Function to search for games and display results in a dialog checklist
search_games() {
    game_name=$(dialog --inputbox "Enter game name to search:" 8 40 3>&1 1>&2 2>&3 3>&-)
    if [ -z "$game_name" ]; then
        clear
        echo "No game name entered. Exiting."
        exit 1
    fi

    echo "Searching for game name: $game_name"

    # Find and grep for the game name in all .txt files in subdirectories
    results=$(find /userdata/system/game-downloader/links -type f -name "AllGames.txt" -exec grep -iHn "$game_name" {} \;)
    echo "Search results: $results"

    # Prepare temporary file
    temp_file=$(mktemp)

    # Prepare checklist items
    checklist_items=()
    while IFS= read -r line; do
        # Extract file path, line number, and game data
        file=$(echo "$line" | cut -d: -f1)
        gameline=$(echo "$line" | cut -d: -f3)
        gamename=$(echo "$gameline" | cut -d'|' -f1 | tr -d '`')  # Remove backticks
        url=$(echo "$gameline" | cut -d'|' -f2)
        destination=$(echo "$gameline" | cut -d'|' -f3)
        folder=$(basename "$(dirname "$file")")  # Get the folder name (not the full path)

        # Save game name, URL, and destination (no folder) to temporary file
        echo "$gamename|$url|$destination" >> "$temp_file"

        # Add only game name and folder name to checklist
        checklist_items+=("$gamename ($folder)" "off")
    done <<< "$results"

    echo "Checklist items: ${checklist_items[@]}"

    # Show checklist dialog with only game names and folder names
    selected_games=$(dialog --checklist "Select games to save information:" 15 50 8 "${checklist_items[@]}" 3>&1 1>&2 2>&3 3>&-)
    echo "Selected games: $selected_games"

    # Process selected games (from temporary file)
    for selected_game in $selected_games; do
        # Read the corresponding line from the temporary file
        gameline=$(grep -m 1 "^$selected_game|" "$temp_file")

        # Extract game name, URL, and destination (no folder)
        gamename=$(echo "$gameline" | cut -d'|' -f1)
        url=$(echo "$gameline" | cut -d'|' -f2)
        destination=$(echo "$gameline" | cut -d'|' -f3)

        # Save to download.txt (with the selected games, no folder path)
        echo "$gamename|$url|$destination" >> /userdata/system/game-downloader/download.txt
    done

    # Clean up temporary file
    rm "$temp_file"

    clear
    echo "Download process completed."
}

# Main script execution
search_games
