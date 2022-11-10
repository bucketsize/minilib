#!/usr/bin/env lua
package.path = '?.lua;' .. package.path
require "luarocks.loader"
luaunit = require('luaunit')

local T = require("timer")

function test_timer()
	print("test_timer, start")
    local timer = T.new_timer()
    local t0, t1, t2, t5, t8 = 0, 0, 0, 0, 0
    timer:tick(0.1, function() t0 = t0+1 end)
    timer:tick(0.2, function() t1 = t1+1 end)
    timer:tick(2, function() t2 = t2+1 end)
    timer:tick(5, function() t5 = t5+1 end)
    timer:tick(8, function() t8 = t8+1 end)
    timer:start(16)
	print("test_timer", t0,t1,t2,t5,t8)
    assert(t0 == 10*16)
    assert(t1 == 5*16)
    assert(t2 == 8)
    assert(t5 == 3)
    assert(t8 == 2)
end

os.exit( luaunit.LuaUnit.run() )
