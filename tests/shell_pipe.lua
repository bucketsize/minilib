#!/usr/bin/env lua
package.path = '?.lua;' .. package.path
require "luarocks.loader"
luaunit = require('luaunit')

local Pr = require("process")
local Sh = require("shell")
local Util = require("util")

function test_arch()
    print("system architecture:", Sh.arch())
end

function test_cat()
	local cat = Sh.cat('/proc/meminfo')
	print(type(cat))
	assert(cat())
	assert(cat())
end

function test_pipe_1()
	local m1,m2
	local r = Pr.pipe()
		.add(Sh.cat('/proc/meminfo'))
		.add(Pr.branch()
			.add(Sh.grep('Buffers'))
			.add(Sh.grep('Cached'))
			.build())
		.add(Pr.cull())
		.add(function(list)
            if list == nil then
                return list
            end
			for i,v in pairs(list) do
				if (i == 1) then m1=v[1] end
				if (i == 2) then m2=v[1] end
			end
			return list
        end)
		.run()
    assert(m1)
    print(m1)
    assert(m2)
    print(m2)
end

function test_pipe_2()
	local m1,m2
	local r = Pr.pipe()
		.add(Sh.exec('lscpu'))
		.add(Pr.branch()
			.add(Sh.grep('Architecture.*'))
			.add(Sh.grep('Flags.*'))
			.build())
		.add(Pr.cull())
		.add(function(list)
            if list == nil then
                return list
            end
			for i,v in pairs(list) do
				if (i == 1) then m1=v[1] end
				if (i == 2) then m2=v[1] end
			end
			return list
		end)
		.run()
    assert(m1)
    print(m1)
    assert(m2)
    print(m2)
end

function test_pipe_3()
	local iv = Pr.pipe()
		.add(Sh.exec('pactl list sinks'))
		.add(Sh.grep('Name.*'))
		.add(Sh.echo())
		.run()
	assert(#iv > 0)
end

os.exit( luaunit.LuaUnit.run() )
