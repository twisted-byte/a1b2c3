#!/bin/bash
clear
# Define the systems and URLs
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

# Function to decode URL (ASCII decode)
decode_url() {
    echo -n "$1" | sed 's/%/\\x/g' | xargs -0 printf "%b"
}

# Clear all text files before starting
clear_all_files() {
    local DEST_DIR="$1"
    rm -f "$DEST_DIR"/*.txt
}

# Function to scrape data for a system
scrape_system() {
    local system="$1"
    local BASE_URL="${SYSTEMS[$system]}"
    local DEST_DIR="/userdata/system/game-downloader/links/$system"
    local ROM_DIR="/userdata/roms/${system,,}"  # Using lowercase system name for ROM directory
    local EXTENSIONS=(".chd" ".zip" ".iso")  # File extensions to check for

    # Ensure the destination directory exists
    mkdir -p "$DEST_DIR"

    # Clear all existing files in the destination directory
    clear_all_files "$DEST_DIR"

    # Fetch the page content
    page_content=$(curl -s "$BASE_URL") || { echo "Failed to fetch $BASE_URL"; return; }

    # Parse links and check for Europe
    for EXT in "${EXTENSIONS[@]}"; do
        echo "$page_content" | grep -oP "(?<=href=\")[^\"]*${EXT}" | while read -r game_url; do
            # Decode the URL and check for Europe
            decoded_name=$(decode_url "$game_url")
            if [[ "$decoded_name" =~ Europe ]]; then
                # Format the entry with backticks around the decoded name
                quoted_name="\`$decoded_name\`"
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
    done
}

# Main loop to scrape multiple systems
for system in "${!SYSTEMS[@]}"; do
    scrape_system "$system" &
done

# Wait for all background processes to finish
wait

echo "Scraping complete!"
