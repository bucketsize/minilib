local debug_lua = os.getenv("DEBUG_LUA")
local Logger = {
	sink = function(self, s)
		self.s = s
		if self.h then
			self.h:close()
		end
		self.h = io.open(s, "a")
	end,
	logfn = function(self, ll)
		return function(self, f, ...)
			if not f then
				return
			end
			local l = f or ""
			if ... then
				l = string.format(f, ...)
			end
			if ll == "DEBUG" and not debug_lua then
				return
			end
			if self.h then
				self.h:write(os.date("%Y%m%dT%H%M%S "), ll, " ", l, "\n")
			else
				io.write(os.date("%Y%m%dT%H%M%S "), ll, " ", l, "\n")
			end
		end
	end,
}

Logger.info = Logger:logfn("INFO")
Logger.debug = Logger:logfn("DEBUG")

return {
	create = function()
		local logger = {}
		setmetatable(logger, { __index = Logger })
		return logger
	end,
}
