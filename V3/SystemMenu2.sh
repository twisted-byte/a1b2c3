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

# Define the predetermined scripts to be executed for each system (pulled from installsystem.sh)
declare -A SYSTEM_SCRIPTS
SYSTEM_SCRIPTS=(
    ["PSX"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-downloader-menu.sh"
    ["PS2"]="/path/to/scripts/PS2.sh"
    ["PS3"]="/path/to/scripts/PS3.sh"
    ["PSP"]="/path/to/scripts/PSP.sh"
    ["PS_Vita"]="/path/to/scripts/PS_Vita.sh"
    ["Xbox"]="/path/to/scripts/Xbox.sh"
    ["Xbox_360"]="/path/to/scripts/Xbox_360.sh"
    ["PC"]="/path/to/scripts/PC.sh"
    ["DOS"]="/path/to/scripts/DOS.sh"
    ["Macintosh"]="/path/to/scripts/Macintosh.sh"
    ["Game_Boy"]="/path/to/scripts/Game_Boy.sh"
    ["Game_Boy_Color"]="/path/to/scripts/Game_Boy_Color.sh"
    ["Game_Boy_Advance"]="/path/to/scripts/Game_Boy_Advance.sh"
    ["Nintendo_DS"]="/path/to/scripts/Nintendo_DS.sh"
    ["NES"]="/path/to/scripts/NES.sh"
    ["SNES"]="/path/to/scripts/SNES.sh"
    ["Nintendo_64"]="/path/to/scripts/Nintendo_64.sh"
    ["GameCube"]="/path/to/scripts/GameCube.sh"
    ["Wii"]="/path/to/scripts/Wii.sh"
    ["Game_Gear"]="/path/to/scripts/Game_Gear.sh"
    ["Dreamcast"]="/path/to/scripts/Dreamcast.sh"
    ["Atari_2600"]="/path/to/scripts/Atari_2600.sh"
    ["Atari_5200"]="/path/to/scripts/Atari_5200.sh"
    ["Atari_7800"]="/path/to/scripts/Atari_7800.sh"
    ["Saturn"]="/path/to/scripts/Saturn.sh"
    ["Master_System"]="/path/to/scripts/Master_System.sh"
    ["Mega_Drive"]="/path/to/scripts/Mega_Drive.sh"
)

# Define the predetermined order for the menu with internal system names
MENU_ORDER=("PSX" "PS2" "PS3" "PSP" "PS_Vita" "Xbox" "Xbox_360" "PC" "DOS" "Macintosh" "Game_Boy" "Game_Boy_Color" "Game_Boy_Advance" "Nintendo_DS" "NES" "SNES" "Nintendo_64" "GameCube" "Wii" "Game_Gear" "Master_System" "Mega_Drive" "Saturn" "Dreamcast" "Atari_2600" "Atari_5200" "Atari_7800")
# Create a list of available game systems (directories inside /userdata/system/game-downloader/links)
GAME_SYSTEMS=()
MENU_OPTIONS=()

# Loop through the predefined systems in the specified order and add them to the menu if the directory exists
index=1
for system in "${MENU_ORDER[@]}"; do
    if [ -d "$BASE_DIR/$system" ]; then
        GAME_SYSTEMS+=("$system")
        MENU_OPTIONS+=("$index" "$system")
    else
        MENU_OPTIONS+=("$index" "$system (Not Installed)")
    fi
    ((index++))
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

# Execute the corresponding script based on user choice
if [ "$choice" -eq 0 ]; then
    clear
    exit 0  # Exit the script
else
    # Get the selected game system
    SELECTED_SYSTEM="${GAME_SYSTEMS[$((choice - 1))]}"
    SCRIPT_PATH="${SYSTEM_SCRIPTS[$SELECTED_SYSTEM]}"
    
    # Check if the script exists and execute it
    if [ -f "$SCRIPT_PATH" ]; then
        bash "$SCRIPT_PATH"
    else
        dialog --msgbox "This game system isn't installed yet!" 10 50
        exit 1
    fi
fi
