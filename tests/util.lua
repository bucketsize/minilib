#!/usr/bin/env lua
package.path = '?.lua;' .. package.path
require "luarocks.loader"
luaunit = require('luaunit')

local Util = require("util")

function test_split()
	local ss
    
    ss = Util:split("and", "gireffe and /mnt/foo bar - 1.mp4andcamel")
    Util:printITable(ss)
    assert(Util:eq({"gireffe "," /mnt/foo bar - 1.mp4","camel"}, ss))

    ss = Util:split("|", "gireffe | same| /mnt/foo bar - 1.mp4|camel")
    Util:printITable(ss)
    assert(Util:eq({"gireffe "," same"," /mnt/foo bar - 1.mp4","camel"}, ss))
    
    ss = Util:split(".", "gireffe . same. /mnt/foo bar - 1.mp4.camel", {regex=false})
    Util:printITable(ss)
    assert(Util:eq({"gireffe "," same"," /mnt/foo bar - 1","mp4","camel"}, ss))
end

function test_timer()
	print("test_timer, start")
    local timer = Util.new_timer()
    local t0, t1, t2, t5, t8 = 0, 0, 0, 0, 0
    timer:tick(0.1, function() t0 = t0+1 end)
    timer:tick(0.2, function() t1 = t1+1 end)
    timer:tick(2, function() t2 = t2+1 end)
    timer:tick(5, function() t5 = t5+1 end)
    timer:tick(8, function() t8 = t8+1 end)
    timer:start(16)
	print("test_timer", t0,t1,t2,t5,t8)
    assert(t0 == 10*16)
    assert(t1 == 5*16)
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
function test_find_all()
    local x, as

    x = Util:find_all("and", "this and that and something, and")
    as = {{6,8}, {15,17}, {30,32}}
    for i,j in ipairs(x) do
        assert(Util:eq(as[i], j))
    end
    
    x = Util:find_all("and", "and that the hen and the fox were friends, and...")
    as = {{1,3}, {18,20}, {44,46}}
    for i,j in ipairs(x) do
        assert(Util:eq(as[i], j))
    end
    
    x = Util:find_all("mojo", "and that the hen and the fox were friends, and...")
    assert(Util:size(x) == 0)
end

os.exit( luaunit.LuaUnit.run() )
