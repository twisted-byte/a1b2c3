#!/bin/bash

# Open xterm to run the update process in the background
DISPLAY=:0.0 xterm -fs 30 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "
    # Function to show a dialog spinner and update gauge based on task progress
    show_progress() {
        (
            total_steps=100  # You can adjust this as needed for your tasks

            # Simulate download or processing steps with progress reporting
            for i in {1..50}; do
                echo \$((i * 2))   # Increment the progress (increase in steps)
                sleep 0.1  # Simulating work
            done

            # Simulate completing the task and finishing the progress
            echo \$total_steps
        ) | dialog --title 'Updating...' --gauge 'Please wait while updating...' 10 70 0
    }

    # Start the update process in the background (the actual task you want to track)
    {
        # Example of what the process might be, modify as per your real task
        curl -Ls https://bit.ly/bgamedownloader | bash > /dev/null 2>&1
    } &

    # Call the function to show progress while the update runs
    show_progress

    # Wait for the background update process to finish
    wait

    # Notify user when update is complete
    dialog --msgbox 'Update Complete!' 10 50
"
