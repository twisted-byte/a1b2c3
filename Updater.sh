#!/bin/bash

# Total duration for the progress bar (in seconds)
total_duration=110  # 1 minute 50 seconds
total_steps=100     # Total number of steps (100% completion)

# Calculate the interval between each progress update
interval=$(($total_duration / $total_steps))  # Interval in seconds

# Open xterm to run the update process in the background and show progress
DISPLAY=:0.0 xterm -fs 30 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "
    # Start the update process in the background (the actual task you want to track)
    {
        # Run the curl command silently in the background
        curl -L https://bit.ly/bgamedownloader > /dev/null 2>&1
    } &

    # Simulate the progress bar while the task is running
    for i in \$(seq 1 $total_steps); do
        # Calculate the progress percentage
        progress=\$((i))

        # Output the progress to update the dialog gauge
        echo \$progress

        # Sleep for the calculated interval time
        sleep $interval
    done

    # Wait for the background update process to finish
    wait

    # Notify user when the update is complete
    dialog --msgbox 'Update Complete!' 10 50
"
