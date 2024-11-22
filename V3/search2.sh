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
        # Strip file path and line number, leaving only the content after the first colon
       gameline=$(echo "$line" | sed 's/^[^:]*:[^:]*://')

        # Extract game name, URL, and destination from the gameline
        gamename=$(echo "$gameline" | cut -d'|' -f1 | tr -d '`')  # Remove backticks from the game name
        url=$(echo "$gameline" | cut -d'|' -f2)
        destination=$(echo "$gameline" | cut -d'|' -f3)

        # Save the cleaned data to the temporary file
        echo "$gamename|$url|$destination" >> "$temp_file"

       file_path=$(echo "$line" | cut -d':' -f1)  # Extract the file path before the first colon
folder=$(basename "$(dirname "$file_path")")  # Extract the folder name of the file path

        # Add game name to checklist items, default "off" selection
        checklist_items+=("$gamename" "$folder" "off")
    done <<< "$results"

    # Show dialog checklist for the user to select games
    selected_games=$(dialog --checklist "Select games to save information:" 15 80 8 "${checklist_items[@]}" 2>&1 >/dev/tty)

    # If the user cancels or exits the checklist, the selected_games will be empty
    if [ -z "$selected_games" ]; then
        clear
        echo "No games selected. Exiting."
        exit 0
    fi


    # Initialize a variable to hold the saved games for dialog display
    saved_games=""

    # Process each selected game (handle full name including spaces properly)
    IFS=$'\n' # Ensure the game names are handled correctly (one per line, even if they have spaces)
    for selected_game in $selected_games; do
        # Clean the game item (remove unwanted characters and spaces)
        game_item_cleaned=$(echo "$selected_game" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')

        # Match the cleaned game name with the line in the temporary file
        gameline=$(grep -m 1 "^$game_item_cleaned|" "$temp_file" || true)


        if [ -n "$gameline" ]; then
            # Save the full line to download.txt
            echo "$gameline" >> /userdata/system/game-downloader/download.txt

            # Append the saved game info to the saved_games variable
            saved_games+="$game_item_cleaned\n"
        else
            echo "No matching line found for $game_item_cleaned"
        fi
    done

    # If any games were saved, display them in a dialog message box
    if [ -n "$saved_games" ]; then
        dialog --msgbox "The following games were saved to the download queue:\n$saved_games" 15 50
    else
        dialog --msgbox "No games were added to the download queue" 8 40
    fi

    # Clean up temporary file
    rm "$temp_file"

    clear

# Execute the search_games function
search_games
