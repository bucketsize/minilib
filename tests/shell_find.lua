#!/usr/bin/env lua
package.path = '?.lua;' .. package.path
require "luarocks.loader"
luaunit = require('luaunit')

local Pr = require("process")
local Sh = require("shell")
local Ut = require("util")

function test_1_find()
	Sh.traverse({"/etc"}, 1, function(f) print("find>", f) end)
end

function test_3_find()
	Pr.pipe()
		.add(Sh.find("/etc", "%.xml$"))
		.add(function(f)
			if f then
				if not f:find("xml") then
					assert(false, "filter *.xml failed for: " .. f)
				end
			end
			return f
		end)
		.add(function(f)
			if f then
				print(f, "->", Sh.sha1sum(f))
			end
			return f
		end)
		.run()
end
function test_4_find()
	local termicons = Pr.pipe()
		.add(Sh.find("/usr/share/icons", "32.*terminal.*"))
		.add(function(f)
			if f then
				print("termicon ->", f)
			end
			return f
		end)
		.run()
	print(termicons)
end

os.exit( luaunit.LuaUnit.run() )
