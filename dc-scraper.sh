#!/bin/bash

# Dreamcast scraper for gathering .chd download links
BASE_URL="https://myrient.erista.me/files/Internet%20Archive/chadmaster/dc-chd-zstd-redump/dc-chd-zstd/"
OUTPUT_FILE="/userdata/system/game-downloader/dc-links.txt"

# Fetch the page content
page_content=$(curl -s "$BASE_URL")

# Parse the .chd links and save to output file with descriptions
echo "$page_content" | grep -oP '(?<=href=")[^"]*\.chd' | while read -r file_name; do
    # Decode the file name and remove text within parentheses
    description=$(basename "$file_name" | sed -e 's/%20/ /g' -e 's/([^)]*)//g' -e 's/\.chd$//')
    echo "$description $BASE_URL$file_name" >> "$OUTPUT_FILE"
done

echo "Dreamcast game links have been saved to $OUTPUT_FILE."
