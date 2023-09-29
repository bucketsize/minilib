package.path = "?.lua;" .. package.path
require("luarocks.loader")

local json = require("minilib.json")
local logger = require("minilib.logger").create()

local Util = {}
function Util:tofile(file, t)
	local h = assert(io.open(file, "w"))
	for k, v in pairs(t) do
		h:write(string.format("%s => %s\n", k, v))
	end
	h:close()
end
function Util:fromfile(file)
	local h = assert(io.open(file, "r"))
	local r = {}
	for l in h:lines() do
		local k, v = string.match(l, "(.+) => (.+)")
		r[k] = v
	end
	h:close()
	return r
end
function Util:size(t)
	if #t > 0 and t[#t + 1] == nil then
		return #t
	else
		local c = 0
		for i, v in pairs(t) do
			c = c + 1
		end
		return c
	end
end
function Util:keys(t)
	local c = {}
	for i, _ in pairs(t) do
		table.insert(c, i)
	end
	return c
end
function Util:values(t)
	local c = {}
	for _, i in pairs(t) do
		table.insert(c, i)
	end
	return c
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
function __find_all(sep, a, i, path)
	local s, f = path:find(sep, i)
	-- logger.info(path, i, s, f)
	if f then
		table.insert(a, { s, f })
		return __find_all(sep, a, f + 1, path)
	else
		return a
	end
end
function __split(sep, a, i, path, opt)
	local s, f = path:find(sep, i, opt.plain)
	-- logger.info(path, i, s, f)
	if f then
		table.insert(a, path:sub(i, s - 1))
		return __split(sep, a, f + 1, path, opt)
	else
		if #path > i then
			table.insert(a, path:sub(i))
		end
		return a
	end
end
function Util:find_all(sep, path)
	return __find_all(sep, {}, 1, path)
end
function Util:split(sep, path, opt)
	if not opt then
		opt = { regex = true, plain = false }
	else
		if opt.regex == nil then
			opt.regex = true
			opt.plain = false
		end
		if opt.plain == nil then
			opt.plain = not opt.regex
		end
	end
	-- logger.info("split opts:", opt.regex, opt.plain)
	return __split(sep, {}, 1, path, opt)
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
	for i = #itable, 1, -1 do
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
	for _, w in ipairs(list) do
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
function Util:head_file(filename)
	local h = io.open(filename, "r")
	local r
	if h then
		r = h:read("*l")
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
	local r = Util:stream_file(file, function(line)
		local m = string.match(line, pattern)
		if m then
			return m
		end
	end)
	for i, v in ipairs(r) do
		if not (v == nil) then
			return v
		end
	end
end

function Util:exec(cmd)
	logger.debug("exec %s", cmd)
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
		if l == nil then
			break
		end
		fn(l)
	end
	h:close()
end
function Util:stream_file(cmd, fn)
	local h = assert(io.open(cmd, "r"))
	local r = {}
	while true do
		local l = h:read("*line")
		if l == nil then
			break
		end
		local s = fn(l)
		if s then
			table.insert(r, s)
		end
	end
	h:close()
	return r
end
function Util:join(tag, list)
	local s = ""
	for i, v in ipairs(list) do
		if i == #list then
			s = string.format("%s%s", s, v)
		else
			s = string.format("%s%s%s", s, v, tag)
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
		--logger.info(i,c)
		if not Util:iswhitespace(c) then
			for j = #str, 1, -1 do
				local r = str:sub(j, j)
				--logger.info(j,r)
				if not Util:iswhitespace(r) then
					return str:sub(i, j)
				end
			end
		end
	end
end
function Util:wminfo()
	local h = assert(io.popen("wmctrl -m"))
	local wm = "generic"
	for line in h:lines() do
		wm = line:match("Name:%s(%w+)")
		if wm then
			break
		end
	end
	return { wm = wm }
end
function Util.tos(list, level)
	if type(list) ~= "table" then
		return tostring(list)
	end
	if level == nil then
		level = 1
	end
	local b = "[ "
	local i = 1
	for k, v in pairs(list) do
		if type(v) == "function" then
			v = "function"
		end
		if type(v) == "table" then
			if level < 3 then
				v = Util.tos(v, level + 1)
			end
		end
		if i == 1 then
			b = string.format("%s%s", b, v)
		else
			b = string.format("%s, %s", b, v)
		end
		i = i + 1
	end
	return b .. " ]"
end

function Util.tojson(t)
	return json.encode(t)
end

return Util
