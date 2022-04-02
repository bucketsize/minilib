#!/usr/bin/env lua
package.path = '?.lua;' .. package.path
require "luarocks.loader"
luaunit = require('luaunit')

local Util = require("util")

function test_exec_sh_cmd()
    local r = Util:exec("ls -l ~/")
    print(r)
    print("done")
end

os.exit( luaunit.LuaUnit.run() )
