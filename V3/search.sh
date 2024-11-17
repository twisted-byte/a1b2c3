#!/bin/bash

# Main directory containing AllGames.txt files in subfolders
main_directory="/userdata/system/game-downloader/links"
output_file="/userdata/system/game-downloader/download.txt"
main_menu_script="/tmp/GameDownloader.sh"

# Ensure the output file exists, create it if it doesn't
if [ ! -f "$output_file" ]; then
    touch "$output_file"
fi

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
                    index=1

                    # Add Return option first
                    menu_items+=("$index" "Return")
                    index=$((index + 1))

                    # Store the lines in an array to maintain their order
                    IFS=$'\n' read -d '' -r -a result_lines <<< "$results"

                    for line in "${result_lines[@]}"; do
                        # Extract file path and game info from AllGames.txt line
                        file_path=$(echo "$line" | awk -F':' '{print $1}')
                        game_info=$(echo "$line" | awk -F':' '{print $3}')

                        # Extract the game name (first part of game_info before the first '|')
                        game_name=$(echo "$game_info" | awk -F'|' '{print $1}')
                        subfolder_name=$(dirname "$file_path" | awk -F'/' '{print $(NF)}')

                        # Clean the game name (remove unwanted characters and spaces)
                        decoded_name_cleaned=$(echo "$game_name" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g')

                        # Combine subfolder and cleaned game name for display purposes
                        display_text="$subfolder_name - $decoded_name_cleaned"
                        menu_items+=("$index" "$display_text")
                        index=$((index + 1))
                    done

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
                        if [ "$selected" -eq "1" ]; then
                            # Return to the search bar menu
                            break
                        elif [ -n "$selected" ]; then
                            # The selected index corresponds to the correct result line in the array
                            result_line=${result_lines[$((selected - 1))]}  # Correct the index by subtracting 1

                            # Clean the entire line (remove backticks, quotes, file path, and line number)
                            cleaned_line=$(echo "$result_line" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g' | sed 's|^[^:]*:[0-9]*:||')

                            # Append the cleaned line to download.txt (without file path or line number)
                            echo "$cleaned_line" >> "$output_file"

                            # Notify the user
                            dialog --title "Success" --ok-label "OK" --msgbox "Added to the download queue:\n\n$decoded_name_cleaned" 10 50
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
            # No Exit message box anymore, just break from the loop
            break
            ;;
    esac
done

# Clean up temporary files
rm -f "$resultfile"

# End the dialog session
clear
