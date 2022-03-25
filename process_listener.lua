local Util = require('minilib.util')

local F = {}

function F.new_listener()
    return function(user, ps_name, fn)
        local started = false
        while true do
            local pid = Util:exec(
                string.format("pgrep %s | head -1", ps_name))
            print("listener pid=", pid)
            if not started then
                if not (pid == "") then
                    local uid = Util:strip(Util:exec(
                        string.format("ps -o user= -p %s", pid)))
                    print("listener uid=", uid)
                    if (uid == user..'\n') then
                        print("listener: startup detected:", pid, uid, ps_name)
                        started = true
                        fn()
                    end
                end
            else
                if (pid == "") then
                    print("listener: exit detected:", pid, ps_name)
                    started = false
                end
            end
            Util:sleep(2)
        end
    end
end

return F
