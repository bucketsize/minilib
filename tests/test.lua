#!/usr/bin/env lua

package.path = os.getenv("HOME") .. '/?.lua;'
    .. package.path

local Pr = require("minilib.process")
local Sh = require("minilib.shell")
local Util = require("minilib.util")
-- local Notifeir = require("minilib.notifeir")

function test_pipe()
	local m1,m2
	local r = Pr.pipe()
		.add(Sh.cat('/proc/meminfo'))
		.add(Pr.branch()
			.add(Sh.grep('MemFree'))
			.add(Sh.grep('SwapFree'))
			.build())
		.add(Pr.cull())
		.add(function(list)
            if list == nil then
                return list
            end
			for i,v in pairs(list) do
				if (i == 1) then m1=v end
				if (i == 2) then m2=v end
			end
			return list
		end)
		.add(Sh.echo())
		.run(true)
end

function test_pipe2()
	local m1,m2
	local r = Pr.pipe()
		.add(Sh.exec('lspci'))
		.add(Pr.branch()
			.add(Sh.grep('VGA.*'))
			.add(Sh.grep('Audio.*'))
			.build())
		.add(Pr.cull())
		.add(function(list)
            if list == nil then
                return list
            end
			for i,v in pairs(list) do
				if (i == 1) then m1=v end
				if (i == 2) then m2=v end
			end
			return list
		end)
		.add(Sh.echo())
		.run()
end

function test_cat()
	local cat = Sh.cat('/proc/meminfo')
	print(type(cat))

	p = cat()
	print(p)

	p = cat()
	print(p)
end

function test_listToString()
	local a = {A=123, b=45}
	print(listToString(a))
end

function test_split()
	local ss = Util:split("|jah { 11 | 97 | k5jk|-|+| 1 | |sk-dj|/mnt/foo bar - 1.mp4|", Util.PSV_PAT)
	Util:printITable(ss)
end

function test_timer()
   Util.Timer:tick(2, function() print(2) end)
   Util.Timer:tick(5, function() print(5) end)
   Util.Timer:tick(8, function() print(8) end)
   Util.Timer:start()
end

function test_map()
	local r

	r = Util:map(function(n) return n*n end, {1,2,3,4})
	print(r)
	Util:printOTable(r)

	r = Util:map(function(n) return n*n end, {one=1,twe=2,tri=3,fuf=4})
	print(r)
	Util:printOTable(r)

	r = Util:filter(function(n) return (n % 2) == 0 end, {1,2,3,4})
	print(r)
	Util:printOTable(r)

	r = Util:fold(function(n, s)
		s=s+n
		return s
	end, {1,2,3,4}, 0)
	print(r)
end

function test_segpath()
   local ts = {"/var/tmp/foo/bar.egg", "fry.egg", "./goto.egg", "//more.egg", "fifa/la/kase.egg"}
   for i, v in ipairs(ts) do
	  print("test_segpath", i, v)
	  local ps = Util:segpath(v)
	  Util:printITable(Util:reverse(ps))
	  print(ps[#ps])
   end
end
function test_strip()
	print(string.format("|%s|", Util:strip("   lo i am a doctor 	")))
	print(string.format("|%s|", Util:strip("    	der maus speilt nie klavier   ")))
end
function test_notifeir()
    Notifeir:notify("test", "gotcja!")
end
function test_listener()
    Pr.new_listener()("pi", "less", function()
        Util:exec("weston-flower")
    end)
end
function test_arch()
    print("system architecture:", Sh.arch())
end

test_cat()
test_split()
test_map()
test_listToString()
test_segpath()
test_strip()
test_pipe()
test_pipe2()
-- test_notifeir()
-- test_timer()
-- test_listener()
test_arch()

