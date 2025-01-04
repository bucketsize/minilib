local U = require("minilib.util")

local MTyp = {
	Obj = 1,
	Maybe = 2,
	Just = 3,
	Nothing = 4,
	List = 5,
	Either = 6,
	Left = 7,
	Right = 8,
	IO = 9,
	Stream = 10,
}

local MObj = { value = nil, Type = MTyp.Obj }
function MObj:eq(mobj)
	return self.value == mobj.value
end
function MObj.of(x, typeT)
	local o = { value = x}
	setmetatable(o, { __index = typeT })
	return o
end
function MObj:show()
	return string.format("Typ.%s %s", self.Type, U.tojson(self))
end

-- functor
-- of   :: a -> M a
-- fmap :: (a -> b) -> M a -> M b

-- monad
-- of 	:: a -> M a
-- bind :: (a -> M b) -> M a -> M b
local Maybe = {}
setmetatable(Maybe, { __index = MObj })

local Just = { Type = MTyp.Just }
setmetatable(Just, { __index = Maybe })

local Nothing = { Type = MTyp.Nothing }
function Nothing:show()
	return "Nothing"
end
setmetatable(Nothing, { __index = Maybe })

function Just.of(s)
	if s == nil then
		return Nothing
	end
	local o = { value = s }
	setmetatable(o, { __index = Just })
	return o
end

function Just:fmap(f)
	return Just.of(f(self.value))
end

function Just:bind(f)
	return f(self.value)
end

function Nothing.of(s)
	return Nothing
end

function Nothing:fmap(f)
	return Nothing
end

function Nothing:bind(f)
	return Nothing
end

local List = { Type = MTyp.List }
setmetatable(List, { __index = MObj })

function List.of(t)
	local o
	if type(t) == "table" then
		o = t or {}
	else
		o = { t }
	end
	setmetatable(o, { __index = List })
	return o
end

function List:eq(l)
	if not (#self == #l) then
		return false
	end
	for k, v in ipairs(self) do
		if not (v == l[k]) then
			return false
		end
	end
	return true
end

function List:fmap(f)
	local o = {}
	for k, v in pairs(self) do
		o[k] = f(v)
	end
	return List.of(o)
end
function List:keys()
	local o = {}
	for k, v in pairs(self) do
		table.insert(o, k)
	end
	return List.of(o)
end
function List:bind(f)
	local o = {}
	for k, v in pairs(self) do
		o[k] = f(v)[1]
	end
	return List.of(o)
end
function List:filter(f)
	local o = {}
	for k, v in pairs(self) do
		if f(v) then
			o[k] = v
		end
	end
	return List.of(o)
end
function List:join(d)
	local o = ""
	for _, v in pairs(self) do
		o = o .. tostring(v) .. d
	end
	return o
end
local Either = { Type = MTyp.Either }
setmetatable(Either, { __index = MObj })

local Left = { Type = MTyp.Left }
setmetatable(Left, { __index = Either })

function Left.of(x)
	local o = { value = x }
	setmetatable(o, { __index = Left })
	return o
end

function Left:fmap(f)
	return Left.of(f(self.value))
end

function Left:bind(f)
	return f(self.value)
end

local Right = { Type = MTyp.Left }
setmetatable(Right, { __index = Either })

function Right.of(x)
	local o = { value = x }
	setmetatable(o, { __index = Right })
	return o
end

function Right:fmap(f)
	return Right.of(f(self.value))
end

function Right:bind(f)
	return f(self.value)
end

local IO = { Type = MTyp.IO }
setmetatable(IO, { __index = MObj })
function IO.of(x)
	local o = { value = x }
	setmetatable(o, { __index = IO })
	return o
end
function IO:fmap(f)
	return IO.of(f(self.value))
end
function IO:bind(f)
	return f(self.value)
end
function IO.read_lines_file(f)
	local h = assert(io.open(f, "r"))
	local ls = {}
	while true do
		local l = h:read("*line")
		if l == nil then
			break
		else
			table.insert(ls, l)
		end
	end
	h:close()
	return IO.of(List.of(ls))
end
function IO.read_lines_pout(f)
	local h = assert(io.popen(f))
	local ls = {}
	while true do
		local l = h:read("*line")
		if l == nil then
			break
		else
			table.insert(ls, l)
		end
	end
	h:close()
	return IO.of(List.of(ls))
end
local Stream = { Type = MTyp.Stream }
setmetatable(Stream, { __index = MObj })
function Stream.of(x)
	local o = { value = x, source=nil }
	setmetatable(o, { __index = Stream })
	return o
end
function Stream.filelines(f)
	local h = assert(io.open(f, "r"))
  local i = Stream.of(h)
  i.source = "filelines"
  i.readfn = function()
		return h:read("*line")
  end
end
function Stream.fmap()

return {
	MTyp = MTyp,
	Maybe = Maybe,
	Just = Just,
	Nothing = Nothing,
	List = List,
	Either = Either,
	Left = Left,
	Right = Right,
	IO = IO,
}
