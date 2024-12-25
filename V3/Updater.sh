#!/bin/bash
batocera-services stop Background_Game_Downloader
# Open xterm to run the update process in the background
DISPLAY=:0.0 xterm -fs 30 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "
    # Function to show a dialog spinner
    show_spinner() {
        (
            echo '0'   # Initial value (0%)
            for i in {1..100}; do
                sleep 0.1
                echo \$i   # Update the progress (0-100)
            done
            echo '100'   # End value (100%)
        ) | dialog --title 'Updating...' --gauge 'Please wait while updating...' 10 70 0
    }

    # Start the update process in the background and capture output
    {
        echo 'Starting update process...'
        curl -Ls https://raw.githubusercontent.com/DTJW92/game-downloader/main/V3/install.sh | bash
        echo 'Update process finished.'
    } &

    # Show the spinner while the update process is running
    show_spinner

    # Wait for the background update process to finish
    wait

    # Notify the user when the update is complete
    dialog --infobox 'Update Complete!' 10 50
    sleep 5
"
