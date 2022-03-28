#!/usr/bin/env lua

package.path = os.getenv("HOME") .. '/?.lua;'
    .. package.path

local Lr = require("minilib.process_listener")
local Sh = require("minilib.shell")

function test_listener()
    Lr.new_listener()
		.listen("pi", "less", "start", function()
    	    Sh.fork("weston-flower")
	    end)
		.start()
end

test_listener()
