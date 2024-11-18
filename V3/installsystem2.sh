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

# Batocera system-to-folder mapping
declare -A BATOCERA_FOLDERS
BATOCERA_FOLDERS=(
    ["Nintendo Game Boy Advance"]="gameboy_advance"
    ["PSX"]="psx"
    ["PS2"]="ps2"
    ["Dreamcast"]="dc"
    ["Nintendo 64"]="n64"
    ["Game Cube"]="gamecube"
    ["Game Boy"]="gameboy"
    ["Game Boy Color"]="gameboy_color"
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
    ["PC"]="pc"
    ["Apple Macintosh"]="macintosh"
    ["MS-DOS"]="msdos"
    ["Wii"]="wii"
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

# Main loop for systems
for SYSTEM in "${!SYSTEMS[@]}"; do
    MANUFACTURER=$(get_manufacturer "$SYSTEM")
    DEST_DIR="$DEST_DIR_BASE/$MANUFACTURER/$SYSTEM"
    ROM_DIR="/userdata/roms/${BATOCERA_FOLDERS[$SYSTEM]}"  # Use Batocera folder mapping
    mkdir -p "$DEST_DIR"

    echo "Starting scrape for $SYSTEM..."
    clear_all_files

    # Start scraping in the background
   {
    # Fetch the page content once
    page_content=$(curl -s "${SYSTEMS[$SYSTEM]}")

    # Extract and store all matching URLs in temp_urls.txt
    echo "$page_content" | grep -oP 'href="([^"]+\.(chd|zip|iso))"' | sed -E 's/href="(.*)"/\1/' > temp_urls.txt

    # Process each URL from the temp_urls.txt file
    while read -r game_url; do
        # Decode the file name (basename of the URL)
        decoded_name=$(decode_url "$(basename "$game_url")")
        first_char="${decoded_name:0:1}"
        first_char=${first_char^^}  # Convert to uppercase

        quoted_name="\`$decoded_name\`"
        full_url="${SYSTEMS[$SYSTEM]}$game_url"

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
}

done

# Wait for all background jobs to finish before exiting the script
wait

echo "All scraping tasks are complete!"
