#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"
DOWNLOAD_DIR="/userdata/roms/psx"  # Update this to your desired download directory

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
    while IFS= read -r game; do
        # Format: "game_name" "game_name"
        game_list+=("$game" "$game")
    done < "$file"
    
    # Use dialog to show the list of games for the selected letter
    selected_games=$(dialog --title "Select Games" --checklist "Choose games to download" 15 50 8 \
        "${game_list[@]}" 3>&1 1>&2 2>&3)

    # If no games are selected, exit
    if [ -z "$selected_games" ]; then
        return
    fi
    
    # Loop over the selected games and download them
    for game in $selected_games; do
        download_game "$game"
    done
}

# Function to download the selected game
download_game() {
    local game_url="$BASE_URL$1"
    echo "Downloading $game_url..."
    
    # Ensure the download directory exists
    mkdir -p "$DOWNLOAD_DIR"
    
    # Download the game using wget (you can switch to curl if preferred)
    wget "$game_url" -P "$DOWNLOAD_DIR"
    
    # Notify user after download is complete
    dialog --msgbox "Downloaded $game_url successfully." 5 40
}

# Function to show the letter selection menu
select_letter() {
    # Get the list of available letters (a-z)
    letter_list=$(ls "$DEST_DIR" | grep -oP '^[a-z]' | sort | uniq)

    # Use dialog to allow the user to select a letter
    selected_letter=$(dialog --title "Select a Letter" --menu "Choose a letter" 15 50 8 \
        $(echo "$letter_list" | while read -r letter; do
            echo "$letter" "$letter"
        done) 3>&1 1>&2 2>&3)

    # If no letter is selected, exit
    if [ -z "$selected_letter" ]; then
        return
    fi

    # Call the function to select games for the chosen letter
    select_games "$selected_letter"
}

# Main execution flow
while true; do
    select_letter
    if [ $? -eq 0 ]; then
        # Continue loop if user successfully selects and downloads games
        dialog --msgbox "Would you like to select another letter?" 5 40
    else
        # Exit if no selection is made
        break
    fi
done

echo "Goodbye!"
