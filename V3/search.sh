#!/bin/bash

# Exit on error or undefined variable
set -e
set -u

# Function to search for games and display results in a dialog checklist
search_games() {
    # Prompt user for game name to search
    game_name=$(dialog --inputbox "Enter game name to search:" 8 40 2>&1 >/dev/tty)
    if [ -z "$game_name" ]; then
        clear
        exit 1
    fi

    # Search for game in AllGames.txt files under the specified directory
    results=$(find /userdata/system/game-downloader/links -type f -name "AllGames.txt" -exec grep -iHn "$game_name" {} \; 2>/dev/null)
    
    # If no results, show a message and exit
    if [ -z "$results" ]; then
        dialog --msgbox "No games found matching \"$game_name\"." 8 40
        return
    fi

    # Prepare temporary file and checklist items array
    temp_file=$(mktemp)
    checklist_items=()

    # Process each line in the results and prepare the checklist
    while IFS= read -r line; do
        gameline=$(echo "$line" | sed 's/^[^:]*:[^:]*://')
        gamename=$(echo "$gameline" | cut -d'|' -f1 | tr -d '`')
        url=$(echo "$gameline" | cut -d'|' -f2)
        destination=$(echo "$gameline" | cut -d'|' -f3)
        file_path=$(echo "$line" | cut -d':' -f1)
        system=$(basename "$(dirname "$file_path")") # Extract system name

        # Add to temporary file for reference
        echo "$system|$gamename|$url|$destination" >> "$temp_file"

        # Add to checklist with system at the front
        checklist_items+=("$system - $gamename" "" "off")
    done <<< "$results"

    # Show dialog checklist for the user to select games
    selected_games=$(dialog --checklist "Select games to save information:" 15 60 8 "${checklist_items[@]}" 2>&1 >/dev/tty)

    # If the user cancels or exits the checklist, the selected_games will be empty
    if [ -z "$selected_games" ]; then
        clear
        exit 0
    fi

    # Initialize a variable to hold the saved games for dialog display
    saved_games=""

    # Add newlines to file extensions (.zip, .iso, .chd) and system
    selected_games=$(echo "$selected_games" | sed 's/\.zip$/\.zip\n/; s/\.iso$/\.iso\n/; s/\.chd$/\.chd\n/; s/ - /|/')

    # Process selected games
    IFS=$'\n'
    for selected_game in $(echo "$selected_games" | tr -d '"'); do
        # Extract system, game name from the selected item
        system=$(echo "$selected_game" | cut -d'|' -f1)
        game_name=$(echo "$selected_game" | cut -d'|' -f2)

        # Match game name and system in the temporary file
        gameline=$(grep -m 1 "^$system|$game_name|.*" "$temp_file" || true)

        if [ -n "$gameline" ]; then
            echo "$gameline" >> /userdata/system/game-downloader/download.txt
            saved_games+="$system - $game_name\n"
        fi
    done

    if [ -n "$saved_games" ]; then
        dialog --msgbox "The following games were saved to the download queue:\n$saved_games" 15 50
    else
        dialog --msgbox "No games were added to the download queue" 8 40
    fi

    # Clean up temporary file
    rm "$temp_file"

    clear
}

# Execute the search_games function
search_games
