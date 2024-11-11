#!/bin/bash

# Function to show the "Loading games list" message
show_loading_message() {
    # Display the loading message in the background
    dialog --title "Loading" --msgbox "Loading games list, please wait..." 6 40 &
}

# Load the list of games into memory once when the script starts
load_psx_games() {
    # Show "Loading games list" message asynchronously
    show_loading_message
    
    # Read psx-links.txt and prepare the list of games in memory
    if [ -f "/userdata/system/game-downloader/psx-links.txt" ]; then
        mapfile -t games < /userdata/system/game-downloader/psx-links.txt
    else
        dialog --msgbox "psx-links.txt not found!" 6 40
        exit 1
    fi
    
    # Close the dialog once the game list is loaded
    kill $!  # Kill the background dialog process
}

# Function to show PSX game download options
show_psx_menu() {
    # Create a menu list for the dialog menu
    local menu=()
    local idx=1
    
    # Process the game list into a format suitable for dialog
    for game in "${games[@]}"; do
        game_name=$(echo "$game" | cut -d ' ' -f 1)
        game_link=$(echo "$game" | cut -d ' ' -f 2-)
        menu+=("$idx" "$game_name")
        ((idx++))
    done
    
    # Show the menu
    choice=$(dialog --clear --title "PSX Downloader" \
    --menu "Select a PSX game to download:" 15 50 10 "${menu[@]}" \
    2>&1 >/dev/tty)
    
    # If Cancel is pressed, exit back to the GameDownloader.sh menu
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # If a valid game is selected, start the download
    if [[ -n "$choice" ]]; then
        game_link=$(echo "${games[$choice-1]}" | cut -d ' ' -f 2-)
        download_psx_game "$game_link"
    fi
}

# Function to download the selected PSX game
download_psx_game() {
    local game_link="$1"
    local file_name=$(basename "$game_link")
    local destination="/userdata/roms/psx/$file_name"
    
    # Check if the game already exists
    if [ -f "$destination" ]; then
        dialog --msgbox "Game $file_name already exists in the PSX folder." 6 40
        return
    fi
    
    # Show a download confirmation
    dialog --yesno "Do you want to download $file_name?" 6 40
    if [ $? -eq 0 ]; then
        # Start downloading the file using curl
        curl -L "$game_link" -o "$destination"
        
        if [ $? -eq 0 ]; then
            dialog --msgbox "$file_name has been successfully downloaded." 6 40
        else
            dialog --msgbox "Error downloading $file_name." 6 40
        fi
    fi
}

# Main menu loop for PSX Downloader
load_psx_games

while true; do
    show_psx_menu
    if [ $? -ne 0 ]; then
        break  # Exit the loop and return to the GameDownloader.sh menu
    fi
done
