#!/bin/bash
# Lanza kitty con split horizontal: ncmpcpp + carátula automática

kitty --session /home/spectre/.config/ncmpcpp/session.conf \
      --class "music" \
      --title "ncmpcpp" \
      --config /home/spectre/.config/ncmpcpp/kitty-music.conf
