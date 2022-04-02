#!/usr/bin/env lua
package.path = '?.lua;' .. package.path
require "luarocks.loader"
luaunit = require('luaunit')

local Pr = require("process")
local Sh = require("shell")
local Ut = require("util")

function test_copy_files()
    Pr.pipe()
        .add(Sh.find("~/frmad/"))
        .add(Sh.read())
        .add(Sh.sed({
            ["print("] = "sysout",
            ["string"] = "Stringy"
        }))
        .add(Sh.write("/var/tmp/t1"))
        .run()
end

os.exit( luaunit.LuaUnit.run() )
