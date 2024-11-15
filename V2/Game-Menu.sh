#!/bin/bash

# Dynamic Variables Based on System Choice
SYSTEM=$1

# Ensure clear display
clear

# Define system-specific variables (without BASE_URL)
case $SYSTEM in
    PSX)
        DEST_DIR="/userdata/system/game-downloader/psxlinks"
        DOWNLOAD_DIR="/userdata/roms/psx"
        ALLGAMES_FILE="$DEST_DIR/AllGames.txt"
        ;;
    PS2)
        DEST_DIR="/userdata/system/game-downloader/ps2links"
        DOWNLOAD_DIR="/userdata/roms/ps2"
        ALLGAMES_FILE="$DEST_DIR/AllGames.txt"
        ;;
    Dreamcast)
        DEST_DIR="/userdata/system/game-downloader/dclinks"
        DOWNLOAD_DIR="/userdata/roms/dreamcast"
        ALLGAMES_FILE="$DEST_DIR/AllGames.txt"
        ;;
    GBA)
        DEST_DIR="/userdata/system/game-downloader/gbalinks"
        DOWNLOAD_DIR="/userdata/roms/gba"
        ALLGAMES_FILE="$DEST_DIR/AllGames.txt"
        ;;
    *)
        dialog --msgbox "Invalid system selected!" 10 50
        exit 1
        ;;
esac

# Function to display the game list and allow selection
select_games() {
    local letter="$1"
    local file

    if [[ "$letter" == "AllGames" ]]; then
        file="$ALLGAMES_FILE"
    else
        file="$DEST_DIR/${letter}.txt"
    fi

    if [[ ! -f "$file" ]]; then
        dialog --infobox "No games found for selection '$letter'." 5 40
        sleep 2
        return
    fi

    # Read the list of games and prepare the dialog input
    local game_list=()
    while IFS="|" read -r decoded_name game_url; do
        game_list+=("$decoded_name" "" off)
    done < "$file"

    selected_games=$(dialog --title "$SYSTEM Games" --checklist "Choose games to download" 25 70 10 \
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

# Function to show the letter selection menu with an "All Games" option
select_letter() {
    letter_list=$(ls "$DEST_DIR" | grep -oP '^[a-zA-Z#]' | sort | uniq)

    # Add "All" option to the menu
    menu_options=("All" "All Games")

    while read -r letter; do
        menu_options+=("$letter" "$letter")
    done <<< "$letter_list"

    selected_letter=$(dialog --title "Select a Letter" --menu "Choose a letter or select 'All Games'" 25 70 10 \
        "${menu_options[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$selected_letter" ]; then
        return 1
    elif [ "$selected_letter" == "All" ]; then
        # If "All Games" is selected, link to AllGames.txt
        select_games "AllGames"
    else
        # Otherwise, proceed with the selected letter
        select_games "$selected_letter"
    fi
}

# Initialize arrays to hold skipped and added games
skipped_games=()
added_games=()

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

    # Ask user if they want to continue after displaying skipped games
    dialog --title "Continue?" --yesno "Would you like to select some more games?" 7 50
    if [ $? -eq 1 ]; then
        break
    fi
done

# Goodbye message
echo "Goodbye!"
