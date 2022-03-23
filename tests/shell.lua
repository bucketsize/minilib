#!/usr/bin/env lua

package.path = os.getenv("HOME") .. '/?.lua;'
    .. package.path

local Sh = require("minilib.shell")

function test_arch()
    print("system architecture:", Sh.arch())
end
function test_shell_launch_app()
    local r,sig,code = Sh.sh("weston-flower &")
    print(r,sig,code)
    print("done")
end
function test_shell_nohup()
    local r,sig,code = Sh.nohup("urxvt")
    print(r,sig,code)
    print("done")
end

test_arch()
test_shell_launch_app()
test_shell_nohup()



