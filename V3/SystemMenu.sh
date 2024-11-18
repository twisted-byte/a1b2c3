#!/bin/bash
# Ensure clear display
clear

# Define the base directory for game systems
BASE_DIR="/userdata/system/game-downloader/links"

# Check if the base directory exists
if [ ! -d "$BASE_DIR" ]; then
    dialog --msgbox "Error: The game downloader directory doesn't exist!" 10 50
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
    dialog --msgbox "No game systems found in $BASE_DIR!" 10 50
    exit 1
fi

# Add the option for the user to exit
MENU_OPTIONS=("0" "Return" "${MENU_OPTIONS[@]}")

# Main dialog menu with loop to keep the menu active until a valid choice is selected
dialog --clear --backtitle "Game Downloader" \
       --title "Select a Game System" \
       --menu "Choose an option:" 15 50 12 \
       "${MENU_OPTIONS[@]}" 2>/tmp/game-downloader-choice

choice=$(< /tmp/game-downloader-choice)
rm /tmp/game-downloader-choice

# Check if the user canceled the dialog (no choice selected)
if [ -z "$choice" ]; then
    clear
    dialog --infobox "Thank you for using Game Downloader! Any issues, message DTJW92 on Discord!" 10 50
    sleep 3
    exit 0  # Exit the script when Cancel is clicked or no option is selected
fi

# Execute the corresponding action based on user choice
if [ "$choice" -eq 0 ]; then
    clear
    exec /tmp/GameDownloader.sh  # Execute the main menu script
    exit 0  # In case exec fails, exit the script
else
    # Get the selected game system
    SELECTED_SYSTEM="${GAME_SYSTEMS[$((choice - 1))]}"
fi

# Define directories and files
DEST_DIR="$BASE_DIR/$SELECTED_SYSTEM"
ALLGAMES_FILE="$DEST_DIR/AllGames.txt"  # File containing the full list of games with URLs
DOWNLOAD_DIR="$DEST_DIR"  # Download directory

# Ensure the download directory exists
mkdir -p "$DOWNLOAD_DIR"

# Initialize arrays to hold skipped and added games
skipped_games=()
added_games=()

# Function to display the game list and allow selection
select_games() {
    local letter="$1"
    local file

    # Set file path based on the selection
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
        # Split game by .chd to treat each game as a separate item
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

    # Find the game URL and folder from the AllGames.txt file
    game_info=$(grep -F "$decoded_name_cleaned" "$ALLGAMES_FILE")
    game_url=$(echo "$game_info" | cut -d '|' -f 2)
    game_folder=$(echo "$game_info" | cut -d '|' -f 3)

    if [ -z "$game_url" ]; then
        dialog --infobox "Error: Could not find download URL for '$decoded_name_cleaned'." 5 40
        sleep 2
        return
    fi

    if [ -z "$game_folder" ]; then
        dialog --infobox "Error: Could not find destination folder for '$decoded_name_cleaned'." 5 40
        sleep 2
        return
    fi

    # Append the decoded name, URL, and folder to the download.txt file
    echo "$decoded_name_cleaned|$game_url|$game_folder" >> "/userdata/system/game-downloader/download.txt"
    
    # Collect the added game
    added_games+=("$decoded_name_cleaned")
}
# Function to show the letter selection menu with an "All Games" and "Return" options
select_letter() {
    letter_list=$(ls "$DEST_DIR" | grep -oP '^[a-zA-Z#]' | sort | uniq)

    # Add "All" option to the menu
    menu_options=("All" "All Games")

    while read -r letter; do
        menu_options+=("$letter" "$letter")
    done <<< "$letter_list"

    selected_letter=$(dialog --title "Select a Letter" --menu "Choose a letter or select 'All Games'" 25 70 10 \
        "${menu_options[@]}" 3>&1 1>&2 2>&3)

    # If "Return" is selected, return to the system selection
    if [ "$selected_letter" == "Return" ]; then
        return 1  # Return to the system selection
    elif [ "$selected_letter" == "All" ]; then
        # If "All Games" is selected, link to AllGames.txt
        select_games "AllGames"
    else
        # Otherwise, proceed with the selected letter
        select_games "$selected_letter"
    fi
}

# Main loop to process selected games
while true; do
    echo "Selected System: $SELECTED_SYSTEM"  # Debugging step
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
clear
echo "Goodbye!"
