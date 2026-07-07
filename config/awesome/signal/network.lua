-- Provides:
-- signal::network (status, ssid)
-- signal::network_speed (dl_kb_s, ul_kb_s)
local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local helpers = require("helpers")

-- SSID
local update_interval = 30
local network_script = [[
  bash -c "
  iwgetid -r
  "]]

awful.widget.watch(network_script, update_interval, function(_, stdout)
    local net_ssid = stdout
    local net_status = true

    if not net_ssid or net_ssid == "" then
        net_status = false
    end

    net_ssid = net_ssid or ""
    net_ssid = string.gsub(net_ssid, '^%s*(.-)%s*$', '%1')
    awesome.emit_signal("signal::network", net_status, net_ssid)
end)

-- Network speed (download/upload bytes/s)
local speed_script = [[
  bash -c '
  IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '\''{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}'\'')
  if [ -z "$IFACE" ]; then echo "0 0"; exit; fi
  R1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
  T1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
  sleep 1
  R2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
  T2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
  echo "$((R2-R1)) $((T2-T1))"
  ']]

awful.widget.watch(speed_script, 4, function(_, stdout)
    local dl, ul = stdout:match("([%d%.]+)%s+([%d%.]+)")
    dl = tonumber(dl) or 0
    ul = tonumber(ul) or 0
    awesome.emit_signal("signal::network_speed", dl, ul)
end)

