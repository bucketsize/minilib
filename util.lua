local socket = require("socket")
local Ot = require("minilib.otable")

local Util={}
function Util:tofile(file, t)
   local h = assert(io.open(file, 'w'))
   for k, v in pairs(t) do
	  h:write(string.format('%s => %s\n', k, v))
   end
   h:close()
end
function Util:fromfile(file)
   local h = assert(io.open(file, 'r'))
   local r = {} 
   for l in h:lines() do
	  local k, v = string.match(l, "(.+) => (.+)")
	  r[k] = v
   end
   h:close()
   return r
end
function Util:size(t)
    if #t > 0 and t[#t+1] == nil then 
        return #t
    else
        local c = 0
        for i,v in pairs(t) do
            c = c + 1
        end
        return c
    end
end
function Util:eq(o1, o2)
    if #o1 ~= #o2 then
        return false
    end
    for k, v in pairs(o1) do
        if o2[k] and o2[k] == v then
        else
            return false
        end
    end
    return true
end
function Util:split(sep, path)
   function __split(sep, a, path)
	  local l = string.len(path)
	  local s, f = path:find(sep)
      -- print("__split.i:", s, f)
	  if f then
		 if f > 1 then
			local p = string.sub(path, 0, s-1)
			table.insert(a, p)
		 end
		 return __split(sep, a, string.sub(path, f+1))
	  else
		 table.insert(a, path)
         return a
	  end
   end
   return __split(sep, {}, path)
end
function Util:segpath(path)
    return Util:split("/", path)
end
function Util:head(itable)
    if #itable == 0 then
        return nil
    end
    return itable[1]
end
function Util:tail(itable)
    if #itable == 0 then
        return {}
    end
    local r = {}
    for i = 2, #itable, 1 do
        table.insert(r, itable[i])
    end
    return r
end
function Util:reverse(itable)
   local r = {}
   for i = #itable,1,-1 do
	  table.insert(r, itable[i])
   end
   return r
end
function Util:map(f, t)
	local r = {}
	for k, v in pairs(t) do
		r[k] = f(v)
	end
	return r
end
function Util:map2(fk, fv, t)
	local r = {}
	for k, v in pairs(t) do
	   r[fk(k)] = fv(v)
	end
	return r
end
function Util:filter(f, t)
	local r = {}
	for k, v in pairs(t) do
		if f(v) then
			table.insert(r, v)
		end
	end
	return r
end
function Util:fold(f, t, i)
	local r = i
	for k, v in pairs(t) do
		r = f(v, r)
	end
	return r
end
function Util:haz(list, s)
    for _,w in ipairs(list) do
        if s:find(w) then
            return true
        end
    end
    return false
end
function Util:f_else(p, fn1, fn2)
    if p then
        fn1()
    else
        return fn2()
    end
end
function Util:if_else(p, o1, o2)
   if p then
      return o1
   else
      return o2
   end
end
function Util:read(filename)
   local h = io.open(filename, "r")
   local r
   if h then
	  r = h:read("*a")
	  h:close()
   else
	  r = nil
   end
   return r
end
function Util:log(level, file, msg)
   local h = assert(io.open(file, "a"))
   h:write(string.format("%s - %s - %s\n", os.date("%Y-%m-%dT%H:%M:%S+05:30"), level, msg))
   h:close()
end
function Util:grep(file, pattern)
   local r = Util:stream_file(file,
							  function(line)
								 local m = string.match(line, pattern)
								 if m then
									return m
								 end
   end)
   for i,v in ipairs(r) do
	  if not (v == nil) then
		 return v
	  end
   end
end

function Util:launch(app)
   local cmd = string.format("nohup setsid %s > /dev/null &"
    , app:gsub("%%U", "/var/tmp")
    , exec_log)
   print("exec>", cmd)
   local h = assert(io.popen(cmd, "r"))
   local r = h:read("*a")
   socket.sleep(1) -- for some reason needed so exit can nohup process to 1
   h:close()
end
function Util:exec(cmd)
    print("exec>", cmd)
	local h = io.popen(cmd, "r")
	local r
	if h == nil then
		r = ""
	else
		r = h:read("*a")
		h:close()
	end
	return r
end
function Util:stream_exec(cmd, fn)
	local h = assert(io.popen(cmd))
	while true do
		local l = h:read("*line")
		if l == nil then break end
		fn(l)
	end
	h:close()
end
function Util:stream_file(cmd, fn)
   local h = assert(io.open(cmd, 'r'))
   local r = {}
   while true do
	  local l = h:read("*line")
	  if l == nil then break end
	  local s = fn(l)
	  if s then
		 table.insert(r,s)
	  end
   end
   h:close()
   return r
end
function Util:join(tag, list)
	local s=""
	for i,v in ipairs(list) do
		if i == #list then
			s = string.format("%s%s",s,v)
		else
			s = string.format("%s%s%s",s,v,tag)
		end
	end
	return s
end
function Util:iswhitespace(c)
	return (c == "" or c == " " or c == "\t")
end
function Util:strip(str)
	for i = 1, #str do
		local c = str:sub(i, i)
		--print(i,c)
		if not Util:iswhitespace(c) then
			for j = #str, 1, -1 do
				local r = str:sub(j, j)
				--print(j,r)
				if not Util:iswhitespace(r) then
					return str:sub(i, j)
				end
			end
		end
	end
end
function Util:printITable(t)
	for i,v in ipairs(t) do
		print(i .. ': ', v)
	end
end
function Util:printOTable(t)
	for i,v in pairs(t) do
		if type(v) == 'table' then
			print(i ..':')
			Util:printOTable(v)
		else
			print(i .. ': ', v)
		end
	end
end
function Util:run_co(k, co)
   local status = coroutine.status(co)
	 if (status == 'dead') and (not co.dead) then
		 co.dead = true
		 return print('co/ ' .. k, status)
	 end
   local ok,res = coroutine.resume(co)
   if not ok then
      print('co/ ' .. k, res)
   end
end

function Util:new_timer()
    return {
        epoc_interval = 1,
        t = 0,
        fns = {},
        tick = function(self, interval, fn)
            table.insert(self.fns, {fn = fn, i = interval})
        end,
        start = function(self, tepocs)
            print("timer started:", self)
            while true do
                self.t = self.t + 1
                for i, fd in ipairs(self.fns) do
                    if (self.t % fd.i) == 0 then
                        fd.fn()
                    end
                end
                -- print("epoc", self.t)
                if not (self.t < tepocs) then
                    break
                end
                Util:sleep(self.epoc_interval)
            end
        end
    }
end

function Util:sleep(n)
    socket.sleep(n)
end

return Util
