#!/bin/bash

# Paths to files and logs
DEST_DIR="/userdata/system/game-downloader/links"
DEBUG_LOG="/userdata/system/game-downloader/debug/search_debug.txt"

# Ensure the debug directory exists
mkdir -p "$(dirname "$DEBUG_LOG")"

# Clear debug log for a fresh session
if [ -f "$DEBUG_LOG" ]; then
    echo "Clearing debug log for the new session." >> "$DEBUG_LOG"
    > "$DEBUG_LOG"
fi

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
    local game_name="$1"
    local game_url="$2"
    local game_download_dir="$3"
    decoded_name_cleaned=$(clean_name "$game_name")

    # Check if the game has already been processed or downloaded
    if [[ -f "$DEST_DIR/$decoded_name_cleaned" ]] || grep -q "$decoded_name_cleaned" "/userdata/system/game-downloader/processing.txt"; then
        skipped_games+=("$decoded_name_cleaned")
        return
    fi

    if [[ -z "$game_url" || -z "$game_download_dir" ]]; then
        dialog --infobox "Error: Could not find URL for '$decoded_name_cleaned'." 5 40
        sleep 2
        return
    fi

    # Log the game info for download, including the cleaned game name
    echo "$decoded_name_cleaned|$game_url|$game_download_dir" >> "/userdata/system/game-downloader/download.txt"
    added_games+=("$decoded_name_cleaned")
}

# Function to search and display games
search_games() {
    local search_term="$1"
    local results=()
    IFS=$'\n'

    search_term=$(echo "$search_term" | tr '[:upper:]' '[:lower:]')

    for file in $(find "$DEST_DIR" -type f -name "*.txt"); do
        folder_name=$(basename "$(dirname "$file")")
       
        while IFS="|" read -r decoded_name encoded_url game_download_dir; do
            decoded_name_lower=$(echo "$decoded_name" | tr '[:upper:]' '[:lower:]')
            if [[ "$decoded_name_lower" =~ $search_term ]]; then
                game_name_cleaned=$(clean_name "$decoded_name")
                
                # Store the full line along with the folder name for description purposes
                # Folder name is only for description, the actual game name will be used for the download list
                results+=("$game_name_cleaned" "($folder_name)" off)
            fi
        done < "$file"
    done

    wait

    if [[ ${#results[@]} -gt 0 ]]; then
        selected_games=$(dialog --title "Search Results" --checklist "Choose games to download" 25 70 10 "${results[@]}" 3>&1 1>&2 2>&3)
        [[ $? -ne 0 ]] && return
        for game in $selected_games; do
            # Extract the actual game name, URL, and download directory, excluding the folder name
            game_name=$(echo "$game" | cut -d '|' -f 1)
            game_url=$(echo "$game" | cut -d '|' -f 2)
            game_download_dir=$(echo "$game" | cut -d '|' -f 3)

            # Pass the correct game info to the download function
            download_game "$game_name" "$game_url" "$game_download_dir"
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

    if [[ ${#added_games[@]} -gt 0 ]]; then
        dialog --msgbox "Added games:\n$(printf "%s\n" "${added_games[@]}")" 10 50
    fi

    if [[ ${#skipped_games[@]} -gt 0 ]]; then
        dialog --msgbox "Skipped games:\n$(printf "%s\n" "${skipped_games[@]}")" 10 50
    fi

    dialog --title "Continue?" --yesno "Search for more games?" 7 50 || break
done
