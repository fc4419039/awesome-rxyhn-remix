#!/usr/bin/env bash
# Monitor sink-inputs and route notification-type streams to the 'notifications' sink
# and non-notification streams out of the 'notifications' sink back to system_sink.
# This ensures each stream always lands on the correct sink, even if module-stream-restore
# or similar tools try to restore a wrong route.
set -e

NOTIF_SINK_NAME="notifications"
SYSTEM_SINK_NAME="system_sink"
NOTIF_SINK_ID=$(pactl list sinks short 2>/dev/null | awk -v name="$NOTIF_SINK_NAME" '$2 == name {print $1}')
SYSTEM_SINK_ID=$(pactl list sinks short 2>/dev/null | awk -v name="$SYSTEM_SINK_NAME" '$2 == name {print $1}')

if [ -z "$NOTIF_SINK_ID" ] || [ -z "$SYSTEM_SINK_ID" ]; then
  echo "ERROR: notifications or system_sink not found — run notif-sink-setup.sh first" >&2
  exit 1
fi

is_notification_stream() {
  local props="$1"
  local role app mname

  role=$(echo "$props" | awk -F'"' '/media.role/ {print tolower($2); exit}')
  app=$(echo "$props" | awk -F'"' '/application.name/ {print tolower($2); exit}')
  mname=$(echo "$props" | awk -F'"' '/media.name/ {print tolower($2); exit}')

  [ -z "$role" ] && [ -z "$app" ] && [ -z "$mname" ] && return 1

  echo "$role" | grep -qE "notification|event|alarm|alert|x-event|x-notification|system-sound" && return 0
  echo "$app" | grep -qE "paplay|libcanberra|notification|notify|canberra|speech-dispatcher" && return 0
  echo "$mname" | grep -qE "notification|event|audio-volume-change|bell|dialog|message|alert" && return 0

  return 1
}

move_route() {
  pactl list sink-inputs 2>/dev/null | awk -v notif_sink="$NOTIF_SINK_ID" -v sys_sink="$SYSTEM_SINK_ID" '
    BEGIN { block = ""; id = ""; in_block = 0 }

    /^Sink Input #[0-9]+/ {
      if (in_block && id != "") process_block()
      id = $0; sub(/^Sink Input #/, "", id); sub(/:$/, "", id); gsub(/[ \t]/, "", id)
      block = $0 "\n"
      in_block = 1
      next
    }

    in_block { block = block $0 "\n"; next }

    END { if (in_block && id != "") process_block() }

    function process_block() {
      sink = ""; role = ""; app = ""; mname = ""; owner = ""
      n = split(block, lines, "\n")
      for (i = 1; i <= n; i++) {
        line = lines[i]
        if (line ~ /^[ \t]*Sink: /)           { gsub(/.*Sink: /, "", line); sink = line }
        if (line ~ /^[ \t]*Owner Module: /)   { gsub(/.*Owner Module: /, "", line); owner = line }
        if (line ~ /media.role/)               { gsub(/.*media.role[ \t]*=[ \t]*"/, "", line); gsub(/".*$/, "", line); role = tolower(line) }
        if (line ~ /application.name/)         { gsub(/.*application.name[ \t]*=[ \t]*"/, "", line); gsub(/".*$/, "", line); app = tolower(line) }
        if (line ~ /media.name/)               { gsub(/.*media.name[ \t]*=[ \t]*"/, "", line); gsub(/".*$/, "", line); mname = tolower(line) }
      }
      # Skip module-created streams (loopbacks)
      if (owner ~ /^[0-9]+$/) return
      is_notif = 0
      if (role ~ /notification|event|alarm|alert|x-event|x-notification|system-sound/) is_notif = 1
      if (app ~ /paplay|libcanberra|notification|notify|canberra|speech-dispatcher/) is_notif = 1
      if (mname ~ /notification|event|audio-volume-change|bell|dialog|message|alert/) is_notif = 1
      # Route notification streams TO notifications sink
      if (is_notif && sink != notif_sink)
        system("pactl move-sink-input " id " " notif_sink " 2>/dev/null")
      # Route non-notification streams FROM notifications sink TO system_sink
      if (!is_notif && sink == notif_sink)
        system("pactl move-sink-input " id " " sys_sink " 2>/dev/null")
    }
  '
}

# Route existing streams at startup
move_route

# Subscribe to new sink-inputs and react immediately
pactl subscribe 2>/dev/null | grep --line-buffered "on sink-input" | while read -r line; do
  id=$(echo "$line" | sed -n 's/.*#\([0-9]*\).*/\1/p')
  [ -z "$id" ] && continue

  props=$(pactl list sink-inputs 2>/dev/null | awk -v id="$id" '
    BEGIN { found = 0 }
    /^Sink Input #/ {
      s = $0; sub(/^Sink Input #/, "", s); sub(/:$/, "", s); gsub(/[ \t]/, "", s)
      found = (s == id)
      if (found) { block = $0 "\n"; next }
    }
    found { block = block $0 "\n" }
    END { if (found) print block }
  ')

  sink=$(echo "$props" | awk '/^[ \t]*Sink: / {gsub(/.*Sink: /, "", $0); print $0; exit}')
  owner=$(echo "$props" | awk '/^[ \t]*Owner Module: / {gsub(/.*Owner Module: /, "", $0); print $0; exit}')

  # Skip module-created streams (loopbacks)
  echo "$owner" | grep -qE '^[0-9]+$' && continue

  if [ "$sink" != "$NOTIF_SINK_ID" ] && is_notification_stream "$props"; then
    pactl move-sink-input "$id" "$NOTIF_SINK_NAME" 2>/dev/null
  elif [ "$sink" = "$NOTIF_SINK_ID" ] && ! is_notification_stream "$props"; then
    pactl move-sink-input "$id" "$SYSTEM_SINK_NAME" 2>/dev/null
  fi
done
