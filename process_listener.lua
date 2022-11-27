local Ut = require('minilib.util')
local Sh = require('minilib.shell')
local Sg = require('minilib.sgrid')
local Pr = require('minilib.process')

local F = {}

function F.new_listener()
	local L = {callback={}, ob_list={}}
	function L.listen(user, ps_name, event, fn)
		logger.info("L.listen, %s %s %s", user, ps_name, event)
		Sg.put_elem(L.callback, {user, ps_name, event}, fn)
		table.insert(L.ob_list, {user, ps_name, event})
		return L
	end
	function L.trigger(x, event)
		local fn = Sg.get_elem(L.callback, {x[1], x[2], event}) 
		if fn then
			fn()
		else
			logger.info("L.trigger, fn missing, %s %s %s", x[1], x[2], event)
		end
	end
	function L.start()
        while true do
			local curr = {}
			Pr.pipe()
				.add(Sh.exec("ps -eo user,comm"))
				.add(Sh.grep("(%w+)%s+(%w+)"))
				.add(function(x)
					if not x then return nil end
					Sg.put_elem(curr, {x[1], x[2], "status"}, "running")
					return x
				end)
				.add(Pr.filter(function(x)
					if not x then return nil end
					for _,v in ipairs(L.ob_list) do
						if x[1] == v[1] and x[2] == v[2] then
							return true
						end
					end
				end))
				.add(function(x)
					if not x then return nil end
					local status = L.callback[x[1]][x[2]]["status"]
					--logger.info("cs>", status)
					if status == nil or status ~= "started" then
						L.trigger(x, "start")
						L.callback[x[1]][x[2]]["status"] = "started"
						logger.info("start %s %s %s started",x[1], x[2], status)
					end
				end)
				.run()

			for _,v in ipairs(L.ob_list) do
				local status = L.callback[v[1]][v[2]]["status"]
				-- logger.info("os>", status)
				if status ~= nil and status == "started" and curr[v[1]][v[2]] == nil then
					L.trigger(v, "exit")
					L.callback[v[1]][v[2]]["status"] = "exited"
					logger.info("start %s %s %s exited", v[1], v[2], status)
				end
			end

            Ut.sleep(2)
        end
	end
	return L
end

return F
