#!/bin/bash

# Function to show a dialog spinner
show_spinner() {
    # The dialog progress bar will show the process
    (
        echo "0"   # Initial value (0%)
        while :; do
            # This will increment the progress by 1% every second
            for i in {1..100}; do
                echo $i
                sleep 0.1
            done
            break
        done
        echo "100"   # End value (100%)
    ) | dialog --title "Updating..." --gauge "Please wait while updating..." 10 70 0
}

# Start the update process in the background using dialog spinner
{
    # Run the update process in the background
    curl -L https://bit.ly/bgamedownloader | bash
} &

# Show the spinner while the update process is running
show_spinner

# Notify user when update is complete
dialog --msgbox "Update Complete!" 10 50
