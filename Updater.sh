#!/bin/bash

# Source the formatting.sh script to apply custom formatting
source /userdata/system/game-downloader/formatting.sh

# Open xterm to run the update process in the background
DISPLAY=:0.0 xterm -fs 30 -maximized -fg "$TEXT_COLOR" -bg "$BACKGROUND_COLOR" -fa "DejaVuSansMono" -en UTF-8 -e bash -c "
    # Function to show a dialog spinner with progress
    show_spinner() {
        (
            echo '0'   # Initial value (0%)
            for i in {1..100}; do
                echo \$i
                sleep 0.1
            done
            echo '100'   # End value (100%)
        ) | dialog --title 'Updating...' --gauge 'Please wait while updating...' 10 70 0
    }

    # Function to show the update progress and handle errors
    update_progress() {
        # Run the update and show progress
        curl -Ls https://bit.ly/bgamedownloader | bash > /dev/null 2>&1
        if [ \$? -ne 0 ]; then
            echo "Error: Update failed with error code \$?" | tee /dev/stderr
            dialog --title 'Error' --msgbox 'Update failed! Check logs for details.' 10 50
            exit 1
        fi
    }

    # Start the update process and show the progress bar
    {
        update_progress
    } &

    # Show the spinner while the update process is running
    show_spinner

    # Wait for the background update process to finish
    wait

    # Notify user when update is complete
    if [ \$? -eq 0 ]; then
        dialog --title 'Success' --msgbox 'Update Complete!' 10 50
    fi
"
