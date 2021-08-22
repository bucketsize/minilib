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

function F.grep(patt)
	return function(s)
		local r = {}
		r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8],r[9],r[10] = string.match(s, patt)
		if r[1] == nil then return nil end
		return r
	end
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

return F
