#!/bin/bash

# Set the display environment variable
DISPLAY=:0.0

# Define the local path to save GameDownloader.sh
LOCAL_SCRIPT_PATH="/userdata/system/game-downloader/GameDownloader.sh"

# Download the GameDownloader.sh script locally
curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/GameDownloader.sh" -o "$LOCAL_SCRIPT_PATH"

# Make the downloaded script executable
chmod +x "$LOCAL_SCRIPT_PATH"

# Open an xterm window and run the downloaded GameDownloader.sh script
xterm -fs 30 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "
    # Execute the GameDownloader.sh script
    bash '$LOCAL_SCRIPT_PATH'
    
    # After the script finishes, delete the local copy of GameDownloader.sh
    rm -f '$LOCAL_SCRIPT_PATH'
"
