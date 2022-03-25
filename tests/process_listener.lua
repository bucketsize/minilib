#!/usr/bin/env lua

package.path = os.getenv("HOME") .. '/?.lua;'
    .. package.path

local Lr = require("minilib.process_listener")
local Sh = require("minilib.shell")

function test_listener()
    Lr.new_listener()("pi", "less", function()
        Sh.fork("weston-flower")
    end)
end

test_listener()
