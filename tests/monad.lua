#!/usr/bin/env lua
package.path = '?.lua;' .. package.path
require "luarocks.loader"
luaunit = require('luaunit')

local M = require("monad")

local f = function(x) return x*x end
local g = function(x) return x+1 end

function test_just_fmap()
	local m = M.Just.of(12):fmap(f)
	assert(m:eq(M.Just.of(144)))	
end

function test_just_fmap_nil()
	local m = M.Just.of(123)
		:fmap(function(x) return nil end)
	assert(m:eq(M.Nothing))	
end

function test_just_fmap_nothing()
	local m = M.Nothing
		:fmap(function(x) return nil end)
	assert(m:eq(M.Nothing))	
end

function test_just_id()
	local m = M.Just.of(8)
	assert(m.value == 8)
end

function test_just_assoc()
	local m = M.Just.of(8):fmap(f):fmap(g)
	local r = M.Just.of(f(8)):fmap(g)
	assert(m:eq(r))
end

function test_list_fmap()
	local m = M.List.of({1,2,3,4})
		:fmap(f)
		:fmap(g)
	assert(m.Type == "List")
	assert(m[3] == 10)
end

function test_dict_fmap()
	local m = M.List.of({a=1,b=2,c=3,d=4})
		:fmap(f)
		:fmap(g)
	assert(m.Type == "List")
	assert(m.c == 10)
end

-- monadic laws
-- M a >>= f  => M f(a)
-- M a >>= of => M a
-- M a >>= f >>= g => M a >>= f(g)

local mf = function(x) return M.Just.of(x*x) end
local mg = function(x) return M.Just.of(x+1) end

function test_just_monad_law_1()
	local m = M.Just.of(8):bind(mf)
	local r = mf(8)
	assert(m:eq(r))
end

function test_just_monad_law_2()
	local m = M.Just.of(8):bind(M.Just.of)
	local r = M.Just.of(8)
	assert(m:eq(r))
end

function test_just_monad_law_3()
	local m = M.Just.of(8):bind(mf):bind(mg)
	local r = M.Just.of(8):bind(function(x)
		local y = mf(x)
		return  mg(y.value)
	end)
	assert(m:eq(r))
end

os.exit( luaunit.LuaUnit.run() )
