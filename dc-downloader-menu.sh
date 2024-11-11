#!/bin/bash

# Function to show Dreamcast game download options
show_dc_menu() {
    # Get the list of available games (dc-links.txt) and display them
    local games
    games=$(cat /userdata/system/game-downloader/dc-links.txt)
    
    # If the file is empty, show an error message
    if [ -z "$games" ]; then
        dialog --msgbox "No Dreamcast games available for download." 6 40
        exit 0
    fi
    
    # Create a menu list for the dialog menu
    local menu=()
    local idx=1
    while IFS= read -r line; do
        game_name=$(echo "$line" | cut -d ' ' -f 1)
        game_link=$(echo "$line" | cut -d ' ' -f 2-)
        menu+=("$idx" "$game_name")
        ((idx++))
    done <<< "$games"
    
    # Show the menu
    choice=$(dialog --clear --title "Dreamcast Downloader" \
    --menu "Select a Dreamcast game to download:" 15 50 10 "${menu[@]}" \
    2>&1 >/dev/tty)
    
    # If a valid game is selected, start the download
    if [[ -n "$choice" ]]; then
        game_link=$(echo "$games" | sed -n "${choice}p" | cut -d ' ' -f 2-)
        download_dc_game "$game_link"
    fi
}

# Function to download the selected Dreamcast game
download_dc_game() {
    local game_link="$1"
    local file_name=$(basename "$game_link")
    local destination="/userdata/roms/dreamcast/$file_name"
    
    # Check if the game already exists
    if [ -f "$destination" ]; then
        dialog --msgbox "Game $file_name already exists in the Dreamcast folder." 6 40
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

# Main menu loop for Dreamcast Downloader
while true; do
    show_dc_menu
done
