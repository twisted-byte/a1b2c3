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

    # Find the game URL from the AllGames.txt file
    game_url=$(grep -F "$decoded_name_cleaned" "$ALLGAMES_FILE" | cut -d '|' -f 2)

    if [ -z "$game_url" ]; then
        dialog --infobox "Error: Could not find download URL for '$decoded_name_cleaned'." 5 40
        sleep 2
        return
    fi

    # Append the decoded name, URL, and folder to the DownloadManager.txt file
    echo "$decoded_name_cleaned|$game_url|$DOWNLOAD_DIR" >> "/userdata/system/game-downloader/download.txt"
    
    # Collect the added game
    added_games+=("$decoded_name_cleaned")
}

# Main loop to process selected games
while true; do
    select_letter

    # Show a single message if any games were added to the download list
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

    dialog --title "Continue?" --yesno "Would you like to select some more games?" 7 50
    if [ $? -eq 1 ]; then
        break
    fi
done
