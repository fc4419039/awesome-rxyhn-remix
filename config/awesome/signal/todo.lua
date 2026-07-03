-- Provides:
-- signal::todo
--      total (integer)
--      done (integer)
--      undone (integer)
local awful = require("awful")

-- 🌟 LA MAGIA: Lua obtiene dinámicamente la ruta HOME del usuario actual
local user_home = os.getenv("HOME")
local todo_file_path = user_home .. "/.todo"

-- Subscribe to todo changes
-- Requires inotify-tools
local todo_subscribe_script = [[
   bash -c "
   while inotifywait -e modify ]] .. todo_file_path .. [[ -qq; do
       echo 'update'
   done
"
]]

local todo_script = [[
   bash -c "
   touch ]] .. todo_file_path .. [[

   todo_done=$(todo raw done | wc -l)
   todo_undone=$(todo raw todo | wc -l)

   echo \"$todo_done\"@@\"$todo_undone\"
"
]]

local emit_todo_info = function()
   awful.spawn.with_line_callback(todo_script, {
       stdout = function(line)
           local done_match, undone_match = line:match('(.*)@@(.*)')
           if done_match and undone_match then
               local done = tonumber(done_match) or 0
               local undone = tonumber(undone_match) or 0
               local total = undone + done
               awesome.emit_signal("signal::todo", total, done, undone)
           end
       end
   })
end

-- Run once to initialize widgets
emit_todo_info()

-- Kill old inotifywait process de forma limpia usando pkill (así evitas el grep/awk que gasta CPU)
awful.spawn.easy_async_with_shell("pkill -f 'inotifywait -e modify " .. todo_file_path .. "'", function ()
   -- Update todo status with each line printed
   awful.spawn.with_line_callback(todo_subscribe_script, {
       stdout = function(_)
           emit_todo_info()
       end
   })
end)
