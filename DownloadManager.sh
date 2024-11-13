#!/bin/bash

# Path to the progress file
PROGRESS_FILE="/userdata/system/game-downloader/progress.txt"
mkdir -p "$(dirname "$PROGRESS_FILE")"

# Function to display download status with Dialog (non-blocking)
show_download_progress() {
    while true; do
        progress_text="Downloading:\n"
        any_progress=false

        # Check the progress file for all downloads
        if [[ -f "$PROGRESS_FILE" ]]; then
            while IFS='|' read -r game_name progress; do
                if [[ -n "$game_name" && -n "$progress" ]]; then
                    progress_text="$progress_text$game_name: $progress%\n"
                    any_progress=true
                fi
            done < "$PROGRESS_FILE"
        fi

        # If there's ongoing downloads, show progress
        if $any_progress; then
            # Use dialog --gauge for a progress bar
            dialog --title "Download Progress" --gauge "$progress_text" 15 50 0
        else
            # Show a message when no downloads are active
            dialog --clear --title "Download Progress" --msgbox "Nothing downloading currently!" 10 50
            break
        fi

        # Exit when the dialog is closed
        if [[ $? -eq 0 ]]; then
            break
        fi

        sleep 2  # Refresh every 2 seconds
    done
}

# Start showing download progress in the background
show_download_progress &

# Main menu or other logic here
# You can now show the main menu, and the download progress will continue updating in the background
echo "You can return to the main menu while the downloads continue in the background."