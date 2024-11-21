#!/bin/bash

DEST_DIR="/userdata/system/game-downloader/links"

# Ensure the download directory exists
mkdir -p "$DEST_DIR"

# Define the predetermined order for the menu with internal system names
MENU_ORDER=("PSX" "PS2" "PS3" "PSP" "PS Vita" "Xbox" "Xbox 360" "PC" "DOS" "Macintosh" "Game Boy" "Game Boy Color" "Game Boy Advance" "Nintendo DS" "NES" "SNES" "Nintendo 64" "GameCube" "Wii" "Game Gear" "Master System" "Mega Drive" "Saturn" "Dreamcast" "Atari 2600" "Atari 5200" "Atari 7800")


# Function to display the game list and allow selection
select_games() {
    local letter="$1"
    local file="$DEST_DIR/${system}/${letter}.txt"

    if [[ ! -f "$file" ]]; then
        dialog --infobox "No games found for selection '$letter'." 5 40
        sleep 2
        return
    fi

    # Read the list of games from the file and prepare the dialog input
    local game_list=()
    while IFS="|" read -r decoded_name encoded_url download_dir; do
        game_list+=("$decoded_name" "" off)
    done < "$file"

    selected_games=$(dialog --title "Select Games" --checklist "Choose games to download" 25 70 10 \
        "${game_list[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$selected_games" ]; then
        return
    fi

    IFS=$'\n'
    for game in $selected_games; do
        # Split game by .chd to treat each game as a separate item
        game_items=$(echo "$game" | sed 's/\.chd/.chd\n/g')
        while IFS= read -r game_item; do
            if [[ -n "$game_item" ]]; then
                game_item_cleaned=$(echo "$game_item" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')
                if [[ -n "$game_item_cleaned" ]]; then
                    download_game "$game_item_cleaned" "$file"
                fi
            fi
        done <<< "$game_items"
    done
}

# Function to download the selected game and send the link to the DownloadManager
download_game() {
    local decoded_name="$1"
    local file="$2"
    decoded_name_cleaned=$(echo "$decoded_name" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')

    # Find the game URL and download directory from the letter file
    game_info=$(grep -F "$decoded_name_cleaned" "$file")
    game_url=$(echo "$game_info" | cut -d '|' -f 2)
    download_dir=$(echo "$game_info" | cut -d '|' -f 3)

    if [ -z "$game_url" ]; then
        dialog --infobox "Error: Could not find download URL for '$decoded_name_cleaned'." 5 40
        sleep 2
        return
    fi

    # Ensure the download directory exists
    mkdir -p "$download_dir"

    # Check if the game already exists in the download directory
    if [[ -f "$download_dir/$decoded_name_cleaned" ]]; then
        skipped_games+=("$decoded_name_cleaned")
        return
    fi

    # Check if the game is already in the download queue (download.txt)
    if grep -q "$decoded_name_cleaned" "/userdata/system/game-downloader/download.txt"; then
        skipped_games+=("$decoded_name_cleaned")
        return
    fi

    # Append the decoded name, URL, and folder to the DownloadManager.txt file
    echo "$decoded_name_cleaned|$game_url|$download_dir" >> "/userdata/system/game-downloader/download.txt"
    
    # Collect the added game
    added_games+=("$decoded_name_cleaned")
}

# Function to show the letter selection menu
select_letter() {
    letter_list=$(ls "$DEST_DIR/${system}" | grep -oP '^[a-zA-Z#]' | sort | uniq)

    menu_options=()

    while read -r letter; do
        menu_options+=("$letter" "$letter")
    done <<< "$letter_list"

    selected_letter=$(dialog --title "Select a Letter" --menu "Choose a letter" 25 70 10 \
        "${menu_options[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$selected_letter" ]; then
        return 1
    else
        # Otherwise, proceed with the selected letter
        select_games "$selected_letter"
    fi
}

# Function to show the system selection menu
select_system() {
    system_list=$(ls "$DEST_DIR" | grep -oP '^[a-zA-Z]+' | sort | uniq)

    menu_options=()

    for system in "${MENU_ORDER[@]}"; do
        if [[ " ${system_list[@]} " =~ " ${system} " ]]; then
            menu_options+=("$system" "$system")
        fi
    done

    selected_system=$(dialog --title "Select a System" --menu "Choose a system" 25 70 10 \
        "${menu_options[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$selected_system" ]; then
        return 1
    else
        system="$selected_system"
        # Proceed to select letter menu
        select_letter
    fi
}

# Initialize arrays to hold skipped and added games
skipped_games=()
added_games=()

# Main loop to process selected games
while true; do
    select_system

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

exec /tmp/GameDownloader.sh
