local Logger = {
	sink=function(self, s)
		self.s = s
		if self.h then self.h:close() end
		self.h = io.open(s, "a")
	end,
	info=function(self, f, ...)
		local l = f or ""
		if ... then
			l = string.format(f, ...)
		end
		if self.h then
			self.h
				:write(os.date("%Y%m%dT%H%M%S - INFO - "), l, "\n")
		else
			io
				.write(os.date("%Y%m%dT%H%M%S - INFO - "), l, "\n")
		end
	end
}

return {
	create = function()
		local logger = {}
		setmetatable(logger, {__index = Logger})
		return logger
	end
}
