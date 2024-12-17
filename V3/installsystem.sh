#!/bin/bash

# Ensure clear display
clear

# URLs for game system scrapers (store the URLs in an associative array)
declare -A SCRAPERS

SCRAPERS["PSX"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/psx-scraper.sh"
SCRAPERS["PS2"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/ps2-scraper.sh"
SCRAPERS["Xbox"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/xbox-scraper.sh"
SCRAPERS["Dreamcast"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/dc-scraper.sh"
SCRAPERS["Game_Boy_Advance"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/gba-scraper.sh"
SCRAPERS["Atari_5200"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/atari-5200-scraper.sh"
SCRAPERS["Atari_2600"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/atari2600-scraper.sh"
SCRAPERS["Atari_7800"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/atari7800-scraper.sh"
SCRAPERS["DOS"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/dos-scraper.sh"
SCRAPERS["Game_Gear"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/gamegear-scraper.sh"
SCRAPERS["Game_Boy"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/gb-scraper.sh"
SCRAPERS["Game_Boy_Color"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/gbc-scraper.sh"
SCRAPERS["GameCube"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/gc-scraper.sh"
SCRAPERS["Macintosh"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/macintosh-scraper.sh"
SCRAPERS["Master_System"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/mastersystem-scraper.sh"
SCRAPERS["Mega_Drive"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/megadrive-scraper.sh"
SCRAPERS["Nintendo_64"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/n64-scraper.sh"
SCRAPERS["Nintendo_DS"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/nds-scraper.sh"
SCRAPERS["NES"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/nes-scraper.sh" 
#SCRAPERS["PC"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/pc-scraper.sh" 
SCRAPERS["PS3"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/ps3-scraper.sh"
SCRAPERS["PSP"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/psp-scraper.sh" 
SCRAPERS["PS_Vita"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/psv-scraper.sh"
SCRAPERS["Saturn"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/saturn-scraper.sh"
SCRAPERS["SNES"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/snes-scraper.sh"
SCRAPERS["Wii"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/wii-scraper.sh" 
SCRAPERS["Xbox_360"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/xbox360-scraper.sh"
SCRAPERS["SegaCD"]="https://raw.githubusercontent.com/DTJW92/game-downloader/main/scrapers/segacd-scraper.sh"

# Define the predetermined order for the menu with internal system names
MENU_ORDER=("PSX" "PS2" "PS3" "PSP" "PS_Vita" "Xbox" "Xbox_360" "DOS" "Macintosh" "Game_Boy" "Game_Boy_Color" "Game_Boy_Advance" "Nintendo_DS" "NES" "SNES" "Nintendo_64" "GameCube" "Wii" "Game_Gear" "Master_System" "Mega_Drive" "Saturn" "Dreamcast" "SegaCD" "Atari_2600" "Atari_5200" "Atari_7800")

# Create the menu dynamically based on the predetermined order
MENU_OPTIONS=()
for system in "${MENU_ORDER[@]}"; do
    MENU_OPTIONS+=("$system" "" "OFF")  # Use the internal name directly, default to OFF
done

# Main dialog checklist menu
choices=$(dialog --clear --backtitle "Game System Installer" \
       --title "Select Game Systems" \
       --checklist "Use SPACE to select systems for installation. Press ENTER when done:" 20 60 15 \
       "${MENU_OPTIONS[@]}" \
       3>&1 1>&2 2>&3 3>&-)

# Check if the user canceled the dialog (no choice selected)
if [ -z "$choices" ]; then
    clear
    exit 0  # Exit the script when Cancel is clicked or no option is selected
fi

# Iterate over each selected system and run the corresponding scraper
IFS=$' '  # Use newline as the separator for choices

for system in $choices; do
    # Remove quotes from the system name, if any
    system=$(sed 's/^"//;s/"$//' <<< "$system")

    # Get the URL for the selected system
    scraper_url="${SCRAPERS[$system]}"

    # Check if the scraper URL exists for the system (to avoid errors)
    if [[ -z "$scraper_url" ]]; then
        dialog --infobox "Error: Scraper not found for $system." 10 50
        continue  # Skip this system if no scraper URL exists
    fi

    # Inform the user that the installation is starting
    dialog --infobox "Installing $system downloader. Please wait..." 10 50

    # Download and execute the scraper script
    curl -Ls "$scraper_url" -o /tmp/scraper.sh 
    bash /tmp/scraper.sh > /dev/null 2>&1 &  # Run the downloaded scraper and wait for it to complete
    
    wait
    # Show completion message once the process is done (after the script finishes)
    dialog --infobox "$system installation complete!" 10 50
    sleep 2  # Display the "Installation complete!" message for a few seconds
done

# Optionally, return to the main menu or run another script after the process
exec /tmp/GameDownloader.sh
