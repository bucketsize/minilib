package.path = "?.lua;" .. package.path
require("luarocks.loader")

local Util = require("minilib.util")
local Proc = require("minilib.process")
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
	"/snap/bin/",
	_HOME .. "/.local/bin/",
}
_LIBS = {
	"/usr/lib/pkgconfig/",
	"/usr/local/lib/pkgconfig/",
	"/opt/lib/pkgconfig/",
	"/lib/pkgconfig/",
}

local F = { HOME = _HOME, USER = _USER }
local S = { HOME = _HOME, USER = _USER }

function F.cat(path)
	local h = assert(io.open(path, "r"))
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
			end
		end
		return l
	end
end

function F.find(path, pattern)
	local co = nil
	return function()
		if not co then
			co = coroutine.create(function()
				F.traverse({ path }, 1, function(f)
					-- logger.info("find, yield", f)
					coroutine.yield(f)
				end, { pattern = pattern })
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
		cmd = string.format("find %s -type f -exec grep -Iq . {} \\; -print", path)
	else
		cmd = string.format('find %s -type f -name "%s" -exec grep -Iq . {} \\; -print', path, pattern)
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

local skip_paths = { "git" }

function F.read()
	local h, p = nil, 1
	local paths = {}
	return function(path)
		if not (path == nil or Util.haz(skip_paths, path)) then
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
			return { path = paths[p], line = l }
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
		for p, sub in pairs(slist) do
			fline.line = fline.line:gsub(p, sub)
		end
		return fline
	end
end

function F.sha1sum(file)
	local s, e, ls = S.__exec("sha1sum < " .. file)
	return ls[1]
end

function F.open(path, mode)
	local h = io.open(path, mode)
	if h == nil then
		local _, d = F.split_path(path)
		F.mkdir(d)
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
		local wpath = head_path .. "/" .. fline.path
		if h == nil then
			-- logger.info("write next", wpath)
			h = F.open(wpath, "w")
			p = fline.path
			c = c + 1
		else
			if not (p == fline.path) then
				-- logger.info("write next", wpath)
				h:close()
				h = F.open(wpath, "w")
				p = fline.path
				c = c + 1
			end
			-- logger.info("write cont >>", wpath)
		end
		if not (fline.line == nil) then
			h:write(fline.line)
			h:write("\n")
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
		r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10] = string.match(s, patt)
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
		if type(s) == "function" then
			print("fun", i)
		elseif type(s) == "table" then
			print("tab", i, s)
		else
			print("str", i, s)
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
		local s = ""
		for i, v in pairs(list) do
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
local EXEC_FORMAT = {
	sh = "sh -c '%s'",
	nohup = "nohup %s &",
	fork = "%s &",
	launch = "nohup setsid %s > /dev/null &",
}
function S.__exec_cb(cmd, fn)
	logger.debug("__exec_cb %s", cmd)
	local h, e = assert(io.popen(cmd, "r"))
	for l in h:lines() do
		fn(l)
	end
	h:close()
	if e then
		return false, e
	else
		return true
	end
end
function S.__exec(cmd)
	local ls = {}
	local s, e = S.__exec_cb(cmd, function(l)
		table.insert(ls, l)
	end)
	return s, e, ls
end
S.exec_cmd = S.__exec
function S.pgrep(s)
	if s == nil or s == "" then
		return false
	end
	local p, r, cmd = false, {}, string.format("pgrep -l %s", s)
	local h = assert(io.popen(cmd, "r"))
	for l in h:lines() do
		if l and l ~= "" then
			table.insert(r, l)
			p = true
		end
	end
	h:close()
	return p, r
end
function S.kill(pid, sig)
	if not sig then
		sig = 9
	end
	S.__exec(string.format("kill -%s %s", sig, pid))
end
function S.killall(exe, sig)
	if not sig then
		sig = 9
	end
	S.__exec(string.format("killall -%s %s", sig, exe))
end
function S.sh(cmd)
	return S.__exec(string.format(EXEC_FORMAT["sh"], cmd))
end
function S.nohup(cmd)
	logger.debug("nohup %s", cmd)
	os.execute(string.format(EXEC_FORMAT["nohup"], cmd))
end
function S.fork(cmd)
	logger.debug("fork %s", cmd)
	os.execute(string.format(EXEC_FORMAT["fork"], cmd))
end
function S.forkonce(exe, args)
	if not S.pgrep(exe) then
		if args then
			S.fork(string.format("%s %s", exe, args))
		else
			S.fork(exe)
		end
	else
		logger.info("forkonce, already running: %s %s", exe, args)
	end
end
function S.launch(app)
	local cmd =
		string.format(EXEC_FORMAT["launch"], app:gsub("%%F", ""):gsub("%%f", ""):gsub("%%U", ""):gsub("%%u", ""))
	logger.info("launch %s", cmd)
	local h = assert(io.popen(cmd, "r"))
	local r = h:read("*a")
	logger.info(r)
	h:close()
end
function S.expand(p)
	return p:gsub("~", _HOME)
end
function S.test(path)
	local h = io.open(path, "r")
	if not h then
		return nil
	end
	local s, e, ec = h:read()
	if s then
		return "file"
	end
	if e then
		return "dir"
	end
end

function S.mkdir(path)
	S.__exec(string.format("mkdir -pv %s", path))
end

function S.rm(path)
	S.__exec(string.format("rm -v %s", path))
end

function S.ln(s, t)
	S.sh(string.format(
		[[
        s=%s
        t=%s
        r=$(date +"%%s")
        [ -d $t ] && mv -v $t $t.$r 
        [ -L $t ] && mv -v $t $t.$r
        [ -f $t ] && mv -v $t $t.$r
        ln -svf $s $t
    ]],
		s,
		t
	))
end

function S.cp(s, t)
	S.__exec(string.format("cp -v %s %s", s, t))
end
function S.mv(s, t)
	S.__exec(string.format("mv -v %s %s", s, t))
end
function S.append(s, f)
	local h = assert(io.open(S.expand(f), "a"))
	h:write("\n")
	h:write(s)
	h:close()
end
function S.wget(url, name)
	print("#curl", url, name)
	if name then
		S.__exec(string.format('curl -o %s  -kL "%s"', name, url))
	else
		S.__exec(string.format('curl -OkL "%s"', url))
	end
end
function S.basename(path)
	local ps = Util.segpath(path)
	return ps[#ps]
end
function S.groups()
	local gs = {}
	S.__exec_cb("groups", function(c)
		if c then
			gs = Util.split(" ", c)
		end
	end)
	return gs
end
function S.github_fetch(user, repo)
	S.sh(string.format(
		[[
        b="%s"
        r="%s"
        [ -d ~/$r ] || git clone https://github.com/$b/$r.git ~/$r
    cd ~/$r
    git pull
    ]],
		user,
		repo
	))
end

-- mutually exclusive CPU arch flags
_ARCH_FLAG = {
	GenuineIntel = "x86_64",
	AuthenticAMD = "x86_64",
	BCM2835 = "aarch64",
}
function S.arch()
	local parch = "unknown-isa"
	Proc.pipe()
		.add(F.cat("/proc/cpuinfo"))
		.add(Proc.branch().add(F.grep("BCM2835")).add(F.grep("GenuineIntel")).add(F.grep("AuthenticAMD")).build())
		.add(Proc.cull())
		.add(function(list)
			if list == nil then
				return list
			end
			for i, v in pairs(list) do
				-- logger.info("arch", i, v[1])
				if v ~= nil then
					parch = _ARCH_FLAG[v[1]]
				end
			end
			return list
		end)
		.run()
	return parch
end
function S.lsb_release()
	local parch = { distro = "unknown" }
	local extfn = nil
	if S.path_exists("/etc/os-release") then
		extfn = Proc
			.pipe()
			.add(F.cat("/etc/os-release"))
			.add(F.echo())
			-- NAME="Fedora Linux"
			-- VERSION="40 (Sway)"
			-- ID=fedora
			-- VERSION_ID=40
			-- VERSION_CODENAME=""
			.add(
				Proc.branch()
					.add(F.grep("^ID=(.+)"))
					.add(F.grep("PRETTY_NAME=(.+)"))
					.add(F.grep("VERSION_ID=(.+)"))
					.add(F.grep("VERSION_CODEAME=(.+)"))
					.build()
			)
	else
		extfn = Proc
			.pipe()
			.add(F.exec("lsb_release -a"))
			.add(F.echo())
			-- Distributor ID: Debian
			-- Description:    Debian GNU/Linux 12 (bookworm)
			-- Release:        12
			-- Codename:       bookworm
			.add(
				Proc.branch()
					.add(F.grep("Distributor ID:%s+(.+)"))
					.add(F.grep("Description:%s+(.+)"))
					.add(F.grep("Release:%s+(.+)"))
					.add(F.grep("Codename:%s+(.+)"))
					.build()
			)
	end

	extfn
		.add(Proc.cull())
		.add(function(list)
			if list == nil then
				return list
			end
			for i, v in pairs(list) do
				print("lsb_release>", i, v[1]:lower())
				if v ~= nil then
					if i == 1 then
						parch = { distro = v[1]:lower() }
					end
				end
			end
			return list
		end)
		.run()
	return parch
end

function S.path_exists(file)
	local h = io.open(file, "r")
	if h == nil then
		return false, file
	end
	h:close()
	return true, file
end

function S.__file_exists(file, repo)
	for _, v in ipairs(repo) do
		local p = v .. file
		if S.path_exists(p) then
			return true, p
		end
	end
	return false, file
end

function S.file_exists(f)
	if type(f) == "table" then
		for _, j in ipairs(f) do
			if not S.__file_exists(j, _PATH) then
				return false, f
			end
		end
		return true, f
	else
		if type(f) == "string" then
			return S.__file_exists(f, _PATH)
		else
			return false, f
		end
	end
end

function S.libs()
	table.insert(_LIBS, string.format("/lib/%s-linux-gnu/pkgconfig/", F.arch()))
	return _LIBS
end

function S.lib_exists(lib)
	return S.__file_exists(lib .. ".pc", F.libs())
end

function S.assert_file_exists(file)
	if not S.file_exists(file) then
		logger.info("assert_file_exists, requires %s", file)
		os.exit(1)
	end
end

function S.split_path(path)
	local pi = Util.find_all("/", path)
	if #pi == 0 then
		return path
	end
	local i = pi[#pi]
	local b, p = path:sub(i[2] + 1), path:sub(0, i[1] - 1)
	return b, p
end

F.util = S

return F
