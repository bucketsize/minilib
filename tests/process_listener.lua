#!/usr/bin/env lua
package.path = '?.lua;' .. package.path
require "luarocks.loader"
luaunit = require('luaunit')

local Lr = require("process_listener")
local Sh = require("shell")

function test_listener()
    Lr.new_listener()
		.listen("pi", "less", "start", function()
    	    Sh.fork("weston-flower")
	    end)
		.start()
end

os.exit( luaunit.LuaUnit.run() )
