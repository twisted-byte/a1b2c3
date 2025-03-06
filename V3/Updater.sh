#!/bin/bash
batocera-services stop Background_Game_Downloader > /dev/null 2>&1
# Open xterm to run the update process in the background
DISPLAY=:0.0 xterm -fs 30 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "
    # Function to show a dialog spinner
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

    # Start the update process in the background
    {
        curl -Ls https://raw.githubusercontent.com/twisted-byte/a1b2c3/main/V3/install.sh | bash > /dev/null 2>&1
    } &

    # Show the spinner while the update process is running
    show_spinner

    # Wait for the background update process to finish
    wait

    # Notify user when update is complete
    dialog --infobox 'Update Complete!' 10 50
    sleep 5
"
batocera-services start Background_Game_Downloader &>/dev/null &
exit
