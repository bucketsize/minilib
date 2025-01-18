local logger = require("minilib.logger").create()

-- @Deprecated -- use via monad
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
			for i = 1, t - 1 do
				local a0 = a
				a = fn[i](a)
				if a == nil then
					e[i] = true
				else
					e[i] = false
					ended = false
				end
				if trace then
					logger.info("fn_%s %s -> %s %s", i, a0, a, e[i])
				end
			end
			if not (a == nil) then
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
			if r == nil then
				return r
			end
			local out = {}
			for i = 1, t - 1 do
				out[i] = fn[i](r)
			end
			return out
		end
	end
	return p
end

function F.bget(l)
	logger.info("bget: %s", l)
	local r = {}
	local i = 1
	return function(x)
		while true do
			local s = l[i]
			if s == nil then
				break
			end
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
				ok = true
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

return F
