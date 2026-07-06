#!/bin/bash
# Lanza kitty con split horizontal: ncmpcpp + carátula automática

kitty --session "$HOME/.config/ncmpcpp/session.conf" \
      --class "music" \
      --title "ncmpcpp" \
      --config "$HOME/.config/ncmpcpp/kitty-music.conf"
