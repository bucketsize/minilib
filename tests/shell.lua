#!/usr/bin/env lua
package.path = "?.lua;" .. package.path
require("luarocks.loader")
require("luacov")
local luaunit = require("luaunit")
local Sh = require("shell")

function test_01_split_path()
	local x
	x = Sh.util.split_path("totem")
	print(x)
	assert("totem" == x)

	x, y = Sh.util.split_path("/var/tmp/totem")
	print(x, y)
	assert("totem" == x)
	assert("/var/tmp" == y)

	x, y = Sh.util.split_path("/var/tmp bin/.totem")
	print(x, y)
	assert(".totem" == x)
	assert("/var/tmp bin" == y)

	x, y = Sh.util.split_path("var/tmp/totem.bin")
	print(x, y)
	assert("totem.bin" == x)
	assert("var/tmp" == y)
end
function test_02_arch()
	print("system architecture:", Sh.util.arch())
	assert(Sh.util.arch())
end
function test_03_shell_launch_app()
	local r, sig, code = Sh.util.sh("weston-flower &")
	print(r, sig, code)
	print("done")
end
function test_04_shell_nohup()
	local r, sig, code = Sh.util.nohup("conky -c ~/scripts/config/conky/simple/conky.conf")
	print(r, sig, code)
	print("done")
end
-- function test_05_shell_fork()
-- 	local r, sig, code = Sh.fork("glxgears")
-- 	print(r, sig, code)
-- 	print("done")
-- end
function test_06_pkgs()
	assert(Sh.util.file_exists("curl"))
	assert(Sh.util.lib_exists("libssl"))
end
function test_07_ln()
	Sh.util.ln("/etc/hosts", "/var/tmp/dns.cfg")
end
function test_08_pgrep()
	local t, s = Sh.util.pgrep("lua")
	assert(Sh.util.pgrep("lua"))
	assert(not Sh.util.pgrep("phantomkahn"))

	if Sh.util.pgrep("lua") then
		assert(true)
	else
		assert(false)
	end

	if Sh.util.pgrep("conky") then
		Sh.util.killall("conky")
	end

	-- if Sh.pgrep("glxgears") then
	-- 	Sh.killall("glxgears")
	-- end
end

function test_09_exec_cb()
	Sh.util.__exec("ls -l ~/")
	Sh.util.__exec_cb("ls -l ~/", function(x)
		print("|yea> " .. x)
	end)
end

function test_10_groups()
	local gs = Sh.util.groups()
	assert(#gs > 0)
end

function test_11_mkdir()
	Sh.util.mkdir("/tmp/" .. tostring(os.time()) .. "/now")
	-- assert(Sh.util.path_exists(file))
end

function test_12_lsbrelease()
	local parch = Sh.util.lsb_release()
	print("lsb_release.distro=", parch.distro)
	assert(parch.distro)
end

os.exit(luaunit.LuaUnit.run())
