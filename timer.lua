package.path = '?.lua;' .. package.path
require "luarocks.loader"

local Ut = require("minilib.util")
local So = require("socket")
local logger = require("minilib.logger").create()

local Timer = {
	sleep = So.sleep,
	new_timer = function()
		return {
			t_sleep = 10, -- millis
			t_lapsd = 0,
			fns = {},
			tick = function(self, interval, fn)
				table.insert(self.fns, {fn = fn, i = interval*1000})
			end,
			start = function(self, t_run)
				if t_run then
					t_run = t_run * 1000
				end
				logger.info("new_timer.start")
				while true do
					-- logger.info("new_timer.start, i", self.t_lapsd)
					self.t_lapsd = self.t_lapsd + self.t_sleep
					for k, fd in ipairs(self.fns) do
						if (self.t_lapsd % fd.i) == 0 then
							-- logger.info("new_timer.start", k, fd.i , "@", self.t_lapsd)
							fd.fn()
						end
					end
					if t_run and (not (self.t_lapsd < t_run)) then
						break
					end
					So.sleep(self.t_sleep/1000)
				end
			end
		}
	end
}
return Timer

