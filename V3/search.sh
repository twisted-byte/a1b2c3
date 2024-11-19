#!/bin/bash

# Paths to files and logs
DEST_DIR="/userdata/system/game-downloader/links"
ALLGAMES_FILE="$DEST_DIR/AllGames.txt"
DEBUG_LOG="/userdata/system/game-downloader/debug/search_debug.txt"

# Ensure the debug directory exists
mkdir -p "$(dirname "$DEBUG_LOG")"

# Clear debug log for a fresh session
if [ -f "$DEBUG_LOG" ]; then
    echo "Clearing debug log for the new session." >> "$DEBUG_LOG"
    > "$DEBUG_LOG"
fi

# Redirect stdout and stderr to debug log
# exec > "$DEBUG_LOG" 2>&1

# Log script start
echo "Starting search script at $(date)"

# Arrays for tracking games
added_games=()
skipped_games=()

# Function to clean up game names
clean_name() {
    echo "$1" | sed 's/[\\\"]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g'
}

# Function to download a game
download_game() {
    local decoded_name="$1"
    decoded_name_cleaned=$(clean_name "$decoded_name")

    echo "Checking if game already exists or is queued: $decoded_name_cleaned"

    if [[ -f "$DEST_DIR/$decoded_name_cleaned" ]] || grep -q "$decoded_name_cleaned" "/userdata/system/game-downloader/download.txt"; then
        skipped_games+=("$decoded_name_cleaned")
        echo "Game already exists or is queued: $decoded_name_cleaned"
        return
    fi

    echo "Extracting URL and directory for $decoded_name_cleaned"
    game_info=$(grep -F "$decoded_name_cleaned" "$ALLGAMES_FILE")
    game_url=$(echo "$game_info" | cut -d '|' -f 2)
    game_download_dir=$(echo "$game_info" | cut -d '|' -f 3)

    if [[ -z "$game_url" || -z "$game_download_dir" ]]; then
        dialog --infobox "Error: Could not find URL for '$decoded_name_cleaned'." 5 40
        echo "Error: Could not find URL for '$decoded_name_cleaned'"
        sleep 2
        return
    fi

    echo "Adding to download queue: $decoded_name_cleaned|$game_url|$game_download_dir"
    echo "$decoded_name_cleaned|$game_url|$game_download_dir" >> "/userdata/system/game-downloader/download.txt"
    added_games+=("$decoded_name_cleaned")
}

# Function to search and display games
search_games() {
    local search_term="$1"
    local results=()
    IFS=$'\n'

    search_term=$(echo "$search_term" | tr '[:upper:]' '[:lower:]')
    echo "Searching for term: $search_term" &

    for file in $(find "$DEST_DIR" -type f -name "AllGames.txt"); do
        folder_name=$(basename "$(dirname "$file")")
        echo "Searching in file: $file" &
        while IFS="|" read -r decoded_name encoded_url game_download_dir; do
            decoded_name_lower=$(echo "$decoded_name" | tr '[:upper:]' '[:lower:]')
            if [[ "$decoded_name_lower" =~ $search_term ]]; then
                game_name_cleaned=$(clean_name "$decoded_name")
                echo "Found game: $folder_name - $game_name_cleaned" &
                results+=("$game_name_cleaned" "$decoded_name" off)
            fi
        done < <(grep -i "$search_term" "$file")
    done

    wait

    if [[ ${#results[@]} -gt 0 ]]; then
        selected_games=$(dialog --title "Search Results" --checklist "Choose games to download" 25 70 10 "${results[@]}" 3>&1 1>&2 2>&3)
        [[ $? -ne 0 ]] && return
        for game in $selected_games; do
            download_game "$(clean_name "$game")"
        done
    else
        dialog --infobox "No games found for '$search_term'." 5 40
        echo "No games found for '$search_term'"
        sleep 2
    fi
}

# Main loop
while true; do
    search_term=$(dialog --inputbox "Enter search term" 10 50 3>&1 1>&2 2>&3)
    [[ -z "$search_term" ]] && break
    search_games "$search_term"

    if [[ ${#added_games[@]} -gt 0 ]]; then
        dialog --msgbox "Added games:\n$(printf "%s\n" "${added_games[@]}")" 10 50
        echo "Added games: ${added_games[@]}"
    fi

    if [[ ${#skipped_games[@]} -gt 0 ]]; then
        dialog --msgbox "Skipped games:\n$(printf "%s\n" "${skipped_games[@]}")" 10 50
        echo "Skipped games: ${skipped_games[@]}"
    fi

    dialog --title "Continue?" --yesno "Search for more games?" 7 50 || break
done
echo "Goodbye!"
