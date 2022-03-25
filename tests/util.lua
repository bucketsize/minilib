#!/usr/bin/env lua

package.path = os.getenv("HOME") .. '/?.lua;'
    .. package.path

local Util = require("minilib.util")

function test_split()
	local ss
    ss = Util:split("and", "gireffe and /mnt/foo bar - 1.mp4andcamel")
    assert(#ss == 3)
    ss = Util:split("|", "gireffe | same| /mnt/foo bar - 1.mp4|camel")
    assert(#ss == 4)
end

function test_timer()
    local timer = Util.new_timer()
    local t2, t5, t8 = 0, 0, 0
    timer:tick(2, function() t2 = t2+1 end)
    timer:tick(5, function() t5 = t5+1 end)
    timer:tick(8, function() t8 = t8+1 end)
    timer:start(16)
    assert(t2 == 8)
    assert(t5 == 3)
    assert(t8 == 2)
end

function test_map()
	local r

	r = Util:map(function(n) return n*n end, {1,2,3,4})
    assert(Util:eq({1,4,9,16}, r))

	r = Util:map(function(n) return n*n end, {ein=1,dwei=2,drei=3,funf=4})
    assert(not Util:eq({1,4,9,16}, r))
    assert(Util:eq({ein=1,dwei=4,drei=9,funf=16}, r))

	r = Util:filter(function(n) return (n % 2) == 0 end, {1,2,3,4})
    assert(Util:eq({2,4}, r))

	r = Util:fold(function(n, s)
		s=s+n
		return s
	end, {1,2,3,4}, 0)
    assert(r == 10)
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
