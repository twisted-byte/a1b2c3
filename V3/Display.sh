#!/bin/bash

# Open an xterm window and run the downloaded GameDownloader.sh script
DISPLAY=:0.0 xterm -fs 30 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "DISPLAY=:0.0 curl -L "https://raw.githubusercontent.com/twisted-byte/a1b2c3/main/V3/MainMenu.sh" | bash"
    
    # Reload the game list
    curl http://127.0.0.1:1234/reloadgames"
