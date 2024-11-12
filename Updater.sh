#!/bin/bash

# Open xterm to run the update process
DISPLAY=:0.0 xterm -fs 30 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "
    # Function to show a dialog spinner with custom colors
    show_spinner() {
        (
            echo '0'   # Initial value (0%)
            for i in {1..100}; do
                echo \$i
                sleep 0.1
            done
            echo '100'   # End value (100%)
        ) | dialog --title 'Updating...' --gauge 'Please wait while updating...' 10 70 0 --fg white --bg blue
    }

    # Start the update process in the background
    update_process() {
        curl -Ls https://bit.ly/bgamedownloader | bash > /dev/null 2>&1
    }

    # Start the update process and show spinner simultaneously
    {
        update_process &
        show_spinner
    }

    # Wait for the background update process to finish
    wait

    # Notify user when update is complete with dialog colors
    dialog --msgbox 'Update Complete!' 10 50 --fg green --bg black
"
