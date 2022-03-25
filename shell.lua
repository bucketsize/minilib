local Util = require('minilib.util')
local Proc = require('minilib.process')

_HOME = os.getenv("HOME")
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

local F = {}

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
	  local l = h:read("*line")
	  if l == nil then
		 h:close()
	  end
	  return l
   end
end

function F.find(path)
    local cmd = string.format(
        "find %s -type f -exec grep -Iq . {} \\; -print",
        path)
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
        if not (path == nil) then
            if not Util:haz(skip_paths, path) then
                table.insert(paths, path)
                -- print("read next", path)
            end
        end
        if h == nil then
            h = assert(io.open(paths[p], "r"))
        end
        local l = h:read("*line")
        if l == nil then
            h:close()
            if p < #paths then
                p = p + 1
                h = assert(io.open(paths[p]))
                l = h:read("*line")
            else
                print("read ", #paths)
                return nil
            end
        end
        return {path=paths[p], line=l}
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

function F.open(path, mode)
    local h = io.open(path, mode)
    if h == nil then
        local b, d = F.split_path(path)
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
            print("write", c)
            return fline
        end
        local wpath = head_path .. "/".. fline.path
        if (h == nil) then
            -- print("write next", wpath)
            h = F.open(wpath, "w")
            p = fline.path
            c = c+1
        else
            if not (p == fline.path) then
                -- print("write next", wpath)
                h:close()
                h = F.open(wpath, "w")
                p = fline.path
                c = c+1
            end
            -- print("write cont >>", wpath)
        end
        if not (fline.line == nil) then
            h:write(fline.line)
            h:write('\n')
            -- print(wpath .. " << " .. fline.line)
        end
        return fline
    end
end

function F.grep(patt)
	return function(s)
		local r = {}
        if s == nil then
            return r
        end
		r[1],r[2],r[3],r[4],r[5],r[6],r[7],r[8],r[9],r[10] = string.match(s, patt)
		if r[1] == nil then return nil end
		return r
	end
end

function F.echo()
	return function(s)
		if type(s) == 'function' then
			print('function')
		else
			if type(s) == 'table' then
				print(listToString(s))
			else
				print(s)
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
function F.sh(cmd)
    return os.execute(cmd)
end

function F.nohup(cmd)
    return os.execute(
        string.format("nohup %s 2>&1 >> /tmp/sh.nohup.log &", cmd))
end

function F.fork(cmd)
    return os.execute(
        string.format("%s 1>&2 >> /tmp/sh.daemon.log &", cmd))
end

function F.mkdir(path)
    Util:exec(
        string.format("mkdir -pv %s", path))
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
    Util:exec(string.format("cp -vb %s %s", s, t))
end

function F.wget(url)
    Util:exec(string.format("wget %s", url))
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
    lm = "x86_64",
    BCM2835 = "aarch64" 
}
function F.arch()
    local flags = Proc.pipe()
	    .add(F.cat("/proc/cpuinfo"))
        .add(Proc.branch()
            .add(F.grep("BCM2835"))
            .add(F.grep("lm"))
            .build()
        )
        .add(Proc.cull())
        .run()
    for _,i in ipairs(flags) do
        for _,j in ipairs(i) do
            if _ARCH_FLAG[j] then
                return _ARCH_FLAG[j]
            end
        end
    end
    return "UnknownISA"
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
        -- print("trying>", p)
        if F.path_exists(p) then
            return p
        end
    end
    return nil
end

function F.file_exists(file)
    return F.__file_exists(file, _PATH)
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
        print(file .. " -> required") 
        os.exit(1)
    end
end

function F.split_path(path)
    local li  = Util:reverse(Util:segpath(path))
    local b,p = Util:head(li),
        "/"..Util:join("/", Util:reverse(Util:tail(li)))
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
