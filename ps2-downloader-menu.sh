#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Redump/Sony%20-%20PlayStation%202/"
DEST_DIR="/userdata/system/game-downloader/ps2links"
DOWNLOAD_DIR="/userdata/roms/ps2"  # Update this to your desired download directory
TEMP_DIR="/tmp/ps2_download"  # Temporary directory for downloading and extracting
ALLGAMES_FILE="$DEST_DIR/AllGames.txt"  # File containing the full list of games with URLs

# Ensure the download and temporary directories exist
mkdir -p "$DOWNLOAD_DIR" "$TEMP_DIR"

# Function to display the game list and allow selection
select_games() {
    local letter="$1"
    local file="$DEST_DIR/${letter}.txt"

    if [[ ! -f "$file" ]]; then
        dialog --infobox "No games found for letter '$letter'." 5 40
        sleep 2
        return
    fi

    # Read the list of games from the file and prepare the dialog input
    local game_list=()
    while IFS="|" read -r decoded_name encoded_url; do
        game_list+=("$decoded_name" "" off)
    done < "$file"

    # Use dialog to show the list of games for the selected letter
    selected_games=$(dialog --title "Select Games" --checklist "Choose games to download" 15 50 8 \
        "${game_list[@]}" 3>&1 1>&2 2>&3)

    # If no games are selected, exit
    if [ -z "$selected_games" ]; then
        return
    fi

    # Loop over the selected games
    IFS=$'\n'
    for game in $selected_games; do
        game_items=$(echo "$game" | sed 's/\.zip/.zip\n/g')

        # Iterate over each game item found in the split
        while IFS= read -r game_item; do
            if [[ -n "$game_item" ]]; then
                game_item_cleaned=$(echo "$game_item" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')
                if [[ -n "$game_item_cleaned" ]]; then
                    download_game "$game_item_cleaned"
                fi
            fi
        done <<< "$game_items"
    done
}

# Function to download the selected game
download_game() {
    local decoded_name="$1"
    decoded_name_cleaned=$(echo "$decoded_name" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')
    game_url=$(grep -F "$decoded_name_cleaned" "$ALLGAMES_FILE" | cut -d '|' -f 2)

    if [ -z "$game_url" ]; then
        dialog --infobox "Error: Could not find download URL for '$decoded_name_cleaned'." 5 40
        sleep 2
        return
    fi

    # Determine the folder name based on the zip file name (remove .zip extension)
    folder_name=$(basename "$decoded_name_cleaned" .zip)
    extracted_folder="$DOWNLOAD_DIR/$folder_name"

    # Check if the folder already exists
    if [[ -d "$extracted_folder" ]]; then
        dialog --infobox "'$folder_name' already exists. Skipping download." 5 40
        sleep 2
        return
    fi

    # Show the message about download size and then start the download process
    dialog --infobox "Please note; some PS2 games are much larger than others, so they may take longer to download." 5 50
    sleep 2

    # Download the .zip file to the temporary directory
    zip_file="$TEMP_DIR/$(basename "$decoded_name_cleaned")"
    (
        wget -c "$game_url" -O "$zip_file" --progress=dot 2>&1 | while read -r line; do
            # Extract the percentage progress from the wget output
            if [[ "$line" =~ ([0-9]+)% ]]; then
                percent="${BASH_REMATCH[1]}"
                # Update progress bar with percentage
                echo $percent
            fi
        done
    ) | dialog --title "Downloading $decoded_name_cleaned" --gauge "Downloading..." 10 70 0

    if [[ $? -ne 0 ]]; then
        dialog --infobox "Error downloading '$decoded_name_cleaned'." 5 40
        sleep 2
        return
    fi

    # Unzip the file into the folder within /roms/ps2
    mkdir -p "$extracted_folder"
    unzip -o "$zip_file" -d "$extracted_folder"

    # Remove the downloaded zip file after extraction
    rm -f "$zip_file"

    if [[ $? -eq 0 ]]; then
        dialog --infobox "Downloaded and extracted '$folder_name' successfully." 5 40
        sleep 2
    else
        dialog --infobox "Error extracting '$folder_name'." 5 40
        sleep 2
    fi
}

# Function to show the letter selection menu
select_letter() {
    letter_list=$(ls "$DEST_DIR" | grep -oP '^[a-zA-Z#]' | sort | uniq)
    menu_options=()
    while read -r letter; do
        menu_options+=("$letter" "$letter")
    done <<< "$letter_list"

    selected_letter=$(dialog --title "Select a Letter" --menu "Choose a letter" 15 50 8 \
        "${menu_options[@]}" 3>&1 1>&2 2>&3)

    if [ -z "$selected_letter" ]; then
        return 1
    fi

    select_games "$selected_letter"
}

# Main execution flow
while true; do
    select_letter
    if [ $? -eq 0 ]; then
        dialog --title "Continue?" --yesno "Would you like to select some more games?" 7 50
        if [ $? -eq 1 ]; then
            break
        fi
    else
        break
    fi
done

echo "Goodbye!"

# Run the curl command to reload the games
curl http://127.0.0.1:1234/reloadgames

curl -L raw.githubusercontent.com/DTJW92/game-downloader/main/GameDownloader.sh | bash
