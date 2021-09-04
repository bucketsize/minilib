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
   "luasocket >= 3.0rc1-2"
}
build = {
	type = "none",
	install = {
		lua = {
			["minilib.util"] = "util.lua",
			["minilib.process"] = "process.lua",
			["minilib.shell"] = "shell.lua",
			["minilib.json"] = "json.lua",
			["minilib.otable"] = "otable.lua",
			["minilib.cmd_server"] = "cmd_server.lua",
			["minilib.cmd_client"] = "cmd_client.lua"
		}
	}
}
