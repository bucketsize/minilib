local Ut = require('minilib.util')
local Sh = require('minilib.shell')
local Sg = require('minilib.sgrid')

local F = {}

function F.new_listener()
	local L = {callback={}}
	function L.listen(user, ps_name, event, fn)
		print("L.listen", user, ps_name, event)
		Sg.put_elem(L.callback, {user, ps_name, event}, fn)
		return L
	end
	function L.start()
        while true do
            local pid = Sh.sh(
                string.format("pgrep %s | head -1", ps_name))
			if not (pid == "") then
				local uid = Ut:strip(Sh.sh(
					string.format("ps -o user= -p %s", pid)))
				print("listener ", pid, uid, "start", ps_name)
				fn = Sg.get_elem(L.callback, {uid, pid, start}) 
				if fn then
					fn()
				end
			end
            Util.sleep(2)
        end
	end
	return L
end

return F
