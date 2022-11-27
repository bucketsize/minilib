package.path = '?.lua;' .. package.path
require "luarocks.loader"

local lfs_ = require("lfs")
local sha1 = require("sha1")

local Util = require('minilib.util')
local Proc = require('minilib.process')
local logger = require("minilib.logger").create()

_HOME = os.getenv("HOME")
_USER = os.getenv("USER")
_DEBUG = os.getenv("DEBUG_LUA")
_PATH = {
    "/bin/",
    "/sbin/",
    "/usr/bin/",
    "/usr/sbin/",
    "/usr/local/bin/",
    "/usr/local/sbin/",
    "/opt/bin/",
    "/opt/sbin/",
    _HOME .. "/.local/bin/",
}
_LIBS = {
    "/usr/lib/pkgconfig/",
    "/usr/local/lib/pkgconfig/",
    "/opt/lib/pkgconfig/",
    "/lib/pkgconfig/"
} 

local F = {HOME=_HOME, USER=_USER}

function F.cat(path)
   local h = assert(io.open(path, 'r'))
   return function()
	  local l = nil
      if h then
          l = h:read("*line")
          if l == nil then
             h:close()
             h = nil
          end
      end
	  return l
   end
end

function F.exec(path)
	local h = assert(io.popen(path))
	return function()
		local l = nil
		if h then 
			l = h:read("*line")
			if l == nil then
				h:close()
				h = nil
			end
		end
		return l
	end
end

function F.traverse(dque, dqueptr, cb, opts)
	if not opts then
		opts = {}
	end
	local dcur = dque[dqueptr] 
	-- logger.info("traverse", dcur, dqueptr, #dque, cb)
	function readdiro(diro)
		local e = diro:next()
		if e == nil then
			diro:close()
			diro = nil
			return F.traverse(dque, dqueptr+1, cb, opts)
		else
			if e == "." or e == ".." then
				-- logger.info("readdiro, reject", dcur, e)
				return readdiro(diro)
			end
			local l = dcur .. "/" .. e
			local attrs, err = lfs_.attributes(l)
			if err then
				-- logger.info("readdiro, error", l, err)
				return readdiro(diro)
			end
			if attrs.mode == "file" then
				-- logger.info("readdiro, next", l)
				if opts.pattern then
					if l:find(opts.pattern) then
						cb(l)
					end
				else
					cb(l)
				end
				return readdiro(diro)
			else
				-- logger.info("readdiro, dque", l, attrs.mode)
				table.insert(dque, l)
				return readdiro(diro)
			end
		end
	end
	if not (dcur) then
		return nil
	end
	local ok, res = pcall(function()
		local i, d = lfs_.dir(dcur)
		return {iter = i, diro = d}
	end)
	-- logger.info("traverse, state", ok, res)
	if not ok then
		return F.traverse(dque, dqueptr+1, cb, opts)
	end
	return readdiro(res.diro)
end

function F.find(path, pattern)
	local co = nil
	return function()
		if not co then
			co = coroutine.create(function()
				F.traverse({path}, 1, function(f)
					-- logger.info("find, yield", f)
					coroutine.yield(f)
				end, {pattern=pattern})
			end)
		end
		local ok, res = coroutine.resume(co)
		if ok then
			return res
		else
			return nil
		end
	end
end
function F.__find(path, pattern)
	local cmd = ""
	if pattern == nil then
		cmd = string.format(
			"find %s -type f -exec grep -Iq . {} \\; -print",
			path)
	else
		cmd = string.format(
			"find %s -type f -name \"%s\" -exec grep -Iq . {} \\; -print",
			path, pattern)
	end
	logger.info("__find %s", cmd)
    local h = assert(io.popen(cmd))
    return function()
        if h == nil then
            return nil
        end
        local l = h:read("*line")
        if l == nil then
            h:close()
            h = nil
        end
        return l
    end
end

local skip_paths = {"git"}

function F.read()
    local h, p = nil, 1
    local paths = {}
    return function(path)
        if not (path == nil or Util:haz(skip_paths, path)) then
			table.insert(paths, path)
        end
        if h == nil and #paths > 0 then
			h = assert(io.open(paths[p], "r"))
        end
		local l = nil
		if h then
			l = h:read("*line")
			if l == nil then
				h:close()
				if p < #paths then
					p = p + 1
					h = assert(io.open(paths[p]))
					l = h:read("*line")
				else
					logger.info("read %s", #paths)
					return nil
				end
			end
		else
			return nil
		end
		if l then 
        	return {path=paths[p], line=l}
		else
			return nil
		end
    end
end

function F.sed(slist)
    return function(fline)
        if fline == nil then
            return fline
        end
        for p,sub in pairs(slist) do
            fline.line = fline.line:gsub(p, sub)
        end
        return fline
    end
end

function F.sha1sum(file)
	local h = io.open(file, "rb");
	local s = nil
	if h then 
		s = sha1.sha1(h:read("*all"))
		h:close()
	end
	return s
end

function F.open(path, mode)
    local h = io.open(path, mode)
    if h == nil then
        local b, d = F.split_path(path)
        lfs_.mkdir(d)
        h = io.open(path, mode)
    end
    return h
end

function F.write(head_path)
    local h, p = nil, nil
    local c = 0
    return function(fline)
        if fline == nil then
            logger.info("write %s", c)
            return fline
        end
        local wpath = head_path .. "/".. fline.path
        if (h == nil) then
            -- logger.info("write next", wpath)
            h = F.open(wpath, "w")
            p = fline.path
            c = c+1
        else
            if not (p == fline.path) then
                -- logger.info("write next", wpath)
                h:close()
                h = F.open(wpath, "w")
                p = fline.path
                c = c+1
            end
            -- logger.info("write cont >>", wpath)
        end
        if not (fline.line == nil) then
            h:write(fline.line)
            h:write('\n')
            -- logger.info(wpath .. " << " .. fline.line)
        end
        return fline
    end
end

function F.grep(patt)
	return function(s)
        if s == nil then
            return nil
        end
		local r = {}
		r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8],r[9],r[10] = string.match(s, patt)
		if r[1] == nil then
			return nil
		end
		return r
	end
end

function F.echo()
	local i = 0
	return function(s)
		i = i + 1
		if type(s) == 'function' then
			logger.info('function %s', i)
		else
			if type(s) == 'table' then
				logger.info('function %s %s', tostring(i), listToString(s))
			else
				logger.info('function %s %s', tostring(i), s)
			end
		end
		return s
	end
end

function F.format(patt)
	return function(s)
		return string.format(patt, s)
	end
end

function F.flat(delim)
	return function(list)
		local s = ''
		for i,v in pairs(list) do
			if i == 1 then
				s = s .. v
			else
				s = s .. delim .. v
			end
		end
		return s
	end
end

--
-- shell utils --
--
local EXEC_FORMAT={
	sh     = "sh -c '%s'",
	nohup  = "nohup %s &",
	fork   = "%s &",
	launch = "nohup setsid %s > /dev/null &"
}
function F.__exec_cb(cmd, fn)
	logger.info("__exec_cb %s", cmd)
	local h = io.popen(cmd, "r")
	for l in h:lines() do
		fn(l)
	end
	h:close()
end
function F.__exec(cmd)
	F.__exec_cb(cmd, function()end)
end
F.exec_cmd = F.__exec
function F.pgrep(s)
	local p, r, cmd = false, {}, string.format("pgrep -l %s", s)
	local h = io.popen(cmd, "r")
	for l in h:lines() do
		if l and l ~= "" then
			table.insert(r, l)
			p = true
		end
	end
	h:close()
	return p, r
end
function F.kill(pid, sig)
	if not sig then
		sig=9
	end
	F.__exec(string.format("kill -%s %s", sig, pid))
end
function F.killall(exe, sig)
	if not sig then
		sig=9
	end
	F.__exec(string.format("killall -%s %s", sig, exe))
end
function F.sh(cmd)
	F.__exec(string.format(EXEC_FORMAT["sh"], cmd))
end
function F.nohup(cmd)
	os.execute(string.format(EXEC_FORMAT["nohup"], cmd))
end
function F.fork(cmd)
	logger.info("fork %s", cmd)
	os.execute(string.format(EXEC_FORMAT["fork"], cmd))
end
function F.forkonce(exe, args)
	if not F.pgrep(exe) then
		if args then
			F.fork(string.format("%s %s", exe, args))
		else
			F.fork(exe)
		end
	else
		logger.info("forkonce, already running: %s %s", exe, args)
	end
end
function F.launch(app)
   local cmd = string.format(EXEC_FORMAT["launch"]
    , app
		:gsub("%%F", "")
		:gsub("%%f", "")
		:gsub("%%U", "")
		:gsub("%%u", ""))
	logger.info("launch %s", cmd)
   local h = assert(io.popen(cmd, "r"))
   local r = h:read("*a")
   Util.sleep(0.5) -- for some reason needed so exit can nohup process to 1
   h:close()
end

function F.test(path) 
	local h = io.open(path, "r")
	if not h then return nil end
	local s, e, ec = h:read()
	if s then return "file" end
	if e then return "dir" end
end

function F.mkdir(path)
    F.__exec(string.format("mkdir -pv %s", path))
end

function F.rm(path)
    F.__exec(string.format("rm -v %s", path))
end

function F.ln(s, t)
    F.sh(string.format([[
        s=%s
        t=%s
        [ -L $t ] && rm $t
        ln -svf $s $t
    ]], s, t))
end

function F.cp(s, t)
    F.__exec(string.format("cp -v %s %s", s, t))
end
function F.mv(s, t)
    F.__exec(string.format("mv -v %s %s", s, t))
end

function F.wget(url, name)
	if name then
	    F.__exec(string.format("wget -O %s %s", name, url))
	else
	    F.__exec(string.format("wget %s", url))
	end
end
function F.basename(path)
	local ps = Util:segpath(path)
	return ps[#ps]
end
function F.groups()
	local gs = {}
	F.__exec_cb("groups", function(c)
		if c then
			gs = Util:split(" ", c)
		end
	end)
	return gs
end
function F.github_fetch(user, repo)
    F.sh(string.format([[
        b="%s"
        r="%s"
        [ -d ~/$r ] || git clone https://github.com/$b/$r.git ~/$r
		cd ~/$r
		git pull
    ]], user, repo))
end

-- mutually exclusive CPU arch flags
_ARCH_FLAG = {
    GenuineIntel = "x86_64",
    AuthenticAMD = "x86_64",
    BCM2835 = "aarch64" 
}
function F.arch()
    local parch = "unknown-isa"
	Proc.pipe()
	    .add(F.cat("/proc/cpuinfo"))
        .add(Proc.branch()
            .add(F.grep("BCM2835"))
            .add(F.grep("GenuineIntel"))
            .add(F.grep("AuthenticAMD"))
            .build()
        )
        .add(Proc.cull())
		.add(function(list)
            if list == nil then
                return list
            end
			for i, v in pairs(list) do
				-- logger.info("arch", i, v[1])
				if v ~= nil then parch=_ARCH_FLAG[v[1]] end
			end
			return list
        end)
        .run()
	return parch
end

function F.path_exists(file)
	local h = io.open(file, "r")
	if h == nil then
		return false
	end
	h:close()
	return true
end

function F.__file_exists(file, repo)
    for i,v in ipairs(repo) do
        local p = v..file
        if F.path_exists(p) then
            return p
        end
    end
    return nil
end

function F.file_exists(f)
	if type(f) == 'table' then
		for i, j in ipairs(f) do
    		if not F.__file_exists(j, _PATH) then
				return false
			end
		end
		return true
	else
		if type(f) == 'string' then
    		return F.__file_exists(f, _PATH)
		else
			return false
		end
	end
end

function F.libs()
    table.insert(_LIBS, 
        string.format("/lib/%s-linux-gnu/pkgconfig/", F.arch()))
    return _LIBS
end

function F.lib_exists(lib)
    return F.__file_exists(lib..".pc", F.libs())
end

function F.assert_file_exists(file)
    if not F.file_exists(file) then
        logger.info("assert_file_exists, requires %s", file) 
        os.exit(1)
    end
end

function F.split_path(path)
    local pi = Util:find_all("/", path)
    if #pi == 0 then
        return path
    end
    local i  = pi[#pi]
    local b, p = 
        path:sub(i[2]+1),
        path:sub(0, i[1]-1)
    return b,p
end

function listToString(list, level)
	if level == nil then level = 1 end
	local b = ''
	local i = 1
	for k, v in pairs(list) do
		if type(v) == 'function' then
			v = 'function'
		end
		if type(v) == 'table' then
			if level < 3 then
				v = listToString(v, level+1)
			end
		end
		if i==1 then
			b = string.format('%s', v)
		else
			b = string.format('%s, %s', b, v)
		end
		i = i + 1
	end
	return b
end

return F
