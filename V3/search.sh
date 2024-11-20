#!/bin/bash

# Pre-determined base directory for searching, set this as needed
BASE_DIR="/userdata/system/game-downloader/links"  # Default to current directory if BASE_DIR is not set

# Predetermined location for download.txt, default is "download.txt" in the current directory
DOWNLOAD_FILE="/userdata/system/game-downloader/download.txt"  # Default to ./download.txt if not set

# Function to search for game entries in .txt files and clean the game names
search_games() {
  local search_dir="$1"
  local file_pattern="*.txt"  # We are still looking for *.txt files
  game_list=()

  # Find all .txt files in the directory and its subdirectories
  find "$search_dir" -type f -name "$file_pattern" | while read -r file; do
    # Read each line of the .txt file
    while IFS= read -r line; do
      # Use regex to extract the game name and clean it by removing backticks
      if [[ "$line" =~ \`([^\\`]+)\`\|([^|]+)\|([^|]+) ]]; then
        game_name="${BASH_REMATCH[1]}" 
        url="${BASH_REMATCH[2]}"
        destination="${BASH_REMATCH[3]}"

        # If a search term is provided, only add games that match the search term
        if [[ -z "$search_term" || "$game_name" =~ $search_term ]]; then
          game_list+=("$game_name|$url|$destination" "$file")
        fi
      fi
    done < "$file"
  done
}

# Function to send selected games to the download process, with extension splitting
download_games() {
  local selected_games=("$@")

  for game in "${selected_games[@]}"; do
    # Now, split the game into its constituent game files based on .chd, .iso, .zip extensions.
    # This will find all extensions and handle them individually while keeping game name intact.
    IFS=$'\n' read -r -d '' -a game_files <<< "$(echo "$game" | grep -oP '.*\.(chd|iso|zip)')"

    # For each split game file, search the file containing the game entry
    for game_file in "${game_files[@]}"; do
      # Search for the exact line in the original file that matches the game file name
      for file in "${game_list[@]}"; do
        if [[ "$file" == *"$game_file"* ]]; then
          # Extract the exact line from the file that matches the game name
          # Format: cleaned game name|download url|destination path
          line=$(grep -F "\`$game_file\`" "$file")
          
          # Clean the line by removing backticks and reformat it
          cleaned_game_name=$(echo "$line" | sed -E 's/`([^`]+)`/\1/')
          echo "$cleaned_game_name" >> "$DOWNLOAD_FILE"
        fi
      done
    done
  done
}

# Main script execution
# If BASE_DIR is not set, it will default to the current directory.
echo "Using base directory: $BASE_DIR"
echo "Saving download list to: $DOWNLOAD_FILE"
game_list=()

# Ask the user for a search term
while true; do
  # Prompt the user for a search term
  search_term=$(dialog --inputbox "Enter search term" 10 50 3>&1 1>&2 2>&3)

  # If the user cancels or enters an empty search term, exit or break out of the loop
  [[ -z "$search_term" ]] && break
  
  # Search for games and create the game list based on the search term
  search_games "$BASE_DIR" "$search_term"
  
  # Use dialog to display a checklist of game names
  selected_games=$(dialog --checklist "Select games to download" 0 0 10 "${game_list[@]}" 2>&1 >/dev/tty)

  # Check if any games were selected
  if [ -n "$selected_games" ]; then
    # Since the games contain spaces, we'll split the selected games based on the extensions only
    IFS=$'\n' read -r -d '' -a selected_games_array <<< "$(echo "$selected_games" | grep -oP '.*\.(chd|iso|zip)')"

    # Call the function to download games and split by extensions
    download_games "${selected_games_array[@]}"
    echo "Download list has been updated in $DOWNLOAD_FILE"
    break
  else
    echo "No games selected."
    break
  fi
done
