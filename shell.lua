local Util = require('minilib.util')
local Process = require('minilib.process')

local F = {}

function F.cat(path)
   local h = assert(io.open(path, 'r'))
   return function()
	  local l = h:read("*line")
	  if l == nil then
		 h:close()
	  end
	  return l
   end
end

function F.exec(path)
   local h = assert(io.popen(path))
   return function()
	  local l = h:read("*line")
	  if l == nil then
		 h:close()
	  end
	  return l
   end
end

function F.find(path)
    local cmd = string.format(
        "find %s -type f -exec grep -Iq . {} \\; -print",
        path)
    local h = assert(io.popen(cmd))
    return function()
        if h == nil then
            return nil
        end
        local l = h:read("*line")
        if l == nil then
            h:close()
            h = nil
        end
        return l
    end
end

local skip_paths = {"git"}

function F.read()
    local h, p = nil, 1
    local paths = {}
    return function(path)
        if not (path == nil) then
            if not Util:haz(skip_paths, path) then
                table.insert(paths, path)
                print("read next", path)
            end
        end
        if h == nil then
            h = assert(io.open(paths[p], "r"))
        end
        local l = h:read("*line")
        if l == nil then
            h:close()
            if p < #paths then
                p = p + 1
                h = assert(io.open(paths[p]))
                l = h:read("*line")
            else
                print("read ", #paths, paths[p])
                return nil
            end
        end
        return {path=paths[p], line=l}
    end
end

function F.sed(slist)
    return function(fline)
        if fline == nil then
            return fline
        end
        for p,sub in pairs(slist) do
            fline.line = fline.line:gsub(p, sub)
        end
        return fline
    end
end

function F.mkdir(path)
    Util:exec(
        string.format("mkdir -p %s", path))
    print("mkdir", path)
end

function F.open(path, mode)
    local h = io.open(path, mode)
    if h == nil then
        local b, d = F.split_path(path)
        F.mkdir(d)
        h = io.open(path, mode)
    end
    return h
end

function F.write(head_path)
    local h, p = nil, nil
    local c = 0
    return function(fline)
        if fline == nil then
            print("write", c)
            return fline
        end
        local wpath = head_path .. fline.path
        if (h == nil) then
            print("write next", wpath)
            h = F.open(wpath, "w")
            p = fline.path
            c = c+1
        else
            if not (p == fline.path) then
                print("write next", wpath)
                h:close()
                h = F.open(wpath, "w")
                p = fline.path
                c = c+1
            end
            -- print("write cont >>", wpath)
        end
        if not (fline.line == nil) then
            h:write(fline.line)
            h:write('\n')
            -- print(wpath .. " << " .. fline.line)
        end
        return fline
    end
end

function F.grep(patt)
	return function(s)
		local r = {}
		r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8],r[9],r[10] = string.match(s, patt)
		if r[1] == nil then return nil end
		return r
	end
end

function F.echo()
	return function(s)
		if type(s) == 'function' then
			print('function')
		else
			if type(s) == 'table' then
				print(listToString(s))
			else
				print(s)
			end
		end
		return s
	end
end

function F.format(patt)
	return function(s)
		return string.format(patt, s)
	end
end

function F.flat(delim)
	return function(list)
		local s = ''
		for i,v in pairs(list) do
				if i == 1 then
					s = s .. v
				else
					s = s .. delim .. v
				end
		end
		return s
	end
end

function F.split_path(path)
    local li  = Util:reverse(Util:segpath(path))
    local b,p = Util:head(li),
        "/"..Util:join("/", Util:reverse(Util:tail(li)))
    return b,p
end

function listToString(list, level)
	if level == nil then level = 1 end
	local b = ''
	local i = 1
	for k, v in pairs(list) do
		if type(v) == 'function' then
			v = 'function'
		end
		if type(v) == 'table' then
			if level < 3 then
				v = listToString(v, level+1)
			end
		end
		if i==1 then
			b = string.format('%s', v)
		else
			b = string.format('%s, %s', b, v)
		end
		i = i + 1
	end
	return b
end

return F
