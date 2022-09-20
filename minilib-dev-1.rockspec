package = "minilib"
version = "dev-1"
source = {
   url = "."
}
description = {
   homepage = "https://github.com/bucketsize/scripts",
   license = "EULA"
}
dependencies = {
   "lua >= 5.3",
   "sha1",
   "luafilesystem",
   "luasocket >= 3.0rc1-2",
}
build = {
	type = "none",
	install = {
		lua = {
			["minilib.util"]             = "util.lua",
			["minilib.process"]          = "process.lua",
			["minilib.process_listener"] = "process_listener.lua",
			["minilib.shell"]            = "shell.lua",
			["minilib.sgrid"]            = "sgrid.lua",
			["minilib.json"]             = "json.lua",
			["minilib.cmd_server"]       = "cmd_server.lua",
			["minilib.cmd_client"]       = "cmd_client.lua"
		}
	}
}
