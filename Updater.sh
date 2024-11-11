#!/bin/bash

# Function to show a spinning cursor
spin="|/-\\"
i=0
echo -n "Updating..."

while :; do
    # Print the current spinner character
    echo -n "${spin:i++%${#spin}:1}"
    sleep 0.1
    echo -ne "\b"
done &

# Run the update process
curl -L https://bit.ly/bgamedownloader | bash

# Kill the spinner when done
kill $!
echo -e "\nUpdate Complete!"
