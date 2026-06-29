#!/bin/sh

# Open ncmpcpp with album art in a split kitty window

# Create a new window
kitty @ new-window
kitty @ focus-window

# Launch ncmpcpp in current pane
kitty @ send-text "ncmpcpp\n"
sleep 0.5

# Create horizontal split on right
kitty @ launch --location=hsplit --borders=none "$HOME/.config/awesome/scripts/album_art.sh"
