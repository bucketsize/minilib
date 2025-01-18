package = "minilib"
version = "dev-1"
source = {
	url = ".",
}
description = {
	homepage = "https://github.com/bucketsize/scripts",
	license = "EULA",
}
dependencies = {
	"lua >= 5.2",
	"sha1",
	"luafilesystem",
	"luasocket >= 3.0rc1-2",
	"luacov",
	"luaunit",
}
build = {
	type = "none",
	install = {
		lua = {
			["minilib.util"] = "util.lua",
			["minilib.process"] = "process.lua",
			["minilib.shell"] = "shell.lua",
			["minilib.monad"] = "monad.lua",
			["minilib.logger"] = "logger.lua",
		},
	},
}
