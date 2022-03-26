#!/usr/bin/env lua

package.path = os.getenv("HOME") .. '/?.lua;'
    .. package.path

local Util = require("minilib.util")

function test_exec_sh_cmd()
    local r = Util:exec("ls -l ~/")
    print(r)
    print("done")
end

test_exec_sh_cmd()
