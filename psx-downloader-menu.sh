#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"
DOWNLOAD_DIR="/userdata/roms/psx"  # Update this to your desired download directory
ALLGAMES_FILE="$DEST_DIR/AllGames.txt"  # File containing the full list of games with URLs

# Ensure the download directory exists
mkdir -p "$DOWNLOAD_DIR"

# Function to display the game list and allow selection
select_games() {
    local letter="$1"
    local file="$DEST_DIR/${letter}.txt"

    if [[ ! -f "$file" ]]; then
        dialog --infobox "No games found for letter '$letter'." 5 40
        sleep 2
        return
    fi

    # Read the list of games from the file and prepare the dialog input
    local game_list=()
    while IFS="|" read -r decoded_name encoded_url; do
        game_list+=("$decoded_name" "" off)
    done < "$file"

    selected_games=$(dialog --title "Select Games" --checklist "Choose games to download" 25 70 10 \
        "${game_list[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$selected_games" ]; then
        return
    fi

    IFS=$'\n'
    for game in $selected_games; do
        game_items=$(echo "$game" | sed 's/\.chd/.chd\n/g')
        while IFS= read -r game_item; do
            if [[ -n "$game_item" ]]; then
                game_item_cleaned=$(echo "$game_item" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')
                if [[ -n "$game_item_cleaned" ]]; then
                    download_game "$game_item_cleaned"
                fi
            fi
        done <<< "$game_items"
    done
}

# Function to download the selected game and send the link to the DownloadManager
download_game() {
    local decoded_name="$1"
    decoded_name_cleaned=$(echo "$decoded_name" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')

    # Initialize message variables
    existing_games=""
    error_games=""
    added_games=""

    # Check if the game already exists in the download directory
    if [[ -f "$DOWNLOAD_DIR/$decoded_name_cleaned" ]]; then
        existing_games+="$decoded_name_cleaned (already exists in the download directory)\n"
        return
    fi

    # Check if the game is already in the download queue (download.txt)
    if grep -q "$decoded_name_cleaned" "/userdata/system/game-downloader/download.txt"; then
        existing_games+="$decoded_name_cleaned (already in the download queue)\n"
        return
    fi

    # Find the game URL from the AllGames.txt file
    game_url=$(grep -F "$decoded_name_cleaned" "$ALLGAMES_FILE" | cut -d '|' -f 2)

    if [ -z "$game_url" ]; then
        error_games+="$decoded_name_cleaned (URL not found)\n"
        return
    fi

    # Append the decoded name, URL, and folder to the DownloadManager.txt file
    echo "$decoded_name_cleaned|$game_url|$DOWNLOAD_DIR" >> "/userdata/system/game-downloader/download.txt"
    added_games+="$decoded_name_cleaned\n"
}

# Function to show the letter selection menu
select_letter() {
    letter_list=$(ls "$DEST_DIR" | grep -oP '^[a-zA-Z#]' | sort | uniq)

    menu_options=()
    while read -r letter; do
        menu_options+=("$letter" "$letter")
    done <<< "$letter_list"

    selected_letter=$(dialog --title "Select a Letter" --menu "Choose a letter" 25 70 10 \
        "${menu_options[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$selected_letter" ]; then
        return 1
    fi

    select_games "$selected_letter"
}

# Main execution flow
while true; do
    select_letter
    if [ $? -eq 0 ]; then
        # Check for existing games, errors, and added games
        existing_games_message=""
        error_games_message=""
        added_games_message=""

        if [[ -n "$existing_games" ]]; then
            existing_games_message="The following games already exist or are in the queue:\n\n$existing_games"
        fi

        if [[ -n "$error_games" ]]; then
            error_games_message="The following games could not be added due to missing URLs:\n\n$error_games"
        fi

        if [[ -n "$added_games" ]]; then
            added_games_message="The following games have been successfully added to the download queue:\n\n$added_games"
        fi

        # Combine all messages
        message=""
        message+="$existing_games_message\n"
        message+="$error_games_message\n"
        message+="$added_games_message\n"

        if [[ -n "$message" ]]; then
            dialog --infobox "$message" 10 60
            sleep 3
        fi

        dialog --title "Continue?" --yesno "Would you like to select some more games?" 7 50
        if [ $? -eq 1 ]; then
            break
        fi
    else
        break
    fi
done

# After the user exits the game selection loop
echo "Goodbye!"

# Run the curl command to reload the games
curl http://127.0.0.1:1234/reloadgames

# Reload the script (this will re-run the game downloader)
curl -L raw.githubusercontent.com/DTJW92/game-downloader/main/GameDownloader.sh | bash
