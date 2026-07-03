-- Provides:
-- signal::network
--      status (boolean)
--      ssid (string)
local awful = require("awful")

local update_interval = 30
local network_script = [[
  bash -c "
  iwgetid -r
  "]]

-- Periodically get cpu info
awful.widget.watch(network_script, update_interval, function(_, stdout)
    -- local network = stdout:match('+(.*)%.%d...(.*)%(')
    local net_ssid = stdout
    local net_status = true

    if not net_ssid or net_ssid == "" then
        net_status = false
    end

    net_ssid = net_ssid or ""
    net_ssid = string.gsub(net_ssid, '^%s*(.-)%s*$', '%1')
    awesome.emit_signal("signal::network", net_status, net_ssid)
end)

