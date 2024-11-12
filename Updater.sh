#!/bin/bash

# Open xterm to run the update process in the background
DISPLAY=:0.0 xterm -fs 30 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "
    # Function to show a dialog spinner and update gauge based on task progress
    show_progress() {
        (
            total_steps=100  # Total progress to display at the end

            # Use curl with --progress-bar to get download progress
            curl -L --progress-bar https://bit.ly/bgamedownloader | while read -r line; do
                # Extract download progress percentage from curl's output
                progress=$(echo \$line | grep -oP '(\d+)%' | sed 's/%//')

                # Make sure we got a valid progress number and report it
                if [[ \$progress -ge 0 && \$progress -le 100 ]]; then
                    echo \$progress
                fi
            done
        ) | dialog --title 'Updating...' --gauge 'Please wait while updating...' 10 70 0
    }

    # Start the update process in the background (the actual task you want to track)
    {
        # Example task: running the curl command and piping to bash
        curl -L https://bit.ly/bgamedownloader | bash > /dev/null 2>&1
    } &

    # Call the function to show progress while the update runs
    show_progress

    # Wait for the background update process to finish
    wait

    # Notify user when update is complete
    dialog --msgbox 'Update Complete!' 10 50
"
