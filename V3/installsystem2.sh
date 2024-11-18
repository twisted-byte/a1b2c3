#!/bin/bash

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

# Function to display the system selection menu
select_system() {
    local MENU_OPTIONS=("0" "Return to Main Menu")
    local i=1

    # Prepare menu options for systems
    for system in "${!SYSTEMS[@]}"; do
        MENU_OPTIONS+=("$i" "$system")
        ((i++))
    done

    # Show the dialog menu
    selected_system=$(dialog --clear --backtitle "Game System Scraper" \
        --title "Select a System to Scrape" \
        --menu "Choose a system to scrape for:" 15 50 9 \
        "${MENU_OPTIONS[@]}" 2>/tmp/scraper-choice)

    choice=$(< /tmp/scraper-choice)
    rm /tmp/scraper-choice

    if [ -z "$choice" ]; then
        clear
        echo "No system selected, exiting."
        exit 1  # Exit if no system is selected
    fi

    if [ "$choice" -eq 0 ]; then
        clear
        exit 0  # Exit if "Return" is selected
    fi

    SELECTED_SYSTEM="${MENU_OPTIONS[$((choice * 2))]}"
    DEST_DIR="$DEST_DIR_BASE/${BATOCERA_FOLDERS[$SELECTED_SYSTEM]}/$SELECTED_SYSTEM"
}

# Main loop to handle scraping
while true; do
    # Show system selection menu
    select_system

    echo "Starting scrape for $SELECTED_SYSTEM..."
    clear_all_files

    # Fetch the page content once
    page_content=$(curl -s "${SYSTEMS[$SELECTED_SYSTEM]}")

    # Extract and store all matching URLs in temp_urls.txt
    echo "$page_content" | grep -oP 'href="([^"]+\.(chd|zip|iso))"' | sed -E 's/href="(.*)"/\1/' > temp_urls.txt

    # Process each URL from the temp_urls.txt file
    while read -r game_url; do
        # Decode the file name (basename of the URL)
        decoded_name=$(decode_url "$(basename "$game_url")")
        first_char="${decoded_name:0:1}"
        first_char=${first_char^^}  # Convert to uppercase

        quoted_name="\`$decoded_name\`"
        full_url="${SYSTEMS[$SELECTED_SYSTEM]}$game_url"

        # Write to AllGames.txt
        echo "$quoted_name|$full_url|$ROM_DIR" >> "$DEST_DIR/AllGames.txt"

        # Write to letter-specific files
        if [[ "$first_char" =~ [A-Z] ]]; then
            echo "$quoted_name|$full_url|$ROM_DIR" >> "$DEST_DIR/${first_char}.txt"
        elif [[ "$first_char" =~ [0-9] ]]; then
            echo "$quoted_name|$full_url|$ROM_DIR" >> "$DEST_DIR/#.txt"
        else
            echo "$quoted_name|$full_url|$ROM_DIR" >> "$DEST_DIR/other.txt"
        fi
    done < temp_urls.txt

    # Clean up the temporary file
    rm -f temp_urls.txt

    echo "Scraping complete for $SELECTED_SYSTEM!"

    # Ask if the user wants to scrape another system or exit
    dialog --title "Continue?" --yesno "Do you want to scrape another system?" 7 50
    if [ $? -eq 1 ]; then
        break  # Exit if "No" is selected
    fi
done

echo "Goodbye!"
clear
