#!/bin/bash

# Main directory containing AllGames.txt files in subfolders
main_directory="/userdata/system/game-downloader/links"
output_file="/userdata/system/game-downloader/download.txt"
main_menu_script="/tmp/GameDownloader.sh"

# Function to perform the search
perform_search() {
    local query=$1
    # Search recursively for the query in AllGames.txt files
    grep -iHn "$query" "$main_directory"/**/AllGames.txt 2>/dev/null
}

# Temporary files
tempfile=$(mktemp)
resultfile=$(mktemp)

while true; do
    # Display the search bar
    dialog --title "Search Bar" --menu "Choose an option:" 15 50 3 \
        1 "Enter Search Query" \
        2 "Return to Main Menu" 2> "$tempfile"

    # Get the user's choice
    choice=$(<"$tempfile")

    # Clean up temporary file
    rm -f "$tempfile"

    case $choice in
        1)
            # Ask for the search query
            dialog --title "Search Query" --inputbox "Enter your search query:" 10 50 2> "$tempfile"
            search_query=$(<"$tempfile")
            rm -f "$tempfile"

            # Check if a query was provided
            if [ -n "$search_query" ]; then
                # Perform the search and capture results
                results=$(perform_search "$search_query")

                if [ -n "$results" ]; then
                    # Create an array of results for the menu
menu_items=()
menu_items+=("$index" "Return")  # Add Return option first
index=$((index + 1))

while IFS= read -r line; do
    # Extract file path and game name
    file_path=$(echo "$line" | awk -F':' '{print $1}')
    game_name=$(echo "$line" | awk -F':' '{print $3}' | awk -F'|' '{print $1}')
    subfolder_name=$(dirname "$file_path" | awk -F'/' '{print $(NF)}')

    # Combine subfolder and game name
    display_text="$subfolder_name - $game_name"
    menu_items+=("$index" "$display_text")
    ((index++))
done <<< "$results"

                    # Add the Return option at the end of the menu
                    menu_items+=("Return" "$index")

                    # Loop to allow repeated selection
                    while true; do
                        # Display results in a menu with an additional Return option
                        dialog --title "Search Results" --menu "Select a result to add to the download queue or return:" 20 70 10 "${menu_items[@]}" 2> "$resultfile"

                        # Get the selected option
                        selected=$(<"$resultfile")

                        # Detect ESC key or cancellation
                        if [ $? -ne 0 ]; then
                            break
                        fi

                        # Process the selection
                        if [ "$selected" -eq "$index" ]; then
                            # Return to the search bar menu
                            break
                        elif [ -n "$selected" ]; then
                            # Retrieve the full line corresponding to the selected option
                            selected_line=$(echo "$results" | sed -n "${selected}p")

                            # Extract the full game name and subfolder
                            file_path=$(echo "$selected_line" | awk -F':' '{print $1}')
                            game_name=$(echo "$selected_line" | awk -F':' '{print $3}' | awk -F'|' '{print $1}')
                            subfolder_name=$(dirname "$file_path" | awk -F'/' '{print $(NF)}')

                            # Combine subfolder and game name for confirmation
                            confirmation_name="$subfolder_name - $game_name"

                            # Append the full line to download.txt
                            echo "$selected_line" >> "$output_file"

                            # Notify the user
                            dialog --title "Success" --ok-label "OK" --msgbox "Added to the download queue:\n\n$confirmation_name" 10 50
                        fi
                    done
                else
                    # No results found
                    dialog --title "No Results" --msgbox "No matches found for '$search_query'." 10 50
                fi
            else
                dialog --title "Error" --msgbox "No search query entered!" 10 50
            fi
            ;;
        2)
            # Execute the main menu script
            clear
            bash "$main_menu_script"
            exit 0
            ;;
        *)
            # Handle ESC or unexpected input
            dialog --title "Exit" --msgbox "Exiting the program..." 10 50
            break
            ;;
    esac
done

# Clean up temporary files
rm -f "$resultfile"

# End the dialog session
clear
