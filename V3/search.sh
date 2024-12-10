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
        echo "$gamename|$url|$destination|$system" >> "$temp_file"

        # Add to checklist
        checklist_items+=("$gamename ($system)" "$system" "off")
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

    IFS=$'\n'
    selected_games=$(echo "$selected_games" | sed 's/[()]/\n/g' | sed '/^$/d')

    for selected_game in $selected_games; do
        game_item_cleaned=$(echo "$selected_game" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')

        if [ -z "$game_item_cleaned" ]; then
            continue
        fi

        # Match game name and system in the temporary file
        gameline=$(grep -m 1 "^$game_item_cleaned|" "$temp_file" || true)

        if [ -n "$gameline" ]; then
            echo "$gameline" >> /userdata/system/game-downloader/download.txt
            saved_games+="$game_item_cleaned\n"
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
