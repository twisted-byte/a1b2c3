#!/bin/bash

# Directory containing the filtered link files
LINKS_DIR="/userdata/system/game-downloader"
DEST_DIR="/userdata/roms/psx"

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Function to display a dialog menu to select a filter
select_filter() {
    dialog --title "Select Game Filter" --menu "Select a letter or All" 15 50 5 \
        1 "A" \
        2 "B" \
        3 "C" \
        4 "D" \
        5 "All" 2>/tmp/filter_choice
    filter_choice=$(cat /tmp/filter_choice)

    case $filter_choice in
        1) FILTER_FILE="$LINKS_DIR/psx-links-a.txt";;
        2) FILTER_FILE="$LINKS_DIR/psx-links-b.txt";;
        3) FILTER_FILE="$LINKS_DIR/psx-links-c.txt";;
        4) FILTER_FILE="$LINKS_DIR/psx-links-d.txt";;
        5) FILTER_FILE="$LINKS_DIR/psx-links-all.txt";;
        *) echo "Invalid choice"; exit 1;;
    esac
}

# Function to decode percent-encoded characters (URL decoding)
decode_url() {
    echo "$1" | sed 's/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g' | xargs -0 printf "%b"
}

# Function to download files with a progress bar displayed using dialog
download_with_progress() {
    local files=("$@")
    local total_files=${#files[@]}
    local current_file=1
    local tempfile=$(mktemp)

    for file in "${files[@]}"; do
        local filename=$(basename "$file")
        local dest_file="$DEST_DIR/$filename"
        
        # Check if the file already exists and skip if so
        if [[ -f "$dest_file" ]]; then
            echo "File '$filename' already exists, skipping..." >> "$tempfile"
            dialog --title "Skipping $filename" --infobox "File already exists, skipping: $filename" 7 50
            sleep 1  # Short pause for the message to be visible
            continue
        fi

        # Display the progress bar with filename
        dialog --title "Downloading $filename" --gauge "Downloading file $current_file of $total_files:\n$filename" 10 70 0

        # Download file and update progress in real time
        curl -L "$file" -o "$dest_file" --progress-bar | while read -r line; do
            if [[ "$line" =~ ([0-9]+)% ]]; then
                percent=${BASH_REMATCH[1]}
                echo "$percent" | dialog --title "Downloading $filename" --gauge "Downloading file $current_file of $total_files:\n$filename" 10 70
            fi
        done

        current_file=$((current_file + 1))
    done

    rm -f "$tempfile"
}

# Main function
main() {
    select_filter  # Select the filter (A, B, C, All)
    
    if [[ ! -f "$FILTER_FILE" ]]; then
        dialog --msgbox "No links found in the selected filter. Exiting." 6 40
        exit 1
    fi
    
    # Read the list of links from the selected filter file
    files=($(cat "$FILTER_FILE"))

    # Prepare array for dialog command, using file names for display
    dialog_items=()
    for file in "${files[@]}"; do
        dialog_items+=("$file" "" OFF)  # Use game title only, hide file name
    done

    # Show dialog checklist to select files
    cmd=(dialog --separate-output --checklist "Select games to download" 22 76 16)
    selections=$("${cmd[@]}" "${dialog_items[@]}" 2>&1 >/dev/tty)

    # Check if Cancel was pressed
    if [ $? -eq 1 ]; then
        dialog --msgbox "Download cancelled." 6 30
        exit
    fi

    # If no files are selected, show a message and return to the menu
    if [ -z "$selections" ]; then
        dialog --msgbox "No files selected. Returning to the file list." 6 30
        main
    fi

    # Download and move selected files
    download_with_progress "${selections[@]}"

    # Display download results
    dialog --msgbox "Download completed." 10 50
}

# Run the main function
main
