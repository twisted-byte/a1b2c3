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

# Function to search for games and display results in a dialog menu
search_games() {
    # Prompt user for game name to search
    game_name=$(dialog --inputbox "Enter game name to search:" 8 40 2>&1 >/dev/tty)
    if [ -z "$game_name" ]; then
        clear
        echo "No game name entered. Exiting."
        exit 1
    fi

    # Search for game in AllGames.txt files under the specified directory
    results=$(find /userdata/system/game-downloader/links -type f -name "AllGames.txt" -exec grep -iHn "$game_name" {} \; 2>/dev/null)

    # If no results, show a message and exit
    if [ -z "$results" ]; then
        dialog --msgbox "No games found matching \"$game_name\"." 8 40
        return
    fi

    # Prepare temporary file and menu items array
    temp_file=$(mktemp)
    menu_items=()

    # Process each line in the results and prepare the menu
    while IFS= read -r line; do
        # Strip file path and line number, leaving only the content after the first colon
        gameline=$(echo "$line" | sed 's/^[^:]*:[^:]*://')
        # Extract game name, URL, and destination from the gameline
        gamename=$(echo "$gameline" | cut -d'|' -f1 | tr -d '`')  # Remove backticks from the game name
        url=$(echo "$gameline" | cut -d'|' -f2)
        destination=$(echo "$gameline" | cut -d'|' -f3)
        # Extract the file path and folder name from the line before saving to the temp file
        file_path=$(echo "$line" | cut -d':' -f1)  # Extract the file path before the first colon
        folder=$(basename "$(dirname "$file_path")")  # Extract the folder name of the file path
        
        # Save the folder, game name, URL, and destination to the temporary file
        echo "$folder - $gamename|$url|$destination" >> "$temp_file"
        
        # Add game name to menu items
        menu_items+=("$folder - $gamename" "$folder - $gamename")
    done <<< "$results"

    # Debugging: Print the contents of the temporary file
    echo "Contents of temp file ($temp_file):"
    cat "$temp_file"
    echo "End of temp file contents."

    # Show dialog menu for the user to select a game
    selected_game=$(dialog --menu "Select a game to save information:" 15 60 8 "${menu_items[@]}" 2>&1 >/dev/tty)

    # If the user cancels or exits the menu, the selected_game will be empty
    if [ -z "$selected_game" ]; then
        clear
        echo "No game selected. Exiting."
        exit 0
    fi

    # Debugging output
    echo "Processing selected game: $selected_game"

    # Match the selected game with the exact line in the temporary file
    gameline=$(grep -m 1 -F "$selected_game" "$temp_file" || true)

    if [ -n "$gameline" ]; then
        gamename2=$(echo "$gameline" | cut -d'|' -f1 | sed 's/^[^ ]* - //')  # Cleaned game name
        url2=$(echo "$gameline" | cut -d'|' -f2)
        destination2=$(echo "$gameline" | cut -d'|' -f3)

        # Save the exact match game line to download.txt
        echo "$gamename2|$url2|$destination2" >> /userdata/system/game-downloader/download.txt
        echo "Saved $selected_game to download.txt"

        # Display the saved game
        dialog --msgbox "The following game was saved to the download queue:\n$selected_game" 15 50
    else
        echo "No exact match found for $selected_game"
        dialog --msgbox "No exact match found for the selected game." 8 40
    fi

    # Clean up temporary file
    rm "$temp_file"

    clear
}

# Execute the search_games function
search_games
