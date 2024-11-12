#!/bin/bash

# Open xterm to run the update process
DISPLAY=:0.0 xterm -fs 30 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "

    # Define the log file path
    LOG_FILE='/userdata/system/game-downloader/debug-updater.txt'

    # Function to show a dialog spinner with colors enabled
    show_spinner() {
        (
            echo '0'   # Initial value (0%)
            for i in {1..100}; do
                echo \$i
                sleep 1.1
            done
            echo '100'   # End value (100%)
        ) | dialog --title 'Updating...' --gauge 'Please wait while updating...' 10 70 0
    }

    # Start the update process in the background
    update_process() {
        echo "$(date) - Starting update process" | tee -a $LOG_FILE
        curl -Ls https://bit.ly/bgamedownloader | bash 2>&1 | tee -a $LOG_FILE
        echo "$(date) - Update process finished" | tee -a $LOG_FILE
    }

    # Start the update process and show spinner simultaneously
    {
        update_process &  # Run update in background
        show_spinner      # Show spinner
    }

    # Wait for the background update process to finish
    wait

    # Notify user when update is complete without colors
    dialog --msgbox 'Update Complete!' 10 50

    # Reset terminal colors after dialog
    echo -e '\e[0m'

" 2>&1 | tee -a /userdata/system/game-downloader/debug-updater.txt
