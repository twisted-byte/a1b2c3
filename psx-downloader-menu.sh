#!/bin/bash

# Define the game list location (can be updated with your own URL or file)
game_list_file="/userdata/system/game-downloader/psx_games.txt"

# Define the download location
download_folder="/userdata/roms/psx"

# Function to display the available games and allow selection via dialog
show_game_menu() {
    # Check if the game list exists
    if [ ! -f "$game_list_file" ]; then
        echo "Error: The game list file does not exist at $game_list_file"
        exit 1
    fi

    # Read the game list into a format suitable for dialog
    dialog_items=()
    while IFS= read -r line; do
        # Format each line into a dialog option (game name and download link)
        game_name=$(echo "$line" | cut -d ' ' -f 1) # assuming the game name is the first word
        game_link=$(echo "$line" | cut -d ' ' -f 2) # assuming the download link is the second word
        dialog_items+=("$game_name" "$game_name" OFF) # Add game to the dialog list (game name, description, selected OFF by default)
    done < "$game_list_file"

    # Show the checklist dialog to select games
    selected_games=$(dialog --separate-output --checklist \
                            "Select PSX games to download:" \
                            20 70 15 \
                            "${dialog_items[@]}" \
                            2>&1 >/dev/tty)

    # Check if user pressed Cancel
    if [ $? -eq 1 ]; then
        echo "No games selected, exiting."
        exit 0
    fi

    # Loop through selected games and download them
    for game in $selected_games; do
        download_game "$game"
    done
}

# Function to download the selected game
download_game() {
    game_name=$1

    # Find the download link for the selected game
    download_link=$(grep "^$game_name " "$game_list_file" | cut -d ' ' -f 2)

    # Validate download link
    if [ -z "$download_link" ]; then
        echo "Error: No download link found for $game_name"
        return
    fi

    # Create the download folder if it doesn't exist
    mkdir -p "$download_folder"

    # Download the game using curl
    echo "Downloading $game_name from $download_link..."
    curl -L "$download_link" -o "$download_folder/$game_name.chd"

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        echo "$game_name downloaded successfully."
    else
        echo "Error: Failed to download $game_name."
    fi
}

# Main execution
clear
echo "Welcome to PSX Downloader!"

# Show the game selection menu
show_game_menu

echo "Exiting PSX Downloader."
