#!/usr/bin/env lua
package.path = '?.lua;' .. package.path
require "luarocks.loader"
luaunit = require('luaunit')

local log = require("logger").create()

function test_logger()
	log:info("howdy ... %s", 22, "!")
end

function test_logger_file()
	log:sink("/tmp/minilogger.log")
	log:info("howdy ... %s - %s", 55, "!")
end

os.exit( luaunit.LuaUnit.run() )
