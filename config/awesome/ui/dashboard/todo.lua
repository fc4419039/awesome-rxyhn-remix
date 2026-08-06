local awful = require("awful")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local wibox = require("wibox")
local naughty = require("naughty")
local helpers = require("helpers")

local todo_title = wibox.widget{
  font = beautiful.font_name .. "Medium 8",
  markup = helpers.colorize_text(i18n.tr("dash.tasks"), beautiful.dashboard_box_fg),
  align = "left",
  valign = "center",
  widget = wibox.widget.textbox
}

local todo_done_num = wibox.widget{
  font = beautiful.font_name .. "Bold 20",
  markup = "0",
  align = "center",
  valign = "bottom",
  widget = wibox.widget.textbox
}

local todo_total_num = wibox.widget{
  font = beautiful.font_name .. "8",
  markup = helpers.colorize_text("/0", beautiful.xcolor8),
  align = "center",
  valign = "bottom",
  widget = wibox.widget.textbox
}

local todo_arc = wibox.widget{
  max_value = 1,
  value = 0,
  thickness = dpi(6),
  start_angle = math.pi * 1.5,
  rounded_edge = true,
  bg = beautiful.darker_bg or "#1a1a2e",
  colors = { beautiful.deco_cyan or "#06b6d4" },
  widget = wibox.container.arcchart
}

local todo_label = wibox.widget{
  font = beautiful.font_name .. "7",
  markup = helpers.colorize_text(i18n.tr("dash.tasks_done"), beautiful.xcolor8),
  align = "center",
  valign = "top",
  widget = wibox.widget.textbox
}

local todo = wibox.widget{
  {
    todo_title,
    top = dpi(4),
    left = dpi(2),
    widget = wibox.container.margin
  },
  {
    {
      {
        todo_arc,
        {
          todo_done_num,
          todo_total_num,
          spacing = dpi(0),
          layout = wibox.layout.fixed.vertical
        },
        layout = wibox.layout.stack
      },
      halign = "center",
      valign = "center",
      forced_height = dpi(70),
      widget = wibox.container.place
    },
    todo_label,
    spacing = dpi(2),
    layout = wibox.layout.fixed.vertical
  },
  spacing = dpi(4),
  layout = wibox.layout.fixed.vertical
}

awesome.connect_signal("signal::todo", function(total, done, undone)
  todo_done_num.markup = tostring(done or 0)
  todo_total_num.markup = helpers.colorize_text("/" .. (total or 0), beautiful.xcolor8)

  if total == 0 then
    todo_arc.value = 0
  else
    todo_arc.value = done / total
  end
end)

todo:buttons(gears.table.join(
  awful.button({}, 1, function()
    awful.spawn.easy_async_with_shell("todo list", function(out)
      local text = out:match("^(.*%S.-)%s*$") or i18n.tr("dash.no_tasks")
      if text == "" then text = i18n.tr("dash.no_tasks") end
      naughty.notify({
        title = i18n.tr("dash.tasks_pending_title"),
        text = text,
        timeout = 10,
        width = dpi(400),
      })
    end)
  end),
  awful.button({}, 3, function()
    awful.spawn({terminal, "-e", "bash", "-c", "todo list; echo; read -p '" .. i18n.tr("dash.press_enter_exit") .. "'"})
  end)
))

return todo
