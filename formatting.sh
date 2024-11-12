#!/bin/bash

# Set dialog color scheme
export DIALOGRC="/userdata/system/game-downloader/dialogrc"

# Set the dialog background color to black, box color to dark gray, and text to turquoise
cat <<EOF > "$DIALOGRC"
# Color Definitions for Dialog
background=black
foreground=turquoise
border=darkgray
highlight=cyan
dialogbox=darkgray
textbox=darkgray
menu=cyan
infobox=cyan
gauge=cyan
EOF

# Make sure dialog uses this config
export DIALOGRC
