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
   "lua >= 5.1",
   "luasocket >= 3.0rc1-2"
}
build = {
	type = "none",
	install = {
		lua = {
			["minilib.util"] = "src/util.lua",
			["minilib.process"] = "src/process.lua",
			["minilib.shell"] = "src/shell.lua",
			["minilib.json"] = "src/json.lua",
			["minilib.otable"] = "src/otable.lua",
			["minilib.cmd_server"] = "src/cmd_server.lua",
			["minilib.cmd_client"] = "src/cmd_client.lua"
		}
	}
}
