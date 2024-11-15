#!/bin/bash

# Predefined systems and their URLs
declare -A SYSTEMS
SYSTEMS=(
    ["Nintendo Game Boy Advance"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Game%20Boy%20Advance/"
    ["PSX"]="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
    ["PS2"]="https://myrient.erista.me/files/Redump/Sony%20-%20PlayStation%202/"
    ["Dreamcast"]="https://myrient.erista.me/files/Internet%20Archive/chadmaster/dc-chd-zstd-redump/dc-chd-zstd/"
    ["Nintendo 64"]="https://myrient.erista.me/files/No-Intro/Nintendo%20-%20Nintendo%2064%20(BigEndian)/"
    ["Game Cube"]="https://myrient.erista.me/files/Internet%20Archive/kodi_amp_spmc_canada/EuropeanGamecubeCollectionByGhostware/"
)

# Destination base directory
DEST_DIR_BASE="/userdata/system/game-downloaderV2/links"

# Extensions for web scraping systems
FILE_EXTENSIONS=(".chd" ".zip" ".iso")

# Function for handling PC files via IA
process_pc_files() {
    echo "Processing IA files for 'PC'..."

    DEST_DIR="$DEST_DIR_BASE/PC"
    mkdir -p "$DEST_DIR"

    # Add IA identifiers to process
    PC_IDENTIFIERS=("collection1" "collection2" "collection3") # Replace with actual IA collections

    # Loop through each identifier, categorize and save
    for identifier in "${PC_IDENTIFIERS[@]}"; do
        ia list "$identifier" | while read -r file; do
            decoded_name="$file"  # Directly use the file as decoded name (IA identifier usually has readable names)
            first_letter=$(echo "$decoded_name" | cut -c1 | tr '[:lower:]' '[:upper:]')
            entry="$decoded_name | ia download $identifier $file"

            if [[ "$first_letter" =~ [A-Z] ]]; then
                echo "$entry" >> "$DEST_DIR/${first_letter}.txt"
            elif [[ "$first_letter" =~ [0-9] ]]; then
                echo "$entry" >> "$DEST_DIR/#.txt"
            else
                echo "$entry" >> "$DEST_DIR/other.txt"
            fi
        done
    done
}

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
        "Dreamcast"|"Genesis"|"Saturn"|"Game Gear") echo "Sega" ;;
        "Nintendo Game Boy Advance"|"Nintendo 64"|"Game Cube"|"Wii"|"Wii U"|"Switch"|"Nintendo DS"|"Nintendo 3DS"|"Game Boy"|"Game Boy Color") echo "Nintendo" ;;
        "PC") echo "PC" ;;  # PC system
        *) echo "Other" ;;
    esac
}

# Main loop for systems
for SYSTEM in "${!SYSTEMS[@]}"; do
    if [[ "$SYSTEM" == "PC" ]]; then
        process_pc_files
    else
        MANUFACTURER=$(get_manufacturer "$SYSTEM")
        DEST_DIR="$DEST_DIR_BASE/$MANUFACTURER/$SYSTEM"
        mkdir -p "$DEST_DIR"

        echo "Starting scrape for $SYSTEM..."
        clear_all_files

        page_content=$(curl -s "${SYSTEMS[$SYSTEM]}")
        for EXT in "${FILE_EXTENSIONS[@]}"; do
            echo "$page_content" | grep -oP "(?<=href=\")[^\"]*$EXT" | while read -r game_url; do
                decoded_name=$(decode_url "$game_url")
                first_char="${decoded_name:0:1}"
                quoted_name="\`$decoded_name\`"

                echo "$quoted_name|${SYSTEMS[$SYSTEM]}$game_url" >> "$DEST_DIR/AllGames.txt"

                if [[ "$first_char" =~ [A-Za-z] ]]; then
                    first_char=$(echo "$first_char" | tr 'a-z' 'A-Z')
                    echo "$quoted_name|${SYSTEMS[$SYSTEM]}$game_url" >> "$DEST_DIR/${first_char}.txt"
                elif [[ "$first_char" =~ [0-9] ]]; then
                    echo "$quoted_name|${SYSTEMS[$SYSTEM]}$game_url" >> "$DEST_DIR/#.txt"
                else
                    echo "$quoted_name|${SYSTEMS[$SYSTEM]}$game_url" >> "$DEST_DIR/other.txt"
                fi
            done
        done

        echo "Scraping complete for $SYSTEM!"
    fi
done
