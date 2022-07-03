#!/usr/bin/env lua
package.path = '?.lua;' .. package.path
require "luarocks.loader"
luaunit = require('luaunit')

local M = require("monad")

local f = function(x) return x*x end
local g = function(x) return x+1 end

function test_just_fmap()
	local m = M.Just
		:of(12)
		:fmap(f)
	assert(m.Type == "Just")	
	assert(m.s == 144)	
end

function test_just_fmap_nil()
	local m = M.Just
		:of(123)
		:fmap(function(x) return nil end)
	assert(m.Type == "Nothing")	
	assert(m.s == nil)	
end

function test_just_fmap_nothing()
	local m = M.Nothing
		:fmap(function(x) return nil end)
	assert(m.Type == "Nothing")	
	assert(m.s == nil)	
end

function test_just_id()
	local m = M.Just:of(8)
	assert(m.s == 8)
end

function test_just_assoc()
	local m = M.Just:of(8)
		:fmap(f)
		:fmap(g)
	local r = M.Just:of(f(8))
		:fmap(g)
	assert(m.s == r.s)
end

function test_list_fmap()
	local m = M.List:of({1,2,3,4})
		:fmap(f)
		:fmap(g)
	assert(m.Type == "List")
	assert(m[3] == 10)
end

function test_dict_fmap()
	local m = M.List:of({a=1,b=2,c=3,d=4})
		:fmap(f)
		:fmap(g)
	assert(m.Type == "List")
	assert(m.c == 10)
end

os.exit( luaunit.LuaUnit.run() )
