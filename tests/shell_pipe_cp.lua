#!/usr/bin/env lua

package.path = os.getenv("HOME") .. '/?.lua;'
    .. package.path

local Pr = require("minilib.process")
local Sh = require("minilib.shell")
local Util = require("minilib.util")

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

test_copy_files()
