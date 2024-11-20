#!/bin/bash

DEST_DIR="/userdata/system/game-downloader/links"

# Function to clean up game names and remove backticks
clean_name() {
    echo "$1" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g'
}

# Function to search and display games based on the search term
search_games() {
    local search_term="$1"
    local results=()

    # Make search term lowercase to allow case-insensitive search
    search_term=$(echo "$search_term" | tr '[:upper:]' '[:lower:]')

    # Search through all .txt files in DEST_DIR and its subdirectories
    find "$DEST_DIR" -type f -name "*.txt" | while read -r file; do
        while IFS="|" read -r decoded_name encoded_url game_download_dir; do
            # Remove backticks from game name
            decoded_name=$(clean_name "$decoded_name")
            
            decoded_name_lower=$(echo "$decoded_name" | tr '[:upper:]' '[:lower:]')
            if [[ "$decoded_name_lower" =~ $search_term ]]; then
                # Add the game name to the results, and pass the full line to be used for download
                results+=("$decoded_name" "$file" off)
            fi
        done < "$file"
    done

    # If there are any results, display them in a checklist for selection
    if [[ ${#results[@]} -gt 0 ]]; then
        selected_games=$(dialog --title "Search Results" --checklist "Choose games to download" 25 70 10 "${results[@]}" 3>&1 1>&2 2>&3)

        if [ -n "$selected_games" ]; then
            # For each selected game, process and download it
            for game in $selected_games; do
                game_name=$(echo "$game" | sed 's/\([^|]*\).*/\1/')
                game_file=$(echo "$game" | sed 's/[^|]*|\(.*\)/\1/')
                download_game "$game_name" "$game_file"
            done
        fi
    else
        dialog --infobox "No games found for '$search_term'." 5 40
        sleep 2
    fi
}


# Function to download the selected game and send the link to the DownloadManager
download_game() {
    local decoded_name="$1"
    local game_file="$2"
    decoded_name_cleaned=$(clean_name "$decoded_name")

    # Check if the game already exists in the download directory
    if [[ -f "$game_download_dir/$decoded_name_cleaned" ]]; then
        skipped_games+=("$decoded_name_cleaned")
        return
    fi

    # Check if the game is already in the download queue (download.txt)
    if grep -q "$decoded_name_cleaned" "/userdata/system/game-downloader/download.txt"; then
        skipped_games+=("$decoded_name_cleaned")
        return
    fi

    # Find the game URL and download directory from the specific file
    game_url=$(grep -F "$decoded_name_cleaned" "$game_file" | cut -d '|' -f 2)
    game_download_dir=$(grep -F "$decoded_name_cleaned" "$game_file" | cut -d '|' -f 3)

    if [ -z "$game_url" ] || [ -z "$game_download_dir" ]; then
        dialog --infobox "Error: Could not find download URL or directory for '$decoded_name_cleaned'." 5 40
        sleep 2
        return
    fi

    # Append the decoded name, URL, and folder to the DownloadManager.txt file
    echo "$decoded_name_cleaned|$game_url|$game_download_dir" >> "/userdata/system/game-downloader/download.txt"
    
    # Collect the added game
    added_games+=("$decoded_name_cleaned")
}

# Main loop to search and select games
while true; do
    search_term=$(dialog --inputbox "Enter search term" 10 50 3>&1 1>&2 2>&3)
    [[ -z "$search_term" ]] && break

    # Search for games matching the search term
    search_games "$search_term"

    # Show a message if any games were added to the download list
    if [ ${#added_games[@]} -gt 0 ]; then
        dialog --msgbox "Your selection has been added to the download list! Check download status and once it's complete, reload your games list to see the new games!" 10 50
        # Clear the added games list
        added_games=()
    fi

    # Display skipped games message if there are any skipped games
    if [ ${#skipped_games[@]} -gt 0 ]; then
        skipped_games_list=$(printf "%s\n" "${skipped_games[@]}" | sed 's/^/• /')
        dialog --msgbox "The following games already exist in the system and are being skipped:\n\n$skipped_games_list" 15 60
        skipped_games=()
    fi

    # Ask user if they want to continue after displaying skipped games
    dialog --title "Continue?" --yesno "Would you like to search for more games?" 7 50
    if [ $? -eq 1 ]; then
        break
    fi
done

# Goodbye message
echo "Goodbye!"
