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
MENU_OPTIONS+=("0" "Exit")

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
    dialog --infobox "Exiting Game Downloader..." 10 50
    sleep 2
    exit 0
else
    # Get the selected game system
    SELECTED_SYSTEM="${GAME_SYSTEMS[$((choice - 1))]}"

    # Here, you can add the logic to run the appropriate script based on the selected system
    # For example, assuming each system has its own script in the `links` folder
    SYSTEM_SCRIPT="$BASE_DIR/$SELECTED_SYSTEM/$SELECTED_SYSTEM-menu.sh"

    if [ -f "$SYSTEM_SCRIPT" ]; then
        bash "$SYSTEM_SCRIPT"
    else
        dialog --msgbox "No menu script found for $SELECTED_SYSTEM!" 10 50
    fi
fi

# Clear screen at the end
clear
