#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"
DOWNLOAD_DIR="/userdata/roms/psx"  # Update this to your desired download directory
ALLGAMES_FILE="$DEST_DIR/AllGames.txt"  # File containing the full list of games with URLs
DEBUG_LOG="$DEST_DIR/debug.txt"  # Log file to capture debug information

# Ensure the download directory and log file exist
mkdir -p "$DOWNLOAD_DIR"
touch "$DEBUG_LOG"

# Function to log debug messages
log_debug() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$DEBUG_LOG"
}

# Function to display the game list and allow selection
select_games() {
    local letter="$1"
    local file="$DEST_DIR/${letter}.txt"

    if [[ ! -f "$file" ]]; then
        dialog --infobox "No games found for letter '$letter'." 5 40
        return
    fi

    # Read the list of games from the file and prepare the dialog input
    local game_list=()
    while IFS="|" read -r decoded_name encoded_url; do
        # Only add the decoded_name to the list, ignoring the URL in dialog
        game_list+=("$decoded_name" "" off)
    done < "$file"

    # Use dialog to show the list of games for the selected letter
    selected_games=$(dialog --title "Select Games" --checklist "Choose games to download" 15 50 8 \
        "${game_list[@]}" 3>&1 1>&2 2>&3)

    # If no games are selected, exit
    if [ -z "$selected_games" ]; then
        return
    fi

    # Loop over the selected games, splitting each on ".chd" while retaining exact text
    IFS=$'\n'  # Set the internal field separator to newline to preserve spaces in game names
    for game in $selected_games; do
        # Add '.chd' back to each split part, treating each as a separate game
        game_items=$(echo "$game" | sed 's/\.chd/.chd\n/g')

        # Iterate over each game item found in the split
        while IFS= read -r game_item; do
            # Only process non-empty game items
            if [[ -n "$game_item" ]]; then
                # Clean the game name by removing backslashes, quotes, and backticks, while preserving spaces
                game_item_cleaned=$(echo "$game_item" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')  # Trim both leading and trailing spaces

                # Debug: Log the cleaned game name before processing
                log_debug "Processing game: '$game_item_cleaned'"

                # Check if cleaned name is still non-empty before proceeding
                if [[ -n "$game_item_cleaned" ]]; then
                    download_game "$game_item_cleaned"
                else
                    log_debug "Skipping blank game name."
                fi
            fi
        done <<< "$game_items"
    done
}

# Function to download the selected game
download_game() {
    local decoded_name="$1"
    
    # Clean up the game name by removing unwanted characters like backticks and quotes, but keep spaces
    decoded_name_cleaned=$(echo "$decoded_name" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')  # Trim both leading and trailing spaces

    # Debug: Log the cleaned game name before searching
    log_debug "Searching for game '$decoded_name_cleaned' in AllGames.txt..."

    # Find the full URL using the cleaned game name in AllGames.txt
    game_url=$(grep -F "$decoded_name_cleaned" "$ALLGAMES_FILE" | cut -d '|' -f 2)

    if [ -z "$game_url" ]; then
        log_debug "Error: Could not find download URL for '$decoded_name_cleaned'."
        dialog --infobox "Error: Could not find download URL for '$decoded_name_cleaned'." 5 40
        return
    fi

    log_debug "Found download URL for '$decoded_name_cleaned': $game_url"

    # Check if the file already exists
    file_path="$DOWNLOAD_DIR/$(basename "$decoded_name_cleaned")"
    if [[ -f "$file_path" ]]; then
        log_debug "File already exists: '$file_path'. Skipping download."
        dialog --infobox "'$decoded_name_cleaned' already exists. Skipping download." 5 40
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
    ) | dialog --title "Downloading $decoded_name_cleaned" --gauge "Downloading..." 10 70 0

    # Check if the download was successful
    if [[ $? -eq 0 ]]; then
        log_debug "Downloaded '$decoded_name_cleaned' successfully."
        dialog --infobox "Downloaded '$decoded_name_cleaned' successfully." 5 40
        
        # Check file integrity if a checksum file exists
        if [[ -f "$CHECKSUM_FILE" ]]; then
            log_debug "Verifying checksum for '$decoded_name_cleaned'..."
            checksum=$(grep -F "$(basename "$decoded_name_cleaned")" "$CHECKSUM_FILE" | cut -d ' ' -f 1)
            if [[ -n "$checksum" ]]; then
                downloaded_checksum=$(sha256sum "$DOWNLOAD_DIR/$(basename "$decoded_name_cleaned")" | cut -d ' ' -f 1)
                if [[ "$checksum" != "$downloaded_checksum" ]]; then
                    log_debug "Error: Checksum mismatch for '$decoded_name_cleaned'."
                    dialog --infobox "Checksum mismatch for '$decoded_name_cleaned'. Download might be corrupted." 5 40
                else
                    log_debug "Checksum verified for '$decoded_name_cleaned'."
                fi
            else
                log_debug "No checksum found for '$decoded_name_cleaned'."
            fi
        fi
    else
        log_debug "Error downloading '$decoded_name_cleaned'."
        dialog --infobox "Error downloading '$decoded_name_cleaned'." 5 40
    fi
}

# Function to show the letter selection menu
select_letter() {
# Get the list of available letters, convert to uppercase, and sort
letter_list=$(ls "$DEST_DIR" | grep -oP '^[a-zA-Z#]' | tr '[:lower:]' '[:upper:]' | sort | uniq)

# Prepare menu options in a 4x4 grid format
menu_options=()
counter=0
for letter in $letter_list; do
    menu_options+=("$letter" "$letter")  # Repeat each letter for dialog options
    ((counter++))
    
    # If 4 items are added, break the line (start a new row)
    if ((counter % 4 == 0)); then
        menu_options+=("")  # This adds an empty line after every 4 letters
    fi
done

# Use dialog to allow the user to select a letter in a grid format
selected_letter=$(dialog --title "Select a Letter" --menu "Choose a letter" 15 50 8 \
    "${menu_options[@]}" 3>&1 1>&2 2>&3)

# If no letter is selected, exit
if [ -z "$selected_letter" ]; then
    return 1  # Return non-zero exit code if no selection is made
fi

# Call the function to select games for the chosen letter
select_games "$selected_letter"
}

# Main execution flow
while true; do
    select_letter
    if [ $? -eq 0 ]; then
        # Ask the user whether they want to select another letter or exit
        dialog --title "Continue?" --yesno "Would you like to select some more games?" 7 50
        if [ $? -eq 1 ]; then
            break  # Exit if the user chooses "No"
        fi
    else
        break  # Exit if no selection is made
    fi
done

log_debug "Goodbye!"
echo "Goodbye!"

# Run the curl command to reload the games
curl http://127.0.0.1:1234/reloadgames
