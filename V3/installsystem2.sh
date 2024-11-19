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
DEST_DIR_BASE="/userdata/system/game-downloaderV2/links"

# Function to decode URL
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Function to clear text files before starting
clear_all_files() {
    rm -f "$DEST_DIR_BASE"/*/*.txt
    echo "All text files cleared."
}

# Define the predetermined order for the menu
MENU_ORDER=(
    "PSX" "PS2" "Dreamcast" "Nintendo 64" "Game Cube" "Game Boy Advance"
    "Game Boy" "Game Boy Color" "NES" "SNES" "Nintendo DS" "PSP" "PS3"
    "PS Vita" "Xbox" "Xbox 360" "Game Gear" "Master System" "Mega Drive"
    "Saturn" "Atari 2600" "Atari 5200" "Atari 7800" "PC" "Apple Macintosh"
    "MS-DOS" "Wii"
)

# Create the menu dynamically based on the predetermined order
MENU_OPTIONS=("0" "Return to Main Menu")  # Add "Return to Main Menu" as the first option
i=1
for system in "${MENU_ORDER[@]}"; do
    MENU_OPTIONS+=("$i" "$system")  # Add option number and system name
    ((i++))  # Increment the option number
done

# Main dialog menu with dynamically generated options
dialog --clear --backtitle "Game System Scraper" \
       --title "Select a System to Scrape" \
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
BASE_URL="${SYSTEMS[$selected_system]}"
DEST_DIR="$DEST_DIR_BASE/${BATOCERA_FOLDERS[$selected_system]}/$selected_system"
ROM_DIR="/userdata/roms/${BATOCERA_FOLDERS[$selected_system]}"
EXT=".chd"  # Adjust this as needed based on the system

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Function to scrape the selected system
scrape_system() {
    # Clear all text files before starting
    clear_all_files

    # Fetch the page content
    page_content=$(curl -s "$BASE_URL")

    # Parse links, decode them, and check for region-specific criteria
    echo "$page_content" | grep -oP "(?<=href=\")[^\"]*${EXT}" | while read -r game_url; do
        # Decode the URL and check for the region tags and criteria in the decoded text
        decoded_name=$(decode_url "$game_url")
        if [[ "$decoded_name" =~ Europe ]]; then  # Adjust this criteria as needed
            # Process games matching the criteria
            # Format the entry with backticks around the decoded name
            quoted_name="\`$decoded_name\`"
            # Get the first character of the decoded file name
            first_char="${decoded_name:0:1}"

            # Append to AllGames.txt with both quoted decoded name and original URL
            echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/AllGames.txt"

            # Save to the appropriate letter-based file
            if [[ "$first_char" =~ [a-zA-Z] ]]; then
                first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')
                echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/${first_char}.txt"
            elif [[ "$first_char" =~ [0-9] ]]; then
                echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/#.txt"
            else
                echo "$quoted_name|$BASE_URL$game_url|$ROM_DIR" >> "$DEST_DIR/other.txt"
            fi
        fi
    done

    echo "Scraping complete for $selected_system!"
}

# Inform the user that the scraping is starting
dialog --infobox "Scraping $selected_system. Please wait..." 10 50

# Scrape the selected system
scrape_system

# Show completion message once the process is done
dialog --infobox "Scraping complete!" 10 50
sleep 2  # Display the "Scraping complete!" message for a few seconds

# Optionally, return to the main menu or run another script after the process
bash /tmp/GameDownloader.sh
