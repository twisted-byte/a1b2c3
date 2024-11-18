#!/bin/bash

DEST_DIR="/userdata/system/game-downloader/links"
ALLGAMES_FILE="$DEST_DIR/AllGames.txt"

# Ensure the directory exists
mkdir -p "$DEST_DIR"

# Arrays for tracking games
added_games=()
skipped_games=()

# Function to clean up game names
clean_name() {
    echo "$1" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g'
}

# Function to download a game
download_game() {
    local decoded_name="$1"
    decoded_name_cleaned=$(clean_name "$decoded_name")

    # Check if the game already exists or is queued
    if [[ -f "$DEST_DIR/$decoded_name_cleaned" ]] || grep -q "$decoded_name_cleaned" "/userdata/system/game-downloader/download.txt"; then
        skipped_games+=("$decoded_name_cleaned")
        return
    fi

    # Extract URL and directory from AllGames.txt
    game_info=$(grep -F "$decoded_name_cleaned" "$ALLGAMES_FILE")
    game_url=$(echo "$game_info" | cut -d '|' -f 2)
    game_download_dir=$(echo "$game_info" | cut -d '|' -f 3)

    if [[ -z "$game_url" || -z "$game_download_dir" ]]; then
        dialog --infobox "Error: Could not find URL for '$decoded_name_cleaned'." 5 40
        sleep 2
        return
    fi

    # Add to download queue
    echo "$decoded_name_cleaned|$game_url|$game_download_dir" >> "/userdata/system/game-downloader/download.txt"
    added_games+=("$decoded_name_cleaned")
}

# Function to search and display games
search_games() {
    local search_term="$1"
    local results=()
    IFS=$'\n'

    # Search AllGames.txt in subfolders
    for file in $(find "$DEST_DIR" -type f -name "AllGames.txt"); do
        folder_name=$(basename "$(dirname "$file")")
        grep -i "$search_term" "$file" | while IFS="|" read -r decoded_name encoded_url game_download_dir; do
            game_name_cleaned=$(clean_name "$decoded_name")
            results+=("$folder_name - $game_name_cleaned" "$decoded_name" off)
        done
    done

    # Display results in dialog
    if [[ ${#results[@]} -gt 0 ]]; then
        selected_games=$(dialog --title "Search Results" --checklist "Choose games to download" 25 70 10 "${results[@]}" 3>&1 1>&2 2>&3)
        [[ $? -ne 0 ]] && return

        for game in $selected_games; do
            download_game "$(clean_name "$game")"
        done
    else
        dialog --infobox "No games found for '$search_term'." 5 40
        sleep 2
    fi
}

# Main loop
while true; do
    search_term=$(dialog --inputbox "Enter search term" 10 50 3>&1 1>&2 2>&3)
    [[ -z "$search_term" ]] && break

    search_games "$search_term"

    # Notify user of results
    [[ ${#added_games[@]} -gt 0 ]] && dialog --msgbox "Added games:\n$(printf "%s\n" "${added_games[@]}")" 10 50
    [[ ${#skipped_games[@]} -gt 0 ]] && dialog --msgbox "Skipped games:\n$(printf "%s\n" "${skipped_games[@]}")" 10 50

    # Ask to continue
    dialog --title "Continue?" --yesno "Search for more games?" 7 50 || break
done

echo "Goodbye!"
