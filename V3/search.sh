#!/bin/bash

DEST_DIR="/userdata/system/game-downloader/links"
  # Update this to your desired download directory
ALLGAMES_FILE="$DEST_DIR/AllGames.txt"  # File containing the full list of games with URLs

# Ensure the download directory exists
mkdir -p "$DOWNLOAD_DIR"

# Function to download the selected game and send the link to the DownloadManager
download_game() {
    local decoded_name="$1"
    decoded_name_cleaned=$(echo "$decoded_name" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')

    # Check if the game already exists in the download directory
    if [[ -f "$DOWNLOAD_DIR/$decoded_name_cleaned" ]]; then
        skipped_games+=("$decoded_name_cleaned")
        return
    fi

    # Check if the game is already in the download queue (download.txt)
    if grep -q "$decoded_name_cleaned" "/userdata/system/game-downloader/download.txt"; then
        skipped_games+=("$decoded_name_cleaned")
        return
    fi

    # Find the game URL from the AllGames.txt file and the correct download directory
    game_info=$(grep -F "$decoded_name_cleaned" "$ALLGAMES_FILE")
    game_url=$(echo "$game_info" | cut -d '|' -f 2)
    game_download_dir=$(echo "$game_info" | cut -d '|' -f 3)

    if [ -z "$game_url" ]; then
        dialog --infobox "Error: Could not find download URL for '$decoded_name_cleaned'." 5 40
        sleep 2
        return
    fi

    # Append the decoded name, URL, and folder to the DownloadManager.txt file
    echo "$decoded_name_cleaned|$game_url|$game_download_dir" >> "/userdata/system/game-downloader/download.txt"
    
    # Collect the added game
    added_games+=("$decoded_name_cleaned")
}

search_games() {
    local search_term="$1"
    local results=()

    # Wrap the search term in backticks to match the game names in AllGames.txt
    search_term_with_backticks="\`$search_term\`"

    # Search through subfolders and AllGames.txt files
    find "$DEST_DIR" -type f -name "AllGames.txt" | while read -r file; do
        folder_name=$(dirname "$file")  # Get the folder name (subfolder)

        # Search for the term in AllGames.txt, now wrapped in backticks
        grep -i "$search_term_with_backticks" "$file" | while IFS="|" read -r decoded_name encoded_url game_download_dir; do
            # Clean the game name and display it with the subfolder name
            game_name_cleaned=$(echo "$decoded_name" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')
            results+=("$folder_name - $game_name_cleaned")
        done
    done

    # Display results in dialog
    if [ ${#results[@]} -gt 0 ]; then
        selected_games=$(dialog --title "Search Results" --checklist "Choose games to download" 25 70 10 \
            "${results[@]}" 3>&1 1>&2 2>&3)

        if [ -n "$selected_games" ]; then
            IFS=$'\n'
            for game in $selected_games; do
                game_cleaned=$(echo "$game" | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')
                download_game "$game_cleaned"
            done
        fi
    else
        dialog --infobox "No games found for '$search_term'." 5 40
        sleep 2
    fi
}


# Main search loop
while true; do
    search_term=$(dialog --inputbox "Enter search term" 10 50 3>&1 1>&2 2>&3)
    
    if [ -z "$search_term" ]; then
        break
    fi

    search_games "$search_term"

    # Show a single message if any games were added to the download list
    if [ ${#added_games[@]} -gt 0 ]; then
        dialog --msgbox "Your selection has been added to the download list! Check download status and once it's complete, reload your games list to see the new games!" 10 50
        added_games=()  # Clear the added games list
    fi

    # Display skipped games message if there are any skipped games
    if [ ${#skipped_games[@]} -gt 0 ]; then
        skipped_games_list=$(printf "%s\n" "${skipped_games[@]}" | sed 's/^/• /')
        dialog --msgbox "The following games already exist in the system and are being skipped:\n\n$skipped_games_list" 15 60
        skipped_games=()  # Clear the skipped games list
    fi

    # Ask user if they want to continue after displaying skipped games
    dialog --title "Continue?" --yesno "Would you like to search for more games?" 7 50
    if [ $? -eq 1 ]; then
        break
    fi
done

# Goodbye message
echo "Goodbye!"
