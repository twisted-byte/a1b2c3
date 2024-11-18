#!/bin/bash
# Ensure clear display
clear

# Toggle for dialog (1 = enabled, 0 = disabled)
USE_DIALOG=1  # Set to 0 to disable dialog, 1 to enable it

# Define the base directory for game systems
BASE_DIR="/userdata/system/game-downloader/links"
LOG_FILE="/userdata/system/game-downloader/debug/system_menu.txt"

# Debug flag (set to 1 to enable logging, 0 to disable)
DEBUG_ENABLED=1

# Log function to write messages to the log file
log_debug() {
    if [ "$DEBUG_ENABLED" -eq 1 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    fi
}

# Start logging script execution
log_debug "Script started"

# Check if the base directory exists
if [ ! -d "$BASE_DIR" ]; then
    log_debug "Error: The game downloader directory doesn't exist!"
    if [ "$USE_DIALOG" -eq 1 ]; then
        dialog --msgbox "Error: The game downloader directory doesn't exist!" 10 50
    else
        echo "Error: The game downloader directory doesn't exist!"
    fi
    exit 1
fi

# Create a list of available game systems (directories inside /userdata/system/game-downloader/links)
GAME_SYSTEMS=()
MENU_OPTIONS=()

# Loop through the directories in /userdata/system/game-downloader/links and add them to the menu
index=1
for dir in "$BASE_DIR"/*/; do
    if [ -d "$dir" ]; then
        SYSTEM_NAME=$(basename "$dir")
        GAME_SYSTEMS+=("$SYSTEM_NAME")
        MENU_OPTIONS+=("$index" "$SYSTEM_NAME")
        ((index++))
    fi
done

# Check if any systems were found
if [ ${#GAME_SYSTEMS[@]} -eq 0 ]; then
    log_debug "Error: No game systems found in $BASE_DIR!"
    if [ "$USE_DIALOG" -eq 1 ]; then
        dialog --msgbox "No game systems found in $BASE_DIR!" 10 50
    else
        echo "No game systems found in $BASE_DIR!"
    fi
    exit 1
fi

# Add the option for the user to exit
MENU_OPTIONS=("0" "Return" "${MENU_OPTIONS[@]}")

# Main dialog menu with loop to keep the menu active until a valid choice is selected
if [ "$USE_DIALOG" -eq 1 ]; then
    dialog --clear --backtitle "Game Downloader" \
           --title "Select a Game System" \
           --menu "Choose an option:" 15 50 12 \
           "${MENU_OPTIONS[@]}" 2>/tmp/game-downloader-choice
    choice=$(< /tmp/game-downloader-choice)
    rm /tmp/game-downloader-choice
else
    echo "Select a Game System:"
    for ((i=1; i<=${#GAME_SYSTEMS[@]}; i++)); do
        echo "$i) ${GAME_SYSTEMS[$i-1]}"
    done
    read -p "Enter your choice (0 to return): " choice
fi

# Check if the user canceled the dialog (no choice selected)
if [ -z "$choice" ] || [ "$choice" -eq 0 ]; then
    log_debug "User canceled or no option selected."
    clear
    if [ "$USE_DIALOG" -eq 1 ]; then
        dialog --infobox "Thank you for using Game Downloader! Any issues, message DTJW92 on Discord!" 10 50
    else
        echo "Thank you for using Game Downloader! Any issues, message DTJW92 on Discord!"
    fi
    sleep 3
    exit 0  # Exit the script when Cancel is clicked or no option is selected
fi

# Get the selected game system
SELECTED_SYSTEM="${GAME_SYSTEMS[$((choice - 1))]}"
log_debug "User selected system: $SELECTED_SYSTEM"


# Define directories and files
DEST_DIR="/userdata/system/game-downloader/links"
ALLGAMES_FILE="$DEST_DIR/$SELECTED_SYSTEM/AllGames.txt"  # File containing the full list of games with URLs
DOWNLOAD_DIR="$DEST_DIR/$SELECTED_SYSTEM"  # Download directory

# Ensure the download directory exists
mkdir -p "$DOWNLOAD_DIR"

# Initialize arrays to hold skipped and added games
skipped_games=()
added_games=()

# Function to display the game list and allow selection
select_games() {
    local letter="$1"
    local file

    log_debug "Selecting games for letter: $letter"

    # Set file path based on the selection
    if [[ "$letter" == "AllGames" ]]; then
        file="$ALLGAMES_FILE"
    else
        file="$DEST_DIR/$SELECTED_SYSTEM/${letter}.txt"
    fi

    if [[ ! -f "$file" ]]; then
        log_debug "Error: No games found for selection '$letter'."
        if [ "$USE_DIALOG" -eq 1 ]; then
            dialog --infobox "No games found for selection '$letter'." 5 40
        else
            echo "No games found for selection '$letter'."
        fi
        sleep 2
        return
    fi

    # Read the list of games from the file and prepare the dialog input
    local game_list=()
    while IFS="|" read -r decoded_name encoded_url; do
        game_list+=("$decoded_name" "" off)
    done < "$file"

    # Add "Return" option at the top of the list
    game_list=("Return" "${game_list[@]}")

    # Show the game selection menu
    if [ "$USE_DIALOG" -eq 1 ]; then
        selected_games=$(dialog --title "Select Games" --checklist "Choose games to download" 25 70 10 \
            "${game_list[@]}" 3>&1 1>&2 2>&3)
    else
        echo "Select games to download (enter numbers separated by space):"
        for game in "${game_list[@]}"; do
            echo "$game"
        done
        read -p "Enter your selection: " selected_games
    fi

    # If "Return" is selected or no games are selected, exit without continuing
    if [[ "$selected_games" == "Return" || -z "$selected_games" ]]; then
        log_debug "User selected Return or no games selected."
        return 1  # Return to the letter selection menu
    fi

    # Proceed with downloading the selected games
    IFS=$'\n'
    for game in $selected_games; do
        # Split game by .chd to treat each game as a separate item
        game_items=$(echo "$game" | sed -E 's/\.(chd|zip|iso)/\.\1\n/g')
        while IFS= read -r game_item; do
            if [[ -n "$game_item" ]]; then
                game_item_cleaned=$(echo "$game_item" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')
                if [[ -n "$game_item_cleaned" ]]; then
                    log_debug "Downloading game: $game_item_cleaned"
                    download_game "$game_item_cleaned"
                fi
            fi
        done <<< "$game_items"
    done
}


# Function to download the selected game and send the link to the DownloadManager
# Function to download the selected game and send the link to the DownloadManager
download_game() {
    local decoded_name="$1"
    decoded_name_cleaned=$(echo "$decoded_name" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')

    # Check if the game already exists in the download directory
    if [[ -f "$DOWNLOAD_DIR/$decoded_name_cleaned" ]]; then
        log_debug "Game '$decoded_name_cleaned' already exists, skipping."
        skipped_games+=("$decoded_name_cleaned")
        return
    fi

    # Check if the game is already in the download queue (download.txt)
    if grep -q "$decoded_name_cleaned" "/userdata/system/game-downloader/download.txt"; then
        log_debug "Game '$decoded_name_cleaned' already in download queue, skipping."
        skipped_games+=("$decoded_name_cleaned")
        return
    fi

    # Find the full line from the AllGames.txt file based on the cleaned game name
    game_info=$(grep -F "$decoded_name_cleaned" "$ALLGAMES_FILE")

    if [ -z "$game_info" ]; then
        log_debug "Error: Could not find download URL for '$decoded_name_cleaned'."
        dialog --infobox "Error: Could not find download URL for '$decoded_name_cleaned'." 5 40
        sleep 2
        return
    fi

    # Parse the game information (Name|URL|Destination)
    game_name=$(echo "$game_info" | cut -d '|' -f 1)
    game_url=$(echo "$game_info" | cut -d '|' -f 2)
    game_dest_dir=$(echo "$game_info" | cut -d '|' -f 3)

    # Ensure the destination directory exists
    mkdir -p "$game_dest_dir"

    # **Reverted back to appending the full game line** (Name|URL|Destination)
    echo "$game_info" >> "/userdata/system/game-downloader/download.txt"
    
    # Collect the added game
    added_games+=("$decoded_name_cleaned")
    log_debug "Game '$decoded_name_cleaned' added to download list."
}


# Function to show the letter selection menu with an "All Games" and "Return" options
select_letter() {
    # Get a sorted list of the .txt files (A.txt, B.txt, etc.) in the selected game system
    letter_list=$(ls "$DEST_DIR/$SELECTED_SYSTEM"/*.txt | grep -v "AllGames.txt" | sed -E 's/\.txt$//' | sed 's/.*\///' | sort)

    # Add "Return" and "All" options to the menu
    menu_options=("Return" "Back to System Selection" "All" "All Games")

    # Add each letter to the menu
    while read -r letter; do
        menu_options+=("$letter" "$letter")
    done <<< "$letter_list"

    # Show the menu and capture the user's choice
    selected_letter=$(dialog --title "Select a Letter" --menu "Choose a letter or select 'All Games'" 25 70 10 \
        "${menu_options[@]}" 3>&1 1>&2 2>&3)

    # If "Return" is selected, return to the system selection menu
    if [ "$selected_letter" == "Return" ]; then
        log_debug "User selected Return, returning to system selection."
        return 1  # Return to the system selection
    elif [ "$selected_letter" == "All" ]; then
        # If "All Games" is selected, link to AllGames.txt
        log_debug "User selected All Games."
        select_games "AllGames"
    else
        # Otherwise, proceed with the selected letter
        log_debug "User selected letter: $selected_letter"
        select_games "$selected_letter"
    fi
}



# Main execution loop
while true; do
    select_letter
done

log_debug "Script ended"
