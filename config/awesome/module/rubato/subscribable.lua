-- Kidna copying awesotre's stores on a surface level for added compatibility
-- Unique ID counter for functions (works across all Lua versions)
local _func_id_counter = 0
local _func_id_map = setmetatable({}, { __mode = "k" })

local function subscribable(base)
	local obj = base or {}
	
	obj._subscribed = {}

	-- Generate unique ID for a function (compatible with Lua 5.1/5.2/5.3/5.4/LuaJIT)
	local function get_func_id(func)
		-- Use cached ID if function was already registered
		if _func_id_map[func] then
			return _func_id_map[func]
		end
		-- Generate new unique ID
		_func_id_counter = _func_id_counter + 1
		local id = tostring(_func_id_counter)
		_func_id_map[func] = id
		return id
	end

	-- Subscrubes a function to the object so that it's called when `fire` is
	-- Calls subscribe_callback if it exists as well
	function obj:subscribe(func)
		local id = get_func_id(func)
		self._subscribed[id] = func

		if self.subscribe_callback then self.subscribe_callback(func) end
	end

	-- Unsubscribes a function and calls unsubscribe_callback if it exists
	function obj:unsubscribe(func)
		if not func then
			self._subscribed = {}
		else
			local id = get_func_id(func)
			self._subscribed[id] = nil
		end

		if self.unsubscribe_callback then self.unsubscribe_callback(func) end
	end

	function obj:fire(...) for _, func in pairs(self._subscribed) do func(...) end end

	return obj
end

return subscribable
