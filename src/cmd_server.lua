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
	  print('listening on',host, port)
   end,
   handle_client = function(self, client)
	  local line, err = client:receive("*l")
	  if not err then
		 local op, oo = line:match("(%w+)|(.*)")
		 if self.Handler[op] then
			self.Handler[op](client, oo)
		 else
			print("> nil_op")
			client:send("error\n")
		 end
		 client:close()
	  end
   end,
   run_nonblocking = function(self)
	  while true do
		 local sl_r, sl_w, err = self.socket.select({self.server}, nil, 1)
		 for i, s in pairs(sl_r) do
			if type(i) == 'number' then
			   local client = s:accept()
			   self:handle_client(client)
			end
		 end
	  end
   end,
   start = function(self, host, port, handler)
	  self.Handler = handler
	  self:listen(host, port)
	  self:run_nonblocking()
   end
}

return CmdServer
