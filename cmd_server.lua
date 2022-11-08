#!/usr/bin/env lua

local Util = require("minilib.util")
local socket = require("socket")

local CmdServer = {
	listen = function(self, host, port)
		local server = assert(socket.bind(host, port))
		local tcp = assert(socket.tcp())
		tcp:listen(10)
		self.socket = socket
		self.server = server
		print('listen',host, port)
	end,
	handle_client = function(self, client)
		local line, err = client:receive("*l")
		print("handle_client", line, err)
		if not err then
			local op, oo = line:match("(%w+)|(.*)")
			if self.Handler[op] then
				self.Handler[op](client, oo)
			else
				client:send("error\n")
			end
		end
	end,
	run_nonblocking = function(self)
		while true do
			print("run_nonblocking")
			local sl_r, sl_w, err = self.socket.select({self.server}, nil, 1)
			for i, s in pairs(sl_r) do
				if type(i) == 'number' then -- sockets are indexed by number and string:keys
					local client, err = s:accept()
					if err then
						print("-- err on accept", err)
					else
						self:handle_client(client)
						client:close()
					end
				end
			end
			coroutine.yield()
		end
	end,
	start = function(self, host, port, handler)
		self.Handler = handler
		self:listen(host, port)
	end
}

return CmdServer
