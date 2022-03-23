#!/usr/bin/env lua

package.path = os.getenv("HOME") .. '/?.lua;'
    .. package.path

local Util = require("minilib.util")

function test_split()
	local ss = Util:split("|jah { 11 | 97 | k5jk|-|+| 1 | |sk-dj|/mnt/foo bar - 1.mp4|", Util.PSV_PAT)
	Util:printITable(ss)
end

function test_timer()
    local timer = Util.new_timer()
    timer:tick(2, function() print(2) end)
    timer:tick(5, function() print(5) end)
    timer:tick(8, function() print(8) end)
    timer:start(16)
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

test_split()
test_map()
test_segpath()
test_strip()
test_timer()
