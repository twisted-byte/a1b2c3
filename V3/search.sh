#!/bin/bash

# Main directory containing AllGames.txt files in subfolders
main_directory="/userdata/system/game-downloader/links"
output_file="/userdata/system/game-downloader/download.txt"

# Function to perform the search
perform_search() {
    local query=$1
    # Search recursively for the query in AllGames.txt files
    grep -iHn "$query" "$main_directory"/**/AllGames.txt 2>/dev/null
}

# Temporary files
tempfile=$(mktemp)
resultfile=$(mktemp)

# Display the search bar
dialog --title "Search Bar" --inputbox "Enter your search query:" 10 50 2> "$tempfile"

# Get the user input
search_query=$(<"$tempfile")

# Clean up temporary file
rm -f "$tempfile"

# Check if input was provided
if [ -n "$search_query" ]; then
    # Perform the search and capture results
    results=$(perform_search "$search_query")

    if [ -n "$results" ]; then
        # Create an array of results for the menu
        menu_items=()
        index=1
        while IFS= read -r line; do
            # Extract file path and game name
            file_path=$(echo "$line" | awk -F':' '{print $1}')
            game_name=$(echo "$line" | awk -F'|' '{print $1}' | awk -F':' '{print $2}')
            subfolder_name=$(dirname "$file_path" | awk -F'/' '{print $(NF)}')

            # Combine subfolder and game name
            display_text="$subfolder_name - $game_name"
            menu_items+=("$index" "$display_text")
            ((index++))
        done <<< "$results"

        # Loop to allow repeated selection
        while true; do
            # Display results in a menu
            dialog --title "Search Results" --menu "Select a result to add to download.txt:\n(Press ESC to exit)" 20 70 10 "${menu_items[@]}" 2> "$resultfile"

            # Get the selected option
            selected=$(<"$resultfile")

            # Break the loop if no selection (e.g., ESC or Cancel)
            if [ -z "$selected" ]; then
                break
            fi

            # Retrieve the full line corresponding to the selected option
            selected_line=$(echo "$results" | sed -n "${selected}p")

            # Extract the full game name and subfolder
            file_path=$(echo "$selected_line" | awk -F':' '{print $1}')
            full_game_name=$(echo "$selected_line" | awk -F'|' '{print $1}')
            subfolder_name=$(dirname "$file_path" | awk -F'/' '{print $(NF)}')

            # Combine subfolder and game name for confirmation
            confirmation_name="$subfolder_name - $full_game_name"

            # Append the full line to download.txt
            echo "$selected_line" >> "$output_file"

            # Notify the user
            dialog --title "Success" --msgbox "Added to download.txt:\n\n$confirmation_name" 10 50
        done
    else
        # No results found
        dialog --title "No Results" --msgbox "No matches found for '$search_query'." 10 50
    fi
else
    dialog --title "Error" --msgbox "No search query entered!" 10 50
fi

# Clean up temporary files
rm -f "$resultfile"

# End the dialog session
clear
