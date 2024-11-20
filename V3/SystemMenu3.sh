#!/bin/bash

# Ensure clear display
clear

# Set debug flag
DEBUG=false

# Function to log debug messages
log_debug() {
    if [ "$DEBUG" = true ]; then
        local message="$1"
        mkdir -p /userdata/system/game-downloader/debug  # Ensure the directory exists
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> /userdata/system/game-downloader/debug/menu_debug.txt
    fi
}

# Log the start of the script
log_debug "Script started."

# Define the base directory for game systems
BASE_DIR="/userdata/system/game-downloader/links"

# Check if the base directory exists
if [ ! -d "$BASE_DIR" ]; then
    dialog --msgbox "Error: The game downloader directory doesn't exist!" 10 50
    exit 1
fi

# Define the predetermined scripts to be executed for each system (pulled from installsystem.sh)
declare -A SYSTEM_SCRIPTS
SYSTEM_SCRIPTS=(
    ["PSX"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-downloader-menu.sh"
    ["PS2"]="/path/to/scripts/PS2.sh"
    ["PS3"]="/path/to/scripts/PS3.sh"
    ["PSP"]="/path/to/scripts/PSP.sh"
    ["PS Vita"]="/path/to/scripts/PS_Vita.sh"
    ["Xbox"]="/path/to/scripts/Xbox.sh"
    ["Xbox 360"]="/path/to/scripts/Xbox_360.sh"
    ["PC"]="/path/to/scripts/PC.sh"
    ["MS-DOS"]="/path/to/scripts/DOS.sh"
    ["Apple Macintosh"]="/path/to/scripts/Macintosh.sh"
    ["Game Boy"]="/path/to/scripts/Game_Boy.sh"
    ["Game Boy Color"]="/path/to/scripts/Game_Boy_Color.sh"
    ["Game Boy Advance"]="/path/to/scripts/Game_Boy_Advance.sh"
    ["Nintendo DS"]="/path/to/scripts/Nintendo_DS.sh"
    ["NES"]="/path/to/scripts/NES.sh"
    ["SNES"]="/path/to/scripts/SNES.sh"
    ["Nintendo 64"]="/path/to/scripts/Nintendo_64.sh"
    ["GameCube"]="/path/to/scripts/GameCube.sh"
    ["Wii"]="/path/to/scripts/Wii.sh"
    ["Game Gear"]="/path/to/scripts/Game_Gear.sh"
    ["Dreamcast"]="/path/to/scripts/Dreamcast.sh"
    ["Atari 2600"]="/path/to/scripts/Atari_2600.sh"
    ["Atari 5200"]="/path/to/scripts/Atari_5200.sh"
    ["Atari 7800"]="/path/to/scripts/Atari_7800.sh"
    ["Saturn"]="/path/to/scripts/Saturn.sh"
    ["Master System"]="/path/to/scripts/Master_System.sh"
    ["Mega Drive"]="/path/to/scripts/Mega_Drive.sh"
)

# Define the predetermined order for the menu with internal system names
MENU_ORDER=("PSX" "PS2" "PS3" "PSP" "PS Vita" "Xbox" "Xbox 360" "PC" "MS-DOS" "Apple Macintosh" "Game Boy" "Game Boy Color" "Game Boy Advance" "Nintendo DS" "NES" "SNES" "Nintendo 64" "GameCube" "Wii" "Game Gear" "Master System" "Mega Drive" "Saturn" "Dreamcast" "Atari 2600" "Atari 5200" "Atari 7800")
# Create a list of available game systems (directories inside /userdata/system/game-downloader/links)
GAME_SYSTEMS=()
MENU_OPTIONS=()

# Loop through the predefined systems in the specified order and add them to the menu if the directory exists
index=1
for system in "${MENU_ORDER[@]}"; do
    display_name=$(echo "$system" | tr '_' ' ')
    if [ -d "$BASE_DIR/$system" ]; then
        GAME_SYSTEMS+=("$system")
        MENU_OPTIONS+=("$index" "$display_name")
    else
        MENU_OPTIONS+=("$index" "$display_name (Not Installed)")
    fi
    ((index++))
done

# Check if any systems were found
if [ ${#GAME_SYSTEMS[@]} -eq 0 ]; then
    dialog --msgbox "No game systems found in $BASE_DIR!" 10 50
    exit 1
fi

# Add the option for the user to exit
MENU_OPTIONS+=("0" "Return")

# Main dialog menu loop
while true; do
    log_debug "Displaying menu."

    # Display menu
    dialog --clear --backtitle "Game Downloader" \
           --title "Select a Game System" \
           --menu "Choose an option:" 15 50 12 \
           "${MENU_OPTIONS[@]}" \
           2>/tmp/game-downloader-choice

    choice=$(< /tmp/game-downloader-choice)
    rm /tmp/game-downloader-choice

    # Log the user's choice
    log_debug "User selected option: $choice"

    # Check if the user canceled the dialog (no choice selected)
    if [ -z "$choice" ]; then
        log_debug "User canceled the dialog."
        clear
        dialog --infobox "Thank you for using Game Downloader! Any issues, message DTJW92 on Discord!" 10 50
        sleep 3
        exit 0  # Exit gracefully
    fi

    # Exit logic for option 0
    if [ "$choice" -eq 0 ]; then
        log_debug "Exit selected. Ending script."
        clear
        exit 0  # Exit gracefully
    fi

    # Execute the corresponding script for the selected option
    if [[ -n "${SYSTEM_SCRIPTS[${GAME_SYSTEMS[$((choice - 1))]}]}" ]]; then
        log_debug "Running script for option $choice."
        SCRIPT_PATH="${SYSTEM_SCRIPTS[${GAME_SYSTEMS[$((choice - 1))]}]}"

        # Check if the script path is a URL or a local file
        if [[ "$SCRIPT_PATH" =~ ^https?:// ]]; then
            # It's a URL, download it
            curl -s "$SCRIPT_PATH" -o "/tmp/${GAME_SYSTEMS[$((choice - 1))]}.sh" && bash "/tmp/${GAME_SYSTEMS[$((choice - 1))]}.sh"
        elif [ -f "$SCRIPT_PATH" ]; then
            # It's a local file, execute it
            bash "$SCRIPT_PATH"
        else
            # Script doesn't exist
            dialog --msgbox "This game system isn't installed yet!" 10 50
            exit 1
        fi
        log_debug "Script for option $choice completed."
    else
        log_debug "Invalid option selected: $choice."
        dialog --msgbox "Invalid option selected. Please try again." 10 50
    fi
done
