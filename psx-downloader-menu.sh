#!/bin/bash

# File that contains the list of .chd links
LINKS_FILE="/userdata/system/game-downloader/psx-links.txt"
DEST_DIR="/userdata/roms/psx"

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Function to extract clean, decoded game titles from file names
extract_game_titles() {
    local files=("$@")
    declare -A title_to_file_map=()
    for file in "${files[@]}"; do
        # Strip the .chd extension
        title=$(basename "$file" .chd)
        
        # Decode any URL-encoded characters
        title=$(echo "$title" | sed 's/%\([0-9A-Fa-f][0-9A-Fa-f]\)/\\x\1/g' | xargs -0 printf "%b")
        
        # Remove any content inside parentheses, including the parentheses
        title=$(echo "$title" | sed 's/([^)]*)//g')
        
        # Map the cleaned title to the file
        title_to_file_map["$title"]="$file"
    done

    # Sort the titles alphabetically while maintaining the full title per line
    sorted_titles=$(for title in "${!title_to_file_map[@]}"; do echo "$title"; done | sort)
    
    # Return the sorted titles
    echo "$sorted_titles"
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

# Function to refresh the game list with cancellation option
refresh_game_list() {
    dialog --title "Refresh Game List" --yesno "Would you like to refresh the game list?" 7 50
    if [ $? -eq 0 ]; then
        dialog --msgbox "Refreshing game list..." 6 40
        curl http://127.0.0.1:1234/reloadgames  # Reload the games list in Batocera
        dialog --msgbox "Game list refreshed successfully!" 6 40
    else
        dialog --msgbox "Game list refresh cancelled." 6 40
    fi
}

# Main function to display the dialog interface
main() {
    while true; do
        # Read the list of links from psx-links.txt
        files=($(cat "$LINKS_FILE"))
        
        # Extract game titles and map them to files, and sort them alphabetically
        sorted_titles=$(extract_game_titles "${files[@]}")  # This will return sorted titles

        # Prepare array for dialog command, using game titles for display
        dialog_items=()
        while IFS= read -r title; do
            dialog_items+=("$title" "" OFF)  # Use game title only, hide file name
        done <<< "$sorted_titles"

        # Show dialog checklist to select files
        cmd=(dialog --separate-output --checklist "Select games to download" 22 76 16)
        selections=$("${cmd[@]}" "${dialog_items[@]}" 2>&1 >/dev/tty)

        # Check if Cancel was pressed
        if [ $? -eq 1 ]; then
            dialog --msgbox "Download cancelled." 6 30
            refresh_game_list  # Refresh game list before exiting
            exit
        fi

        # If no files are selected, show a message and return to the menu
        if [ -z "$selections" ]; then
            dialog --msgbox "No files selected. Returning t
