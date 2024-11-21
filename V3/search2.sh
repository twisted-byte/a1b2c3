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
    game_name=$(dialog --inputbox "Enter game name to search:" 8 40 2>&1 >/dev/tty)
    if [ -z "$game_name" ]; then
        clear
        echo "No game name entered. Exiting."
        exit 1
    fi

    echo "Searching for game name: $game_name"
    results=$(find /userdata/system/game-downloader/links -type f -name "AllGames.txt" -exec grep -iHn "$game_name" {} \;)
    
    if [ -z "$results" ]; then
        dialog --msgbox "No games found matching \"$game_name\"." 8 40
        return
    fi

    echo "Search results: $results"
    temp_file=$(mktemp)
    checklist_items=()

    while IFS= read -r line; do
        file=$(echo "$line" | cut -d: -f1)
        gameline=$(echo "$line" | cut -d: -f3)
        gamename=$(echo "$gameline" | cut -d'|' -f1 | tr -d '`')
        url=$(echo "$gameline" | cut -d'|' -f2)
        destination=$(echo "$gameline" | cut -d'|' -f3)
        folder=$(basename "$(dirname "$file")")

        echo "$gamename|$url|$destination" >> "$temp_file"
        checklist_items+=("$gamename" "$folder" "off")
    done <<< "$results"

    selected_games=$(dialog --checklist "Select games to save information:" 15 50 8 "${checklist_items[@]}" 2>&1 >/dev/tty)
    echo "Selected games: $selected_games"

    for selected_game in $selected_games; do
        gameline=$(grep -m 1 "^$selected_game|" "$temp_file")
        gamename=$(echo "$gameline" | cut -d'|' -f1)
        url=$(echo "$gameline" | cut -d'|' -f2)
        destination=$(echo "$gameline" | cut -d'|' -f3)

        echo "$gamename|$url|$destination" >> /userdata/system/game-downloader/download.txt
    done

    rm "$temp_file"
    clear
    echo "Download process completed."
}
