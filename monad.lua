local Maybe   = {}
local Just    = {Type = "Just", s=nil}
local Nothing = {Type = "Nothing"}
function Just:of(s)
	if s == nil then
		return Nothing
	end
	local o = {s=s}
	setmetatable(o, {__index = Just})
	return o
end
function Maybe:fmap(f)
	if self.Type == "Just" then
		return Just:of(f(self.s))
	else
		return Nothing
	end
end
setmetatable(Just, {__index = Maybe})
setmetatable(Nothing, {__index = Maybe})
local List = {Type="List"}
function List:of(t)
	local o = t or {}
	setmetatable(o, {__index = List})
	return o
end
function List:fmap(f)
	local o = {}
	for k,v in pairs(self) do
		o[k] = f(v)
	end
	return List:of(o)
end
return 
	{ Maybe=Maybe
	, Just=Just
	, Nothing=Nothing
	, List=List}
