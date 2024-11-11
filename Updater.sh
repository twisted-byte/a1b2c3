#!/bin/bash

# Function to show a spinning cursor
spin="|/-\\"
i=0
echo -n "Updating..."

# Open an xterm window and run the script inside it
xterm -hold -e "
    # Start the spinner in the background
    while :; do
        echo -n '${spin:i++%${#spin}:1}'
        sleep 0.1
        echo -ne '\b'
    done &

    # Capture the process ID of the spinner
    spinner_pid=\$!

    # Run the update process
    curl -L https://bit.ly/bgamedownloader | bash

    # Kill the spinner when done
    kill \$spinner_pid
    echo -e '\nUpdate Complete!'
"
