local Ut = require('minilib.util')
local Sh = require('minilib.shell')

local F = {}


function F.new_listener()
	local L = {callback={}}
	function L.listen(user, ps_name, event, fn)
		put_elem(L.callback, {user, ps_name, event}, fn)
	end
	function L.start()
        while true do
            local pid = Sh.sh(
                string.format("pgrep %s | head -1", ps_name))
			if not (pid == "") then
				local uid = Util:strip(Util:sh(
					string.format("ps -o user= -p %s", pid)))
				print("listener ", pid, uid, "start", ps_name)
				fn = get_elem(L.callback, {uid, pid, start}) 
				if fn then
					fn()
				end
			end
            Util:sleep(2)
        end
	end
end

return F
