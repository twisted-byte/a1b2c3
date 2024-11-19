#!/bin/bash

# Ensure clear display
clear

# Predefined systems and their URLs
declare -A SYSTEMS
SYSTEMS=(
    ["PSX"]="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
    ["PS2"]="https://myrient.erista.me/files/Redump/Sony%20-%20PlayStation%202/"
    ["Dreamcast"]="https://myrient.erista.me/files/Internet%20Archive/chadmaster/dc-chd-zstd-redump/dc-chd-zstd/"
    ["Nintendo 64"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Nintendo%2064%20(ByteSwapped)/"
    ["Game Cube"]="https://myrient.erista.me/files/Internet%20Archive/kodi_amp_spmc_canada/EuropeanGamecubeCollectionByGhostware/"
    ["Game Boy Advance"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Game%20Boy%20Advance/"
    ["Game Boy"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Game%20Boy/"
    ["Game Boy Color"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Game%20Boy%20Color/"
    ["NES"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Nintendo%20Entertainment%20System%20(Headerless)/"
    ["SNES"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Super%20Nintendo%20Entertainment%20System/"
    ["Nintendo DS"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Nintendo%20DS%20(Decrypted)/"
    ["PSP"]="https://myrient.erista.me/files/Redump/Sony%20-%20PlayStation%20Portable/"
    ["PS3"]="https://myrient.erista.me/files/No-Intro/Sony%20-%20PlayStation%203%20(PSN)%20(Content)/"
    ["PS Vita"]="https://myrient.erista.me/files/No-Intro/Unofficial%20-%20Sony%20-%20PlayStation%20Vita%20(NoNpDrm)/"
    ["Xbox"]="https://myrient.erista.me/files/Redump/Microsoft%20-%20Xbox/"
    ["Xbox 360"]="https://myrient.erista.me/files/Redump/Microsoft%20-%20Xbox%20360/"
    ["Game Gear"]="https://myrient.erista.me/files/No-Intro/Sega%20-%20Game%20Gear/"
    ["Master System"]="https://myrient.erista.me/files/No-Intro/Sega%20-%20Master%20System%20-%20Mark%20III/"
    ["Mega Drive"]="https://myrient.erista.me/files/No-Intro/Sega%20-%20Mega%20Drive%20-%20Genesis/"
    ["Saturn"]="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_saturn/CHD-Saturn/Europe/"
    ["Atari 2600"]="https://myrient.erista.me/files/No-Intro/Atari%20-%202600/"
    ["Atari 5200"]="https://myrient.erista.me/files/No-Intro/Atari%20-%205200/"
    ["Atari 7800"]="https://myrient.erista.me/files/No-Intro/Atari%20-%207800/"
    ["PC"]="https://myrient.erista.me/files/Redump/IBM%20-%20PC%20compatible/"
    ["Apple Macintosh"]="https://myrient.erista.me/files/Redump/Apple%20-%20Macintosh/"
    ["MS-DOS"]="https://myrient.erista.me/files/Internet%20Archive/sketch_the_cow/Total_DOS_Collection_Release_16_March_2019/Games/Images/CD/"
    ["Wii"]="https://myrient.erista.me/files/Redump/Nintendo%20-%20Wii%20-%20NKit%20RVZ%20[zstd-19-128k]/"
)

# Batocera system-to-folder mapping
declare -A BATOCERA_FOLDERS
BATOCERA_FOLDERS=(
    ["Game Boy Advance"]="gba"
    ["PSX"]="psx"
    ["PS2"]="ps2"
    ["Dreamcast"]="dreamcast"
    ["Nintendo 64"]="n64"
    ["Game Cube"]="gamecube"
    ["Game Boy"]="gb"
    ["Game Boy Color"]="gbc"
    ["NES"]="nes"
    ["SNES"]="snes"
    ["Nintendo DS"]="nds"
    ["PSP"]="psp"
    ["PS3"]="ps3"
    ["PS Vita"]="psvita"
    ["Xbox"]="xbox"
    ["Xbox 360"]="xbox360"
    ["Game Gear"]="gamegear"
    ["Master System"]="mastersystem"
    ["Mega Drive"]="megadrive"
    ["Saturn"]="saturn"
    ["Atari 2600"]="atari2600"
    ["Atari 5200"]="atari5200"
    ["Atari 7800"]="atari7800"
    ["PC"]="windows_installers"
    ["Apple Macintosh"]="macintosh"
    ["MS-DOS"]="dos"
    ["Wii"]="wii"
)

# Destination base directory
DEST_DIR_BASE="/userdata/system/game-downloader/links"

# Function to decode URL
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Function to clear text files before starting
clear_all_files() {
    rm -f "$DEST_DIR_BASE"/*/*.txt
    echo "All text files cleared."
}

# Clear all text files before starting
clear_all_files

# Define the predetermined order for the menu
MENU_ORDER=(
    "Apple Macintosh" "Atari 2600" "Atari 5200" "Atari 7800" "Dreamcast" "Game Boy"
    "Game Boy Advance" "Game Boy Color" "Game Cube" "Game Gear" "Master System"
    "Mega Drive" "MS-DOS" "NES" "Nintendo 64" "Nintendo DS" "PC" "PS Vita" "PS2"
    "PS3" "PSP" "PSX" "Saturn" "SNES" "Wii" "Xbox" "Xbox 360"
)

# Create the checklist dynamically based on the predetermined order
CHECKLIST_ITEMS=()
i=1
for system in "${MENU_ORDER[@]}"; do
    CHECKLIST_ITEMS+=("$i" "$system" "off")  # Add option number, system name, and default to "off"
    ((i++))  # Increment the option number
done

# Main dialog checklist menu
dialog --clear --backtitle "Game System Scraper" \
       --title "Select Systems to Scrape" \
       --checklist "Choose systems to scrape:" 20 60 15 \
       "${CHECKLIST_ITEMS[@]}" \
       2>/tmp/game-downloader-choice

choices=$(< /tmp/game-downloader-choice)
rm /tmp/game-downloader-choice

# Check if the user canceled the dialog (no choice selected)
if [ -z "$choices" ]; then
    clear
    exit 0  # Exit the script when Cancel is clicked or no option is selected
fi

# Function to scrape the selected systems
scrape_system() {
    local system="$1"
    local BASE_URL="${SYSTEMS[$system]}"
    local DEST_DIR="$DEST_DIR_BASE/$system"
    local ROM_DIR="/userdata/roms/${BATOCERA_FOLDERS[$system]}"
    local EXTENSIONS=(".chd" ".zip" ".iso")  # List of extensions to search for

    # Ensure the destination directory exists
    mkdir -p "$DEST_DIR"

    # Fetch the page content
    page_content=$(curl -s --fail "$BASE_URL") || { echo "Failed to fetch $BASE_URL"; exit 1; }

    # Check if the content is empty
    if [ -z "$page_content" ]; then
        echo "No content fetched from $BASE_URL"
        return  # Skip this system if no content is fetched
    fi

    # Parse links, decode them, and check for region-specific criteria
    for EXT in "${EXTENSIONS[@]}"; do
        echo "$page_content" | grep -oP "(?<=href=\")[^\"]*${EXT}" | while read -r game_url; do
            decoded_name=$(decode_url "$game_url")
            if [[ "$decoded_name" =~ Europe ]]; then  # Adjust this criteria as needed
                quoted_name="\`$decoded_name\`"
                first_char="${decoded_name:0:1}"
                echo "$quoted_name|$first_char" >> "$DEST_DIR/${first_char}.txt"
            fi
        done
    done
}

# Run the scraping processes in the background
for system in $choices; do
    scrape_system "$system"   # Run the scrape_system function in the background
done

# Wait for all background tasks to complete
wait

# After scraping is complete, show the dialog box for completion
dialog --clear --msgbox "Scraping is complete!" 6 40

# Exit after completion
clear
exit 0
