local MObj = {value=nil, Type=nil}
function MObj:eq(mobj)
	return self.value == mobj.value
end
function MObj.of(value, typeT)
	local o = {value=normal}
	setmetatable(o, {__index = typeT})
	return o
end

local Maybe   = {}
setmetatable(Maybe, {__index = MObj})

local Just    = {Type = "Just"}
setmetatable(Just, {__index = Maybe})

local Nothing = {Type = "Nothing"}
setmetatable(Nothing, {__index = Maybe})

-- of :: a -> Maybe a
function Just.of(s)
	if s == nil then
		return Nothing
	end
	local o = {value=s}
	setmetatable(o, {__index = Just})
	return o
end

-- fmap :: (a -> b) -> Maybe a -> Maybe b
function Maybe:fmap(f)
	if self.Type == "Just" then
		return Just.of(f(self.value))
	else
		return Nothing
	end
end

-- bind:: (a -> Maybe b) -> Maybe a -> Maybe b
function Maybe:bind(f)
	return f(self.value)
end

local List = {Type="List"}
setmetatable(List, {__index = MObj})

-- of :: a -> List a
function List.of(t)
	local o = t or {}
	setmetatable(o, {__index = List})
	return o
end

-- fmap :: (a -> b) -> List a -> List b
function List:fmap(f)
	local o = {}
	for k,v in pairs(self) do
		o[k] = f(v)
	end
	return List.of(o)
end

-- bind:: (a -> List b) -> List a -> List b
function List:bind(f)
	local o = {}
	for k,v in pairs(self) do
		o[k] = f(v)[1]
	end
	return List.of(o)
end

return 
	{ Maybe=Maybe
	, Just=Just
	, Nothing=Nothing
	, List=List}
