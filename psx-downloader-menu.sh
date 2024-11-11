#!/bin/bash

# Path to the error log file
ERROR_LOG="/userdata/system/game-downloader/error_log.txt"

# Function to log errors to the error log file
log_error() {
    local message="$1"
    echo "$(date "+%Y-%m-%d %H:%M:%S") - ERROR: $message" >> "$ERROR_LOG"
}

# Function to show the "Loading games list" message
show_loading_message() {
    # Display the loading message while games are loading
    dialog --title "Loading" --msgbox "Loading games list, please wait..." 6 40 &
}

# Function to load the PSX games list
load_psx_games() {
    # Show loading message
    show_loading_message

    # Read the game list from the text file and prepare it for use
    if [ -f "/userdata/system/game-downloader/psx-links.txt" ]; then
        mapfile -t games < /userdata/system/game-downloader/psx-links.txt
    else
        log_error "psx-links.txt not found."
        dialog --msgbox "psx-links.txt not found!" 6 40
        exit 1
    fi

    # Once the games are loaded, close the loading message dialog
    kill $!  # Kill the background dialog process (the loading message)
}

# Function to show the PSX game download menu
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

    # Show the menu using dialog
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
        log_error "Game $file_name already exists in the PSX folder."
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
            log_error "Error downloading $file_name from $game_link."
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
