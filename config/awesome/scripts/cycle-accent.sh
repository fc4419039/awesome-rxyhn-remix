#!/bin/bash

idx_file="/tmp/awesome-accent-idx"

palette=(
    "7c3aed"  # purple
    "06b6d4"  # cyan
    "ec4899"  # pink
    "f59e0b"  # amber
    "10b981"  # emerald
    "3b82f6"  # blue
    "ef4444"  # red
    "8b5cf6"  # violet
    "14b8a6"  # teal
    "f97316"  # orange
    "a855f7"  # lighter purple
    "22d3ee"  # lighter cyan
)

darken() {
    local hex=$1
    local factor=$2
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    r=$(printf '%.0f' "$(echo "$r * $factor" | bc -l)")
    g=$(printf '%.0f' "$(echo "$g * $factor" | bc -l)")
    b=$(printf '%.0f' "$(echo "$b * $factor" | bc -l)")
    [ "$r" -gt 255 ] && r=255
    [ "$g" -gt 255 ] && g=255
    [ "$b" -gt 255 ] && b=255
    printf "#%02x%02x%02x" "$r" "$g" "$b"
}

read -r idx 2>/dev/null < "$idx_file"
idx=${idx:- -1}
idx=$(( (idx + 1) % ${#palette[@]} ))
echo "$idx" > "$idx_file"

color="${palette[$idx]}"
accent="#$color"
accent_dim=$(darken "$color" 0.4)

notify-send -t 1500 "Accent" "Switched to <span color='$accent'>■</span> $color"

theme_dir="$HOME/.config/awesome/theme"
rofi_dir="$HOME/.config/rofi"

# Update rofi.rasi
sed -i \
    -e "s/accent:\s*#[0-9a-fA-F]*;/accent:                $accent;/" \
    -e "s/accent-dim:\s*#[0-9a-fA-F]*;/accent-dim:            $accent_dim;/" \
    "$theme_dir/rofi.rasi"

# Update network.rasi
sed -i \
    -e "s/accent:\s*#[0-9a-fA-F]*;/accent:                 $accent;/" \
    -e "s/accent-dim:\s*#[0-9a-fA-F]*;/accent-dim:             $accent_dim;/" \
    "$theme_dir/network.rasi"

# Update bluetooth.rasi
sed -i \
    -e "s/accent:\s*#[0-9a-fA-F]*;/accent:                 $accent;/" \
    "$theme_dir/bluetooth.rasi"

# Update powermenu.rasi
sed -i \
    -e "s/accent:\s*#[0-9a-fA-F]*;/accent:                 $accent;/" \
    "$theme_dir/powermenu.rasi"

# Update wifi-theme.rasi
sed -i \
    -e "s/accent:\s*#[0-9a-fA-F]*;/accent:                 $accent;/" \
    -e "s/accent-dim:\s*#[0-9a-fA-F]*;/accent-dim:             $accent_dim;/" \
    "$rofi_dir/wifi-theme.rasi"

# Update theme.lua borders
sed -i \
    -e "s/theme.border_normal = \"#[0-9a-fA-F]*\"/theme.border_normal = \"$accent\"/" \
    -e "s/theme.border_focus = \"#[0-9a-fA-F]*\"/theme.border_focus = \"$accent\"/" \
    "$theme_dir/theme.lua"

# Reload awesome to apply new borders
awesome-client 'awesome.restart()'
