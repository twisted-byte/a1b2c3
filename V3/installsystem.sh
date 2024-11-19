#!/bin/bash

# Ensure clear display
clear

# URLs for game system scrapers (store the URLs in an associative array)
declare -A SCRAPERS

SCRAPERS["PSX"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/psx-scraper.sh"
SCRAPERS["PS2"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/ps2-scraper.sh"
SCRAPERS["Xbox"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/xbox-scraper.sh"
SCRAPERS["Dreamcast"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/dc-scraper.sh"
SCRAPERS["Game Boy Advance"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/gba-scraper.sh"
SCRAPERS["Atari 5200"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/atari-5200-scraper.sh"
SCRAPERS["Atari 2600"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/atari2600-scraper.sh"
SCRAPERS["Atari 7800"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/atari7800-scraper.sh"
SCRAPERS["DOS"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/dos-scraper.sh"
SCRAPERS["Game Gear"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/gamegear-scraper.sh"
SCRAPERS["Game Boy"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/gb-scraper.sh"
SCRAPERS["Game Boy Color"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/gbc-scraper.sh"
SCRAPERS["GameCube"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/gc-scraper.sh"
SCRAPERS["Macintosh"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/macintosh-scraper.sh"
SCRAPERS["Master System"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/mastersystem-scraper.sh"
SCRAPERS["Mega Drive"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/megadrive-scraper.sh"
SCRAPERS["Nintendo 64"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/n64-scraper.sh"
SCRAPERS["Nintendo DS"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/nds-scraper.sh"
SCRAPERS["NES"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/nes-scraper.sh"
SCRAPERS["PC"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/pc--scraper.sh"
SCRAPERS["PS3"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/ps3-scraper.sh"
SCRAPERS["PSP"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/psp-scraper.sh"
SCRAPERS["PS Vita"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/psv-scraper.sh"
SCRAPERS["Saturn"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/saturn-scraper.sh"
SCRAPERS["SNES"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/snes-scraper.sh"
SCRAPERS["Wii"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/wii-scraper.sh"
SCRAPERS["Xbox 360"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/xbox360-scraper.sh"

# Define the predetermined order for the menu
MENU_ORDER=("PSX" "PS2" "PS3" "PSP" "PS Vita" "Xbox" "Xbox 360" "PC" "DOS" "Macintosh" "Game Boy" "Game Boy Color" "Game Boy Advance" "Nintendo DS" "Nintendo 64" "GameCube" "NES" "SNES" "Wii" "Dreamcast" "Game Gear" "Master System" "Mega Drive" "Saturn" "Atari 2600" "Atari 5200" "Atari 7800")

# Create the menu dynamically based on the predetermined order
MENU_OPTIONS=("0" "Return to Main Menu")  # Add "Return to Main Menu" as the first option
i=1
for system in "${MENU_ORDER[@]}"; do
    MENU_OPTIONS+=("$i" "$system")  # Add option number and system name
    ((i++))  # Increment the option number
done

# Main dialog menu with dynamically generated options
dialog --clear --backtitle "Game System Installer" \
       --title "Select a Game System" \
       --menu "Choose an option:" 15 50 9 \
       "${MENU_OPTIONS[@]}" \
       2>/tmp/game-downloader-choice

choice=$(< /tmp/game-downloader-choice)
rm /tmp/game-downloader-choice

# Check if the user canceled the dialog (no choice selected)
if [ -z "$choice" ]; then
    clear
    exit 0  # Exit the script when Cancel is clicked or no option is selected
fi

# If user selects "Return to Main Menu"
if [ "$choice" -eq 0 ]; then
    clear
    exec /tmp/GameDownloader.sh  # Execute the main menu script
    exit 0  # In case exec fails, exit the script
fi

# Get the selected system based on the user choice
selected_system="${MENU_ORDER[$choice-1]}"  # Adjust for 0-based indexing

# Check if a valid system was selected
if [ -z "$selected_system" ]; then
    dialog --msgbox "Invalid option selected. Please try again." 10 50
    clear
    bash /tmp/GameDownloader.sh  # Return to the main menu
    exit 1
fi

# Get the URL for the selected system
scraper_url="${SCRAPERS[$selected_system]}"

# Inform the user that the installation is starting
dialog --infobox "Installing $selected_system downloader. Please wait..." 10 50

# Download and execute the scraper script
curl -Ls "$scraper_url" -o /tmp/scraper.sh 
bash /tmp/scraper.sh  # Run the downloaded scraper and wait for it to complete

# Show completion message once the process is done (after the script finishes)
dialog --infobox "Installation complete!" 10 50
sleep 2  # Display the "Installation complete!" message for a few seconds

# Optionally, return to the main menu or run another script after the process
bash /tmp/GameDownloader.sh
