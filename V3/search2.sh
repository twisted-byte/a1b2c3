#!/bin/bash

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

    # Prepare checklist items
    checklist_items=()
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d: -f1)
        lineno=$(echo "$line" | cut -d: -f2)
        gameline=$(echo "$line" | cut -d: -f3)
        gamename=$(echo "$gameline" | cut -d'|' -f1)
        checklist_items+=("$file:$lineno" "$gamename" "off" "$file")
    done <<< "$results"

    # Show checklist dialog
    selected_games=$(dialog --checklist "Select games to download:" 15 50 8 "${checklist_items[@]}" 3>&1 1>&2 2>&3 3>&-)

    # Process selected games
    for game in $selected_games; do
        download_game "$game"
    done

    clear
    echo "Download process completed."
}

# Function to download selected games
download_game() {
    file_lineno="$1"
    file=$(echo "$file_lineno" | cut -d: -f1)
    lineno=$(echo "$file_lineno" | cut -d: -f2)

    # Read the specific line from the file
    gameline=$(sed "${lineno}q;d" "$file")
    gamename=$(echo "$gameline" | cut -d'|' -f1 | tr -d '`')
    url=$(echo "$gameline" | cut -d'|' -f2)
    destination=$(echo "$gameline" | cut -d'|' -f3)

    # Append to download.txt
    echo "$gamename|$url|$destination" >> download.txt
}

# Main script execution
search_games