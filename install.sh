#!/bin/bash

# Function to display animated title for installer
animate_title() {
    local text="GAME DOWNLOADER INSTALLER"
    local delay=0.03
    local length=${#text}

    # Display animated title using dialog
    for (( i=0; i<length; i++ )); do
        echo -n "${text:i:1}"
        sleep $delay
    done
    echo
}

# Function to display controls
display_controls() {
    dialog --title "Controls" --msgbox \
        "This will install the Game Downloader app in Ports." 10 50
}

# Function to install formatting.sh
install_formatting() {
    # Create the /userdata/system/game-downloader directory if it doesn't exist
    mkdir -p /userdata/system/game-downloader

    # Download the formatting.sh script
    curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/formatting.sh" -o /userdata/system/game-downloader/formatting.sh

    # Set execute permissions for formatting.sh
    chmod +x /userdata/system/game-downloader/formatting.sh
}

# Main execution
{
    # Clear the screen and animate the title
    clear
    animate_title

    # Display the controls in a dialog box
    display_controls

    # Ensure necessary directories exist
    mkdir -p /userdata/system/game-downloader
    mkdir -p /userdata/roms/ports

    # Install formatting.sh
    echo "Installing formatting.sh..."
    install_formatting

    # Download and install the GMD.sh script for Ports
    echo "Downloading GMD.sh..."
    curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/GMD.sh" -o /userdata/roms/ports/GMD.sh

    # Download the main GameDownloader script
    echo "Downloading GameDownloader.sh..."
    curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/GameDownloader.sh" -o /userdata/system/game-downloader/GameDownloader.sh

    # Download the scraper and menu scripts for PSX and Dreamcast
    echo "Downloading scraper and menu scripts..."
    curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-scraper.sh" -o /userdata/system/game-downloader/psx-scraper.sh
    curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-scraper.sh" -o /userdata/system/game-downloader/dc-scraper.sh
    curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/psx-downloader-menu.sh" -o /userdata/system/game-downloader/psx-downloader-menu.sh
    curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/dc-downloader-menu.sh" -o /userdata/system/game-downloader/dc-downloader-menu.sh

    # Download the Updater.sh script and rename it to GMD-Updater in the Ports folder
    echo "Downloading GMD-Updater.sh..."
    curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/Updater.sh" -o /userdata/roms/ports/GMD-Updater.sh

    # Download bkeys.txt and rename it to GMD.sh.keys in the Ports folder
    echo "Downloading bkeys.txt..."
    curl -L "https://raw.githubusercontent.com/DTJW92/game-downloader/main/bkeys.txt" -o /userdata/roms/ports/GMD.sh.keys

    # Duplicate bkeys.txt and rename the second file to GMD-Updater.sh.keys in the Ports folder
    echo "Duplicating bkeys.txt and renaming to GMD-Updater.sh.keys..."
    cp /userdata/roms/ports/GMD.sh.keys /userdata/roms/ports/GMD-Updater.sh.keys

    # Set execute permissions for all downloaded scripts
    chmod +x /userdata/roms/ports/GMD.sh
    chmod +x /userdata/system/game-downloader/GameDownloader.sh
    chmod +x /userdata/system/game-downloader/psx-scraper.sh
    chmod +x /userdata/system/game-downloader/dc-scraper.sh
    chmod +x /userdata/system/game-downloader/psx-downloader-menu.sh
    chmod +x /userdata/system/game-downloader/dc-downloader-menu.sh
    chmod +x /userdata/roms/ports/GMD-Updater.sh

    # Run the scraper scripts for PSX and Dreamcast
    echo "Running PSX scraper..."
    /userdata/system/game-downloader/psx-scraper.sh

    echo "Running Dreamcast scraper..."
    /userdata/system/game-downloader/dc-scraper.sh

    # Restart EmulationStation to show the new entry in Ports
    curl http://127.0.0.1:1234/reloadgames

    # Display completion message
    dialog --title "Installation Complete" --msgbox \
        "Installation complete. You should now see 'GMD' and 'GMD-Updater' in Ports." 10 50
} 2>&1 | dialog --title "Installation Progress" --progressbox "Please wait, installation is in progress..." 20 60
