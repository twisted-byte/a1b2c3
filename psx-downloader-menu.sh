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
        dialog --msgbox "No games found for letter '$letter'." 5 40
        return
    fi

    # Read the list of games from the file and prepare the dialog input
    local game_list=()
    while IFS="|" read -r decoded_name encoded_url; do
        game_list+=("$decoded_name" "$encoded_url" off)
    done < "$file"

    # Use dialog to show the list of games for the selected letter
    selected_games=$(dialog --title "Select Games" --checklist "Choose games to download" 15 50 8 \
        "${game_list[@]}" 3>&1 1>&2 2>&3)

    # If no games are selected, exit
    if [ -z "$selected_games" ]; then
        return
    fi

    # Loop over the selected games and download them one by one
    IFS=$'\n'  # Set the internal field separator to newline to preserve spaces in game names
    for game in $selected_games; do
        # Clean the game name by removing quotes and backslashes
        game_cleaned=$(echo "$game" | sed 's/[\\\]//g')

        log_debug "Searching for game '$game_cleaned' in AllGames.txt..."

        # Find the full URL using the cleaned game name
        game_url=$(grep -F "$game_cleaned" "$ALLGAMES_FILE" | cut -d '|' -f 2)

        if [ -z "$game_url" ]; then
            log_debug "Error: Could not find download URL for '$game_cleaned'."
            dialog --msgbox "Error: Could not find download URL for '$game_cleaned'." 5 40
            continue
        fi

        log_debug "Found download URL for '$game_cleaned': $game_url"

        # Check if the file already exists
        file_path="$DOWNLOAD_DIR/$(basename "$game_cleaned")"
        if [[ -f "$file_path" ]]; then
            log_debug "File already exists: '$file_path'. Skipping download."
            dialog --msgbox "'$game_cleaned' already exists. Skipping download." 5 40
            continue
        fi

        # Display the download progress in a dialog infobox
        (
            wget "$game_url" -P "$DOWNLOAD_DIR" 2>&1 | while read -r line; do
                echo "$line" | grep -oP '([0-9]+)%' | sed 's/%//' | \
                while read -r percent; do
                    echo $percent  # Outputs progress percentage for dialog gauge
                done
            done
        ) | dialog --title "Downloading $game_cleaned" --gauge "Downloading..." 10 70 0

        # Check if the download was successful
        if [[ $? -eq 0 ]]; then
            log_debug "Downloaded '$game_cleaned' successfully."
            dialog --msgbox "Downloaded '$game_cleaned' successfully." 5 40
        else
            log_debug "Error downloading '$game_cleaned'."
            dialog --msgbox "Error downloading '$game_cleaned'." 5 40
        fi
    done
}

# Function to show the letter selection menu
select_letter() {
    # Get the list of available letters and format as options for dialog
    letter_list=$(ls "$DEST_DIR" | grep -oP '^[a-zA-Z#]' | sort | uniq)

    # Prepare menu options for dialog
    menu_options=()
    while read -r letter; do
        menu_options+=("$letter" "$letter")  # Repeat each letter to avoid pairing issue
    done <<< "$letter_list"

    # Use dialog to allow the user to select a letter
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
