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
    local r,sig,code = Sh.nohup("conky -c ~/scripts/config/conky/simple/conky.conf")
    print(r,sig,code)
    print("done")
end
function test_shell_fork()
    local r,sig,code = Sh.fork("glxgears")
    print(r,sig,code)
    print("done")
end
function test_pkgs()
    print(Sh.file_exists("wget"))
    print(Sh.lib_exists("libssl"))
end
function test_ln()
    Sh.ln ("/etc/hosts", "/var/tmp/dns.cfg")
end

test_arch()
test_shell_launch_app()
test_shell_nohup()
test_shell_fork()
test_pkgs()
test_ln()


