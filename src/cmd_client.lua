#!/usr/bin/env lua

local socket = require("socket")

local CmdClient = {
   configure = function(self, host, port)
	  local tcp = assert(socket.tcp())
	  self.socket = socket
	  self.tcp = tcp
	  self.host = host
	  self.port = port
	  --print("using", self.host, self.port)
   end,
   send = function(self, cmd, p)
	  self.tcp:connect(self.host, self.port)
	  self.tcp:send(string.format("%s|%s\n", cmd, p))
	  local s, status, partial = self.tcp:receive('*l')
	  self.tcp:close()
	  return s, status
   end,
   sendxr = function(self, cmd, p)
	  self.tcp:connect(self.host, self.port)
	  self.tcp:send(string.format("%s|%s\n", cmd, p))
	  local s, status, partial
	  local mtab={}
	  while true do
		 s, status, partial = self.tcp:receive('*l')
		 if status == "closed"
		 then break
		 end
		 table.insert(mtab, s)
	  end
	  self.tcp:close()
	  return mtab
   end
}

return CmdClient
