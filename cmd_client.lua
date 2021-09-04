#!/usr/bin/env lua

local socket = require("socket")

local CmdClient = {
   configure = function(self, host, port)
	  self.host = host
	  self.port = port
   end,
   send = function(self, cmd, p)
	  local client = assert(socket.tcp())
	  client:connect(self.host, self.port)
	  client:send(string.format("%s|%s\n", cmd, p))
	  local s, status, partial = client:receive('*l')
	  client:close()
	  return s, status
   end,
   sendxr = function(self, cmd, p)
	  local client = assert(socket.tcp())
	  client:connect(self.host, self.port)
	  client:send(string.format("%s|%s\n", cmd, p))
	  local s, status, partial
	  local mtab={}
	  while true do
		 s, status, partial = client:receive('*l')
		 if status == "closed" then
			break
		 end
		 table.insert(mtab, s)
	  end
	  client:close()
	  return mtab
   end
}

return CmdClient
