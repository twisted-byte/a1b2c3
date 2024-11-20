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

    # Find and grep for the game name in all .txt files in subdirectories
    results=$(find . -type f -name "*.txt" -exec grep -Hn "$game_name" {} \;)

    if [ -z "$results" ]; then
        dialog --msgbox "No matching games found!" 8 40
        clear
        exit 1
    fi

    # Prepare checklist items
    checklist_file=$(mktemp)
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d: -f1)
        lineno=$(echo "$line" | cut -d: -f2)
        gameline=$(echo "$line" | cut -d: -f3)
        gamename=$(echo "$gameline" | awk -F'|' '{print $1}')
        echo "$file:$lineno \"$gamename\" off" >> "$checklist_file"
    done <<< "$results"

    # Show checklist dialog to select games
    selected_games=$(dialog --checklist "Select games to save information:" 15 50 8 --file "$checklist_file" 3>&1 1>&2 2>&3 3>&-)
    rm "$checklist_file"

    # Process selected games and save the information
    for game in $selected_games; do
        save_game_info "$game"
    done

    clear
    echo "Game information saved."
}

# Function to save selected game information (no downloading)
save_game_info() {
    file_lineno="$1"
    file=$(echo "$file_lineno" | cut -d: -f1)
    lineno=$(echo "$file_lineno" | cut -d: -f2)

    # Read the specific line from the file
    gameline=$(sed "${lineno}q;d" "$file")
    gamename=$(echo "$gameline" | awk -F'|' '{print $1}')
    url=$(echo "$gameline" | awk -F'|' '{print $2}')
    destination=$(echo "$gameline" | awk -F'|' '{print $3}')

    # Save the game information to download.txt
    echo "$gamename|$url|$destination" >> download.txt
}

# Main script execution
search_games
