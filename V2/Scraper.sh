#!/bin/bash

# Predefined systems and their URLs
declare -A SYSTEMS
SYSTEMS=(
    ["Nintendo Game Boy Advance"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Game%20Boy%20Advance/"
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

# Destination base directory
DEST_DIR_BASE="/userdata/system/game-downloaderV2/links"

# Extensions for web scraping systems
FILE_EXTENSIONS=(".chd" ".zip" ".iso")

# Function to decode URL
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Function to clear text files before starting
clear_all_files() {
    rm -f "$DEST_DIR_BASE"/*/*.txt
    echo "All text files cleared."
}

# Determine manufacturer
get_manufacturer() {
    case "$1" in
        "PSX"|"PS2"|"PS3"|"PS4"|"PS5"|"PSP"|"PS Vita") echo "Sony" ;;
        "Xbox"|"Xbox 360"|"Xbox One"|"Xbox Series X"|"Xbox Series S") echo "Microsoft" ;;
        "Dreamcast"|"Genesis"|"Saturn"|"Game Gear"|"Master System") echo "Sega" ;;
        "Nintendo Game Boy Advance"|"Nintendo 64"|"Game Cube"|"Wii"|"Wii U"|"Switch"|"Nintendo DS"|"Nintendo 3DS"|"Game Boy"|"Game Boy Color"|"NES"|"SNES") echo "Nintendo" ;;
        "PC"|"MS DOS"|"Apple Macintosh") echo "PC" ;;  # PC system
        *) echo "Other" ;;
    esac
}

# Main loop for systems
for SYSTEM in "${!SYSTEMS[@]}"; do
    MANUFACTURER=$(get_manufacturer "$SYSTEM")
    DEST_DIR="$DEST_DIR_BASE/$MANUFACTURER/$SYSTEM"
    mkdir -p "$DEST_DIR"

    echo "Starting scrape for $SYSTEM..."
    clear_all_files

    # Initialize variables to accumulate results
    ALL_GAMES=""
    A_TO_Z=""
    NUMERIC="#.txt"
    OTHER="other.txt"

    # Start scraping in the background
    {
        page_content=$(curl -s "${SYSTEMS[$SYSTEM]}")
        for EXT in "${FILE_EXTENSIONS[@]}"; do
            curl -s "${SYSTEMS[$SYSTEM]}" | grep -oP 'href="([^"]+\.(chd|zip|iso))"' | sed -E 's/href="(.*)"/\1/' | while read -r game_url; do
                decoded_name=$(decode_url "$game_url")
                first_char="${decoded_name:0:1}"
                quoted_name="\`$decoded_name\`"

                ALL_GAMES+="$quoted_name|${SYSTEMS[$SYSTEM]}$game_url"$'\n'

                if [[ "$first_char" =~ [A-Za-z] ]]; then
                    first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')
                    A_TO_Z+="$quoted_name|${SYSTEMS[$SYSTEM]}$game_url"$'\n'
                elif [[ "$first_char" =~ [0-9] ]]; then
                    NUMERIC+="$quoted_name|${SYSTEMS[$SYSTEM]}$game_url"$'\n'
                else
                    OTHER+="$quoted_name|${SYSTEMS[$SYSTEM]}$game_url"$'\n'
                fi
            done
        done

        # Write all results at once after scraping
        echo "$ALL_GAMES" >> "$DEST_DIR/AllGames.txt"
        echo "$A_TO_Z" >> "$DEST_DIR/${first_char}.txt"
        echo "$NUMERIC" >> "$DEST_DIR/$NUMERIC"
        echo "$OTHER" >> "$DEST_DIR/$OTHER"
    }   # This sends the block to run in the background

done

# Wait for all background jobs to finish before exiting the script
wait

echo "All scraping tasks are complete!"
