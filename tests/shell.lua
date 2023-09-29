#!/usr/bin/env lua
package.path = "?.lua;" .. package.path
require("luarocks.loader")
require("luacov")
luaunit = require("luaunit")
local Sh = require("shell")
local Ut = require("util")
local Tr = require("timer")

function test_01_split_path()
	local x

	x = Sh.split_path("totem")
	print(x)
	assert("totem" == x)

	x, y = Sh.split_path("/var/tmp/totem")
	print(x, y)
	assert("totem" == x)
	assert("/var/tmp" == y)

	x, y = Sh.split_path("/var/tmp bin/.totem")
	print(x, y)
	assert(".totem" == x)
	assert("/var/tmp bin" == y)

	x, y = Sh.split_path("var/tmp/totem.bin")
	print(x, y)
	assert("totem.bin" == x)
	assert("var/tmp" == y)
end
function test_02_arch()
	print("system architecture:", Sh.arch())
end
function test_03_shell_launch_app()
	local r, sig, code = Sh.sh("weston-flower &")
	print(r, sig, code)
	print("done")
end
function test_04_shell_nohup()
	local r, sig, code = Sh.nohup("conky -c ~/scripts/config/conky/simple/conky.conf")
	print(r, sig, code)
	print("done")
end
-- function test_05_shell_fork()
-- 	local r, sig, code = Sh.fork("glxgears")
-- 	print(r, sig, code)
-- 	print("done")
-- end
function test_06_pkgs()
	print(Sh.file_exists("wget"))
	print(Sh.lib_exists("libssl"))
end
function test_07_ln()
	Sh.ln("/etc/hosts", "/var/tmp/dns.cfg")
end
function test_08_pgrep()
	local t, s = Sh.pgrep("lua")
	assert(Sh.pgrep("lua"))
	assert(not Sh.pgrep("phantomkahn"))

	if Sh.pgrep("lua") then
		assert(true)
	else
		assert(false)
	end

	Tr.sleep(5)
	if Sh.pgrep("conky") then
		Sh.killall("conky")
	end

	-- if Sh.pgrep("glxgears") then
	-- 	Sh.killall("glxgears")
	-- end
end

function test_09_exec_cb()
	Sh.__exec("ls -l ~/")
	Sh.__exec_cb("ls -l ~/", function(x)
		print("|yea> " .. x)
	end)
end

function test_10_groups()
	local gs = Sh.groups()
	assert(#gs > 0)
end

function test_11_mkdir()
	Sh.mkdir("/tmp/" .. tostring(os.time()) .. "/now")
end

function test_12_lsbrelease()
	local parch = Sh.lsb_release()
	print("lsb_release.distro=", parch.distro)
end

os.exit(luaunit.LuaUnit.run())
