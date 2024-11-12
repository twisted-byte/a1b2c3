# Function to display download status with Dialog
show_download_progress() {
    while true; do
        clear
        progress_text="Downloading:\n"
        any_progress=false
        # Check the status of all downloads
        for status_file in "$STATUS_DIR"/*.status; do
            if [[ -f "$status_file" ]]; then
                file_name=$(basename "$status_file" .status)
                progress=$(<"$status_file")
                decoded_name=$(grep -F "$file_name" "$download_file" | cut -d '|' -f 1)  # Get the decoded name
                progress_text="$progress_text$decoded_name: $progress%\n"
                any_progress=true
            fi
        done

        # If there's ongoing downloads, show progress
        if $any_progress; then
            dialog --clear --title "Download Progress" --msgbox "$progress_text" 15 50
        else
            # Show a message when no downloads are active, with a Cancel button
            dialog --clear --title "Download Progress" --msgbox "Nothing downloading currently!" 10 50
            break
        fi
        sleep 2  # Refresh every 2 seconds
    done

    # Return to GameDownloader.sh when exiting
    bash /userdata/system/game-downloader/GameDownloader.sh
}
