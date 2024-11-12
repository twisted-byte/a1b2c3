#!/bin/bash

# Open xterm to run the update process
DISPLAY=:0.0 xterm -fs 30 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "
    # Function to show a dialog spinner without colors
    show_spinner() {
        (
            echo '0'   # Initial value (0%)
            for i in {1..100}; do
                echo \$i
                sleep 1.1
            done
            echo '100'   # End value (100%)
        ) | dialog --colors --title '\Zb\Z6Updating...' --gauge '\Z5Please wait while updating...' 10 70 0

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

    # Notify user when update is complete without colors
    dialog --msgbox 'Update Complete!' 10 50
"
