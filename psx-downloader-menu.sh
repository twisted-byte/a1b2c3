#!/bin/bash

LINKS_FILE="/userdata/system/game-downloader/psx-links.txt"
DESTINATION_FOLDER="/userdata/roms/psx"

# Function to show Dreamcast game download options
show_dc_menu() {
    # Check if the links file exists and is not empty
    if [ ! -s "$LINKS_FILE" ]; then
        dialog --msgbox "No PSX game links found. Please run the scraper first." 6 50
        exit 1
    fi

    # Create menu options from links file
    local menu=()
    local idx=1
    while IFS= read -r line; do
        game_name=$(echo "$line" | cut -d ' ' -f 1)
        menu+=("$idx" "$game_name")
        ((idx++))
    done < "$LINKS_FILE"

    # Show dialog menu for game selection
    choice=$(dialog --clear --title "PSX Game Downloader" \
        --menu "Select a PSX game to download:" 15 50 10 "${menu[@]}" \
        3>&1 1>&2 2>&3)

    # If a game is selected, download it
    if [[ -n "$choice" ]]; then
        game_link=$(sed -n "${choice}p" "$LINKS_FILE" | cut -d ' ' -f 2-)
        download_dc_game "$game_link"
    fi
}

# Function to download the selected game
download_dc_game() {
    local game_link="$1"
    local file_name=$(basename "$game_link")
    local destination="$DESTINATION_FOLDER/$file_name"

    # Confirm download if the file doesn't exist
    if [ ! -f "$destination" ]; then
        dialog --yesno "Download $file_name?" 6 40
        if [ $? -eq 0 ]; then
            mkdir -p "$DESTINATION_FOLDER"
            curl -L "$game_link" -o "$destination" || dialog --msgbox "Download failed!" 6 40
        fi
    else
        dialog --msgbox "$file_name already exists." 6 40
    fi
}

# Start the Dreamcast menu loop
while true; do
    show_dc_menu
done
