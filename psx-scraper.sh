#!/bin/bash

BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/chd_psx_eur/CHD-PSX-EUR/"
DEST_DIR="/userdata/system/game-downloader/psxlinks"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Download the HTML content from the base URL
HTML_CONTENT=$(curl -s "$BASE_URL")

# Extract all .chd links from the HTML content using grep and regex
CHD_FILES=$(echo "$HTML_CONTENT" | grep -oP 'href="([^"]+\.chd)"' | sed 's/href="//g' | sed 's/"//g')

# Iterate over each CHD file link
for FILE in $CHD_FILES; do
    # Extract the first letter of the filename (lowercase)
    FIRST_LETTER=$(echo "$FILE" | cut -c1 | tr '[:upper:]' '[:lower:]')

    # Create a text file named after the first letter if it doesn't exist
    TEXT_FILE="$DEST_DIR/${FIRST_LETTER}.txt"
    touch "$TEXT_FILE"

    # Append the full CHD file URL to the corresponding text file
    echo "$BASE_URL$FILE" >> "$TEXT_FILE"
done

echo "CHD files have been organized successfully."
