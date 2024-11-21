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
    # Prompt user for game name to search
    game_name=$(dialog --inputbox "Enter game name to search:" 8 40 2>&1 >/dev/tty)
    if [ -z "$game_name" ]; then
        clear
        echo "No game name entered. Exiting."
        exit 1
    fi

    echo "Searching for game name: $game_name"

    # Search for game in AllGames.txt files under the specified directory
    results=$(find /userdata/system/game-downloader/links -type f -name "AllGames.txt" -exec grep -iHn "$game_name" {} \;)
    
    # If no results, show a message and exit
    if [ -z "$results" ]; then
        dialog --msgbox "No games found matching \"$game_name\"." 8 40
        return
    fi

    echo "Search results: $results"

    # Prepare temporary file and checklist items array
    temp_file=$(mktemp)
    checklist_items=()

    # Process each line in the results and prepare the checklist
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d: -f1)
        gameline=$(echo "$line" | cut -d: -f3)
        
        # Extract game name from gameline (remove backticks if present)
        gamename=$(echo "$gameline" | cut -d'|' -f1 | tr -d '`')

        # Save the full gameline to the temporary file
        echo "$gameline" >> "$temp_file"

        # Extract folder name for description in the checklist
        folder=$(basename "$(dirname "$file")")

        # Add game name to checklist items, default "off" selection
        checklist_items+=("$gamename" "$folder" "off")
    done <<< "$results"

    # Show dialog checklist for the user to select games
    selected_games=$(dialog --checklist "Select games to save information:" 15 50 8 "${checklist_items[@]}" 2>&1 >/dev/tty)

    # If the user cancels or exits the checklist, the selected_games will be empty
    if [ -z "$selected_games" ]; then
        clear
        echo "No games selected. Exiting."
        exit 0
    fi

    echo "Selected games: $selected_games"

    # Initialize a variable to hold the saved games for dialog display
    saved_games=""

# Process each line in the results and prepare the checklist
while IFS= read -r line; do
    file=$(echo "$line" | cut -d: -f1)
    gameline=$(echo "$line" | cut -d: -f3)
    
    # Extract game name from gameline (remove backticks if present)
    gamename=$(echo "$gameline" | cut -d'|' -f1 | tr -d '`')

    # Save the full gameline to the temporary file
    echo "$gameline" >> "$temp_file"
    
    # Log the gameline that is being saved to temp_file
    echo "Saved to temp_file: $gameline" >> "$DEBUG_LOG"

    # Extract folder name for description in the checklist
    folder=$(basename "$(dirname "$file")")

    # Add game name to checklist items, default "off" selection
    checklist_items+=("$gamename" "$folder" "off")
done <<< "$results"
    # If any games were saved, display them in a dialog message box
    if [ -n "$saved_games" ]; then
        dialog --msgbox "The following games were saved to the download queue:\n$saved_games" 15 50
    else
        dialog --msgbox "No games were added to the download queue" 8 40
    fi

    # Clean up temporary file
    rm "$temp_file"

    clear
    echo "Download process completed."
}

# Execute the search_games function
search_games
