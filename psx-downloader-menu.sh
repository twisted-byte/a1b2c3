# Function to download the selected game
download_game() {
    local decoded_name="$1"
    
    # Log the search process for the game in AllGames.txt
    log_debug "Searching for game '$decoded_name' in AllGames.txt..."

    # Find the full URL using the decoded name in AllGames.txt
    # Enclose the game name in double quotes for better matching
    game_url=$(grep -F "\"$decoded_name\"" "$ALLGAMES_FILE" | cut -d '|' -f 2)

    if [ -z "$game_url" ]; then
        log_debug "Error: Could not find download URL for '$decoded_name'."
        dialog --msgbox "Error: Could not find download URL for '$decoded_name'." 5 40
        return
    fi

    log_debug "Found download URL for '$decoded_name': $game_url"

    # Check if the file already exists
    file_path="$DOWNLOAD_DIR/$(basename "$decoded_name")"
    if [[ -f "$file_path" ]]; then
        log_debug "File already exists: '$file_path'. Skipping download."
        dialog --msgbox "'$decoded_name' already exists. Skipping download." 5 40
        return
    fi

    # Display the download progress in a dialog infobox
    (
        wget -c "$game_url" -P "$DOWNLOAD_DIR" 2>&1 | while read -r line; do
            echo "$line" | grep -oP '([0-9]+)%' | sed 's/%//' | \
            while read -r percent; do
                echo $percent  # Outputs progress percentage for dialog gauge
            done
        done
    ) | dialog --title "Downloading $decoded_name" --gauge "Downloading..." 10 70 0

    # Check if the download was successful
    if [[ $? -eq 0 ]]; then
        log_debug "Downloaded '$decoded_name' successfully."
        dialog --msgbox "Downloaded '$decoded_name' successfully." 5 40
        
        # Check file integrity if a checksum file exists
        if [[ -f "$CHECKSUM_FILE" ]]; then
            log_debug "Verifying checksum for '$decoded_name'..."
            checksum=$(grep -F "$(basename "$decoded_name")" "$CHECKSUM_FILE" | cut -d ' ' -f 1)
            if [[ -n "$checksum" ]]; then
                downloaded_checksum=$(sha256sum "$DOWNLOAD_DIR/$(basename "$decoded_name")" | cut -d ' ' -f 1)
                if [[ "$checksum" != "$downloaded_checksum" ]]; then
                    log_debug "Error: Checksum mismatch for '$decoded_name'."
                    dialog --msgbox "Checksum mismatch for '$decoded_name'. Download might be corrupted." 5 40
                else
                    log_debug "Checksum verified for '$decoded_name'."
                fi
            else
                log_debug "No checksum found for '$decoded_name'."
            fi
        fi
    else
        log_debug "Error downloading '$decoded_name'."
        dialog --msgbox "Error downloading '$decoded_name'." 5 40
    fi
}
