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
        file=$(echo "$line" | cut -d: -f1)      # File name
        gameline=$(echo "$line" | cut -d: -f3-) # The actual game data (everything after the colon)

        # Log the search result before saving it to the temp file
        echo "Search result: $gameline" >> "$DEBUG_LOG"

        # Save the full line (without file name and line number) to the temp file
        echo "$gameline" >> "$temp_file"

        # Extract game name from gameline (keep backticks here for later matching)
        gamename_with_backticks=$(echo "$gameline" | cut -d'|' -f1)

        # Extract folder name for description in the checklist
        folder=$(basename "$(dirname "$file")")

        # Add game name with backticks to checklist items, default "off" selection
        checklist_items+=("$gamename_with_backticks" "$folder" "off")
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

    # Process selected games
    while IFS= read -r selected_game; do
        # Remove quotes and trim leading/trailing spaces from the game name
        selected_game=$(echo "$selected_game" | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Debugging output to check the selected_game value
        echo "Looking for game: $selected_game"
        
        # Escape special characters in the selected game name (including parentheses)
        escaped_game_name=$(echo "$selected_game" | sed 's/[][\.*^$()|?+]/\\&/g')

        # Debugging output to check the escaped game name
        echo "Escaped game name: $escaped_game_name"
        
        # Match the selected game with the line in the temporary file (with backticks)
        gameline=$(grep -m 1 "$escaped_game_name|" "$temp_file" || true)

        # Debugging output
        echo "Matched line from temp_file: $gameline"

        if [ -n "$gameline" ]; then
            # Extract game name (with backticks) before removing backticks
            gamename_with_backticks=$(echo "$gameline" | cut -d'|' -f1)

            # Remove backticks from the game name for the final save
            gamename=$(echo "$gamename_with_backticks" | tr -d '`')

            # Save the full line to download.txt
            echo "$gameline" >> /userdata/system/game-downloader/download.txt
            echo "Saved $gamename to download.txt"

            # Append the saved game info to the saved_games variable
            saved_games+="$gamename\n"
        else
            echo "No matching line found for $selected_game"
        fi
    done <<< "$selected_games"

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
