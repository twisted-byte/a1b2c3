#!/bin/bash

# Pre-determined base directory for searching, set this as needed
BASE_DIR="/userdata/system/game-downloader/links"  # Default to current directory if BASE_DIR is not set
DOWNLOAD_FILE="/userdata/system/game-downloader/download.txt"  # Default to ./download.txt if not set

# Initialize lists to keep track of skipped and added games
skipped_games=()
added_games=()

# Function to clean game names (remove backticks, spaces, and extra characters)
clean_game_name() {
  local decoded_name="$1"
  echo "$decoded_name" | sed 's/[\\\"`]//g' | sed 's/^[[:space:]]*//g' | sed 's/[[:space:]]*$//g'
}

# Function to download the game if it is not already in the queue or downloaded
download_game() {
  local decoded_name="$1"
  local file="$2"
  decoded_name_cleaned=$(clean_game_name "$decoded_name")

  # Extract the destination directory from the .txt file
  destination=$(grep -F "$decoded_name_cleaned" "$file" | cut -d '|' -f 3)

  # Check if the game already exists in the download directory
  if [[ -f "$destination/$decoded_name_cleaned" ]]; then
    skipped_games+=("$decoded_name_cleaned")
    return
  fi

  # Check if the game is already in the download queue (download.txt)
  if grep -q "$decoded_name_cleaned" "$DOWNLOAD_FILE"; then
    skipped_games+=("$decoded_name_cleaned")
    return
  fi

  # Find the game URL from the letter file
  game_url=$(grep -F "$decoded_name_cleaned" "$file" | cut -d '|' -f 2)

  if [ -z "$game_url" ]; then
    dialog --infobox "Error: Could not find download URL for '$decoded_name_cleaned'." 5 40
    sleep 2
    return
  fi

  # Append the decoded name, URL, and folder to the DownloadManager.txt file
  echo "$decoded_name_cleaned|$game_url|$destination" >> "$DOWNLOAD_FILE"
  
  # Collect the added game
  added_games+=("$decoded_name_cleaned")
}

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

# Main script execution
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

    # Loop through selected games and download each one
    for game in "${selected_games_array[@]}"; do
      # Find the file that corresponds to the selected game
      for file in "${game_list[@]}"; do
        if [[ "$file" == *"$game"* ]]; then
          download_game "$game" "$file"
        fi
      done
    done

    # Output the result
    echo "Download list has been updated in $DOWNLOAD_FILE"
    echo "Skipped games: ${skipped_games[@]}"
    echo "Added games: ${added_games[@]}"
    break
  else
    echo "No games selected."
    break
  fi
done
