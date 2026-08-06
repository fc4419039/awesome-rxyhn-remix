local awful = require("awful")

local user_home = os.getenv("HOME")
local todo_file_path = user_home .. "/.todo"
local todo_dir = user_home

-- Watch the directory for changes to .todo (sed -i creates a new inode)
local todo_subscribe_script = [[
   bash -c "
   while inotifywait -e modify -e close_write -e moved_to -e create -qq ]] .. todo_dir .. [[ --include '\.todo$'; do
        sleep 0.2
        echo 'update'
    done
"
]]

local todo_script = [[
   bash -c "
    todo_done=$(grep -c '^\[\*\]' ]] .. todo_file_path .. [[ 2>/dev/null || echo 0)
    todo_undone=$(grep -c '^\[ \]' ]] .. todo_file_path .. [[ 2>/dev/null || echo 0)
    echo \"\${todo_done}@@\${todo_undone}\"
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

emit_todo_info()

awful.spawn.easy_async_with_shell("pkill -f 'inotifywait.*todo'", function()
   awful.spawn.with_line_callback(todo_subscribe_script, {
       stdout = function(_)
           emit_todo_info()
       end
   })
end)
