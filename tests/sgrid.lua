#!/usr/bin/env lua
package.path = '?.lua;' .. package.path
require "luarocks.loader"
luaunit = require('luaunit')

local Sg = require("sgrid")

function test_sgrid()
	local sg = {}

	Sg.put_elem(sg, {1,2,4}, "1.2.4")
	Sg.put_elem(sg, {1,3}, "1.3")
	Sg.put_elem(sg, {2}, "2")
	
	Sg.put_elem(sg, {1,"two",4}, "1.two.4")
	Sg.put_elem(sg, {"one",3}, "one.3")
	Sg.put_elem(sg, {1,"three"}, "1.three")
	Sg.put_elem(sg, {"two"}, "two")

	 -- assert
	assert(Sg.get_elem(sg, {1,2,4}) == "1.2.4")
	assert(Sg.get_elem(sg, {1,3}) == "1.3")
	assert(Sg.get_elem(sg, {2}) == "2")

	assert(Sg.get_elem(sg, {1,"two",4}) == "1.two.4")
	assert(Sg.get_elem(sg, {"one",3}) == "one.3")
	assert(Sg.get_elem(sg, {1,"three"}) == "1.three")
	assert(Sg.get_elem(sg, {"two"}) == "two")
end

os.exit( luaunit.LuaUnit.run() )

