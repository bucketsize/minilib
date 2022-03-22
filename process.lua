local Util = require('minilib.util')

local F = {}

function F.pipe()
	local fn = {}
	local t = 1
	local p = {}
    local e = {}
	function p.add(f)
		fn[t] = f
        e[t] = false
		t = t + 1
		return p
	end
	function p.run(trace)
		local a, s = nil, nil
        local ended = false
		while not ended do
            ended = true
			for i = 1, t-1 do
                local a0 = a
                a = fn[i](a)
                if a == nil then
                    e[i] = true
                else
                    ended = false
                end
                if trace then
                    print("fn_"..tostring(i)
                        ,a0, "->", a, e[i])
                end
			end
			if not (a==nil) then
				s = a
			end
            if ended then
                break
            end
		end
		return s
	end
	return p
end

function F.branch()
	local fn = {}
	local t = 1
	local p = {}
	function p.add(f)
		fn[t] = f
		t = t + 1
		return p
	end
	function p.build()
		return function(r)
			local out, ended = {}, true
			for i = 1, t-1 do
				out[i] = fn[i](r)
                if out[i] then
                    ended = false
                end
			end
            if ended then
                return nil
            else
    			return out
            end
		end
	end
	return p
end

function F.bget(l)
	print(l)
	local r = {}
	local i = 1
	return function(x)
		while true do
			local s = l[i]
			if s == nil then break end
			if not (r == nil) then
				r[i] = s
			end
			i = i + 1
		end
		return r
	end
end

function F.cull()
	local fn = function(lout)
		local ok = false
		for k, v in pairs(lout) do
			if not (v == nil) then
				ok =  true
			end
			return ok
		end
	end
	return function(lout)
        if lout == nil then
            return lout
        end
		if fn(lout) then
			return lout
		end
	end
end

function F.filter(fn)
	return function(out)
		if fn(out) then
			return out
		end
	end
end

function F.map(fn)
	return function(out)
		return fn(out)
	end
end

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
