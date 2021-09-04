local F = {}

function F.pipe()
	local fn = {}
	local t = 1
	local p = {}
	function p.add(f)
		fn[t] = f
		t = t + 1
		return p
	end
	function p.run()
		local a,s
		while true do
			local a = fn[1]()
			if a == nil then break end
			for i = 2, t-1 do
				if not (a == nil) then
					a = fn[i](a)
				end
			end
			if not (a==nil) then
				s = a
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
			local out = {}
			for i = 1, t-1 do
				out[i] = fn[i](r)
			end
			return out
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
