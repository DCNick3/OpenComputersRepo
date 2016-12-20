local component = require("component")
local internet = require("internet")
local internet_raw = component.internet
local filesystem = require("filesystem")

-- Some hack for debugging 
-- package.loaded.tar = nil

local var_dump = (function()
 local function string(o)
     return '"' .. tostring(o) .. '"'
 end

 local function recurse(o, indent)
     if indent == nil then indent = '' end
     local indent2 = indent .. '  '
     if type(o) == 'table' then
         local s = indent .. '{' .. '\n'
         local first = true
         for k,v in pairs(o) do
             if first == false then s = s .. ', \n' end
             if type(k) ~= 'number' then k = string(k) end
             s = s .. indent2 .. '[' .. k .. '] = ' .. recurse(v, indent2)
             first = false
         end
         return s .. '\n' .. indent .. '}'
     else
         return string(o)
     end
 end

 local function var_dump(...)
     local args = {...}
     if #args > 1 then
         var_dump(args)
     else
         print(recurse(args[1]))
     end
 end
 return var_dump
end)()
local serprint = (
function()
 local n, v = "serpent", 0.285 -- (C) 2012-15 Paul Kulchenko; MIT License
 local c, d = "Paul Kulchenko", "Lua serializer and pretty printer"
 local snum = {[tostring(1/0)]='1/0 --[[math.huge]]',[tostring(-1/0)]='-1/0 --[[-math.huge]]',[tostring(0/0)]='0/0'}
 local badtype = {thread = true, userdata = true, cdata = true}
 local getmetatable = debug and debug.getmetatable or getmetatable
 local keyword, globals, G = {}, {}, (_G or _ENV)
 for _,k in ipairs({'and', 'break', 'do', 'else', 'elseif', 'end', 'false',
   'for', 'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
   'return', 'then', 'true', 'until', 'while'}) do keyword[k] = true end
 for k,v in pairs(G) do globals[v] = k end -- build func to name mapping
 for _,g in ipairs({'coroutine', 'debug', 'io', 'math', 'string', 'table', 'os'}) do
   for k,v in pairs(type(G[g]) == 'table' and G[g] or {}) do globals[v] = g..'.'..k end end

 local function s(t, opts)
   local name, indent, fatal, maxnum = opts.name, opts.indent, opts.fatal, opts.maxnum
   local sparse, custom, huge = opts.sparse, opts.custom, not opts.nohuge
   local space, maxl = (opts.compact and '' or ' '), (opts.maxlevel or math.huge)
   local iname, comm = '_'..(name or ''), opts.comment and (tonumber(opts.comment) or math.huge)
   local numformat = opts.numformat or "%.17g"
   local seen, sref, syms, symn = {}, {'local '..iname..'={}'}, {}, 0
   local function gensym(val) return '_'..(tostring(tostring(val)):gsub("[^%w]",""):gsub("(%d%w+)",
     -- tostring(val) is needed because __tostring may return a non-string value
     function(s) if not syms[s] then symn = symn+1; syms[s] = symn end return tostring(syms[s]) end)) end
   local function safestr(s) return type(s) == "number" and tostring(huge and snum[tostring(s)] or numformat:format(s))
     or type(s) ~= "string" and tostring(s) -- escape NEWLINE/010 and EOF/026
     or ("%q"):format(s):gsub("\010","n"):gsub("\026","\\026") end
   local function comment(s,l) return comm and (l or 0) < comm and ' --[['..select(2, pcall(tostring, s))..']]' or '' end
   local function globerr(s,l) return globals[s] and globals[s]..comment(s,l) or not fatal
     and safestr(select(2, pcall(tostring, s))) or error("Can't serialize "..tostring(s)) end
   local function safename(path, name) -- generates foo.bar, foo[3], or foo['b a r']
     local n = name == nil and '' or name
     local plain = type(n) == "string" and n:match("^[%l%u_][%w_]*$") and not keyword[n]
     local safe = plain and n or '['..safestr(n)..']'
     return (path or '')..(plain and path and '.' or '')..safe, safe end
   local alphanumsort = type(opts.sortkeys) == 'function' and opts.sortkeys or function(k, o, n) -- k=keys, o=originaltable, n=padding
     local maxn, to = tonumber(n) or 12, {number = 'a', string = 'b'}
     local function padnum(d) return ("%0"..tostring(maxn).."d"):format(tonumber(d)) end
     table.sort(k, function(a,b)
       -- sort numeric keys first: k[key] is not nil for numerical keys
       return (k[a] ~= nil and 0 or to[type(a)] or 'z')..(tostring(a):gsub("%d+",padnum))
            < (k[b] ~= nil and 0 or to[type(b)] or 'z')..(tostring(b):gsub("%d+",padnum)) end) end
   local function val2str(t, name, indent, insref, path, plainindex, level)
     local ttype, level, mt = type(t), (level or 0), getmetatable(t)
     local spath, sname = safename(path, name)
     local tag = plainindex and
       ((type(name) == "number") and '' or name..space..'='..space) or
       (name ~= nil and sname..space..'='..space or '')
     if seen[t] then -- already seen this element
       sref[#sref+1] = spath..space..'='..space..seen[t]
       return tag..'nil'..comment('ref', level) end
     -- protect from those cases where __tostring may fail
     if type(mt) == 'table' and pcall(function() return mt.__tostring and mt.__tostring(t) end)
     and (mt.__serialize or mt.__tostring) then -- knows how to serialize itself
       seen[t] = insref or spath
       if mt.__serialize then t = mt.__serialize(t) else t = tostring(t) end
       ttype = type(t) end -- new value falls through to be serialized
     if ttype == "table" then
       if level >= maxl then return tag..'{}'..comment('max', level) end
       seen[t] = insref or spath
       if next(t) == nil then return tag..'{}'..comment(t, level) end -- table empty
       local maxn, o, out = math.min(#t, maxnum or #t), {}, {}
       for key = 1, maxn do o[key] = key end
       if not maxnum or #o < maxnum then
         local n = #o -- n = n + 1; o[n] is much faster than o[#o+1] on large tables
         for key in pairs(t) do if o[key] ~= key then n = n + 1; o[n] = key end end end
       if maxnum and #o > maxnum then o[maxnum+1] = nil end
       if opts.sortkeys and #o > maxn then alphanumsort(o, t, opts.sortkeys) end
       local sparse = sparse and #o > maxn -- disable sparsness if only numeric keys (shorter output)
       for n, key in ipairs(o) do
         local value, ktype, plainindex = t[key], type(key), n <= maxn and not sparse
         if opts.valignore and opts.valignore[value] -- skip ignored values; do nothing
         or opts.keyallow and not opts.keyallow[key]
         or opts.keyignore and opts.keyignore[key]
         or opts.valtypeignore and opts.valtypeignore[type(value)] -- skipping ignored value types
         or sparse and value == nil then -- skipping nils; do nothing
         elseif ktype == 'table' or ktype == 'function' or badtype[ktype] then
           if not seen[key] and not globals[key] then
             sref[#sref+1] = 'placeholder'
             local sname = safename(iname, gensym(key)) -- iname is table for local variables
             sref[#sref] = val2str(key,sname,indent,sname,iname,true) end
           sref[#sref+1] = 'placeholder'
           local path = seen[t]..'['..tostring(seen[key] or globals[key] or gensym(key))..']'
           sref[#sref] = path..space..'='..space..tostring(seen[value] or val2str(value,nil,indent,path))
         else
           out[#out+1] = val2str(value,key,indent,insref,seen[t],plainindex,level+1)
         end
       end
       local prefix = string.rep(indent or '', level)
       local head = indent and '{\n'..prefix..indent or '{'
       local body = table.concat(out, ','..(indent and '\n'..prefix..indent or space))
       local tail = indent and "\n"..prefix..'}' or '}'
       return (custom and custom(tag,head,body,tail) or tag..head..body..tail)..comment(t, level)
     elseif badtype[ttype] then
       seen[t] = insref or spath
       return tag..globerr(t, level)
     elseif ttype == 'function' then
       seen[t] = insref or spath
       local ok, res = pcall(string.dump, t)
       local func = ok and ((opts.nocode and "function() --[[..skipped..]] end" or
         "((loadstring or load)("..safestr(res)..",'@serialized'))")..comment(t, level))
       return tag..(func or globerr(t, level))
     else return tag..safestr(t) end -- handle all other types
   end
   local sepr = indent and "\n" or ";"..space
   local body = val2str(t, name, indent) -- this call also populates sref
   local tail = #sref>1 and table.concat(sref, sepr)..sepr or ''
   local warn = opts.comment and #sref>1 and space.."--[[incomplete output with shared/self-references skipped]]" or ''
   return not name and body..warn or "do local "..body..sepr..tail.."return "..name..sepr.."end"
 end

 local function deserialize(data, opts)
   local env = (opts and opts.safe == false) and G
     or setmetatable({}, {
         __index = function(t,k) return t end,
         __call = function(t,...) error("cannot call functions") end
       })
   local f, res = (loadstring or load)('return '..data, nil, nil, env)
   if not f then f, res = (loadstring or load)(data, nil, nil, env) end
   if not f then return f, res end
   if setfenv then setfenv(f, env) end
   return pcall(f)
 end

 local function merge(a, b) if b then for k,v in pairs(b) do a[k] = v end end; return a; end
 return { _NAME = n, _COPYRIGHT = c, _DESCRIPTION = d, _VERSION = v, serialize = s,
   load = deserialize,
   dump = function(a, opts) return s(a, merge({name = '_', compact = true, sparse = true}, opts)) end,
   line = function(a, opts) return s(a, merge({sortkeys = true, comment = true}, opts)) end,
   block = function(a, opts) return s(a, merge({indent = '  ', sortkeys = true, comment = true}, opts)) end }
end )()
local tar = (function()
--- A pure-Lua implementation of untar (unpacking .tar archives)
local tar = {}


local var_dump = require("var_dump")

-- local fs = require("luarocks.fs")
-- local dir = require("luarocks.dir")
-- local util = require("luarocks.util")
local filesystem = require("filesystem")

local blocksize = 512

local function create_directories(file)
 local p = filesystem.path(filesystem.canonical(file))
 if not filesystem.exists(p) then
  create_directories(p)
  local res, err = filesystem.makeDirectory(p)
  if not res then error(err) end
 end
end

local function get_typeflag(flag)
 if flag == "0" or flag == "\0" then return "file"
 elseif flag == "1" then return "link"
 elseif flag == "2" then return "symlink" -- "reserved" in POSIX, "symlink" in GNU
 elseif flag == "3" then return "character"
 elseif flag == "4" then return "block"
 elseif flag == "5" then return "directory"
 elseif flag == "6" then return "fifo"
 elseif flag == "7" then return "contiguous" -- "reserved" in POSIX, "contiguous" in GNU
 elseif flag == "x" then return "next file"
 elseif flag == "g" then return "global extended header"
 elseif flag == "L" then return "long name"
 elseif flag == "K" then return "long link name"
 end
 return "unknown"
end

local function octal_to_number(octal)
 local exp = 0
 local number = 0
 for i = #octal,1,-1 do
  local digit = tonumber(octal:sub(i,i)) 
  if digit then
   number = number + (digit * 8^exp)
   exp = exp + 1
  end
 end
 return number
end

local function checksum_header(block)
 local sum = 256
 for i = 1,148 do
  --print(block:byte(i))
  sum = sum + block:byte(i)
 end
 for i = 157,500 do
  sum = sum + block:byte(i)
 end
 return sum
end

local function nullterm(s)
 return s:match("^[^%z]*")
end

local function read_header_block(block)
 local header = {}
 header.name = nullterm(block:sub(1,100))
 header.mode = nullterm(block:sub(101,108))
 header.uid = octal_to_number(nullterm(block:sub(109,116)))
 header.gid = octal_to_number(nullterm(block:sub(117,124)))
 header.size = octal_to_number(nullterm(block:sub(125,136)))
 header.mtime = octal_to_number(nullterm(block:sub(137,148)))
 header.chksum = octal_to_number(nullterm(block:sub(149,156)))
 header.typeflag = get_typeflag(block:sub(157,157))
 header.linkname = nullterm(block:sub(158,257))
 header.magic = block:sub(258,263)
 header.version = block:sub(264,265)
 header.uname = nullterm(block:sub(266,297))
 header.gname = nullterm(block:sub(298,329))
 header.devmajor = octal_to_number(nullterm(block:sub(330,337)))
 header.devminor = octal_to_number(nullterm(block:sub(338,345)))
 header.prefix = block:sub(346,500)
 if header.magic ~= "ustar " and header.magic ~= "ustar\0" then
  error("Invalid header magic "..header.magic)
 end
 if header.version ~= "00" and header.version ~= " \0" then
  error("Unknown version "..header.version)
 end
 if not checksum_header(block) == header.chksum then
  error("Failed header checksum")
 end
 return header
end

-- 0 - extract, 1 - list, 2 - memory extract
local function tar_do(filename, destdir, mode, files, dfiles)

 local tar_handle = io.open(filename, "rb")
 if not tar_handle then error("Error opening file "..filename) end
 
 local long_name, long_link_name
 local list = {}
 while true do
  local block
  repeat 
   block = tar_handle:read(blocksize)
  until (not block) or checksum_header(block) > 256
  if not block then break end
  local header, err = read_header_block(block)
  if not header then
   util.printerr(err)
  end

  local file_data = tar_handle:read(math.ceil(header.size / blocksize) * blocksize):sub(1,header.size)

  if header.typeflag == "long name" then
   long_name = nullterm(file_data)
  elseif header.typeflag == "long link name" then
   long_link_name = nullterm(file_data)
  else
   if long_name then
    header.name = long_name
    long_name = nil
   end
   if long_link_name then
    header.name = long_link_name
    long_link_name = nil
   end
  end
  if mode == 0 or mode == 2 then
   if files == nil or files[header.name] ~= nil then
    if mode == 0 then
     local pathname 
     if dfiles ~= nil then
      pathname = filesystem.concat(destdir, dfiles[header.name] or header.name)
     else
      pathname = filesystem.concat(destdir, header.name)
     end
     if header.typeflag == "directory" and not filesystem.exists(pathname) then
      local ok, err = filesystem.makeDirectory(pathname)
      if not ok then error(err) end
     elseif header.typeflag == "file" then
      create_directories(pathname)
      local file_handle = io.open(pathname, "wb")
      file_handle:write(file_data)
      file_handle:close()
     else
      print("Could not extract "..tostring(pathname).." which is "..tostring(header.typeflag));
     end
    else
     list[header.name] = file_data
    end
   end
  else
   list[header.name] = header.typeflag;
  end
 end
 tar_handle:close()
 if mode == 1 or mode == 2 then
     return list
 end
end

function tar.untar(filename, destdir)
   assert(type(filename) == "string")
   assert(type(destdir) == "string")
   return pcall(tar_do, filename, destdir, 0);
end

function tar.list(filename)
 assert(type(filename) == "string")
 return pcall(tar_do, filename, nil, 1);
end

function tar.extract_files(filename, destdir, ...)
 assert(type(filename) == "string")
 assert(type(destdir) == "string")
 local arr = {}
 for _,v in ipairs({...}) do
  arr[v] = true;
 end
 return pcall(tar_do, filename, destdir, 0, arr);
end

function tar.file_content(filename, name)
 assert(type(filename) == "string")
 local arr = {}
 arr[name] = true
 local r, a = pcall(tar_do, filename, nil, 2, arr)
 if not r then
  return r,a
 else
  for _,v in pairs(a) do
   return r,v
  end
 end
end

function tar.extract_file(filename, destname, name)
 assert(type(filename) == "string")
 local arr = {}
 arr[name] = true
 local arr2 = {}
 arr2[name] = destname
 return pcall(tar_do, filename, "", 0, arr, arr2);
end


return tar
end)()

local address = "https://github.com/DCNick3/OpenComputersRepo/raw/master/"
local index_name = "index.lua"
local base_dir = "/etc/packet_manager/"
local packages_list = "packages.list"
local installed_list = "installed.list"
local temp_dir = "/tmp/"
local manifest_name = "package_manifest.lua"



local packet_manager = {}

local function contains(a,b)
 for _,v in pairs(a) do
  if v == b then
   return true
  end
 end
 return false
end

local function create_directories(file)
 local p = filesystem.path(filesystem.canonical(file))
 print(p)
 if not filesystem.exists(p) then
  create_directories(p)
  local res, err = filesystem.makeDirectory(p)
  if not res then error(err) end
 end
end

local function download_to_file(address, file)
 print("Downloading "..address)

 local req = internet_raw.request(address)
 
 local buf = req.read()
 if buf == nil then
     error("Request error!");
 end
 local file_handle = io.open(file, "wb")
 
 while  buf ~= nil do
  file_handle:write(buf)
  
  buf = req.read()
 end
 file_handle:close()
end

local function rm(name)
 return filesystem.remove(name)
end

local function parse_package_string(str)
 local name = string.match(str, "([a-zA-Z-_0-9]+)-[0-9.]+")
 local version = string.match(str, "[a-zA-Z-_0-9]+-([0-9.]+)")
 return name, version
end


local function load_installed(self)
 local err, res = pcall(function() return dofile(base_dir..installed_list) end)
 if not err then
  -- DB Is corrupted!!
 else
  self.installed = res
 end
end
local function save_installed(self)
 local ser = serprint.dump(self.installed)
 local f = io.open(base_dir..installed_list, "wb")
 f:write(ser)
 f:close()
end

local function db_installed_add(self, package_string, files)
 self.installed[package_string] = files
 save_installed(self)
end

local function db_is_installed(self, package_string, match_version)
 if match_version == nil then match_version = false end
 local name, version = parse_package_string(package_string)
 for k,_ in pairs(self.installed) do
  if match_version then
   if k == package_string then return true end
  else
   local n, v = parse_package_string(k)
   if n == name then return true, v end
  end
 end
 return false
end

local function get_level1_deps(self, package_string)
 local name, version = parse_package_string(package_string)
 local p = self:packages()[name]
 if p == nil then
  error("Could not find package "..package_string)
 end
 return p.dependencies[version]
end

local function raw_install(self, fname, package_string)
 local res, files = tar.list(fname)
 local fls = {}
 if not res then error("Could not install: "..tostring(files)) end
 if not files[manifest_name] then
  rm(fname)
  error("Bad package file (no manifest)")
 else
  local res, content = tar.file_content(fname, manifest_name)
  if not res then error("Could not install: "..tostring(content)) end
  local mani_func = load(content)
  local res, manifest = pcall(mani_func)
  if res then
   if type(manifest.files) == "table" then
    if manifest.pre ~= nil then
     manifest:pre(fname, tar)
    end
    for k,v in pairs(manifest.files) do 
     print(k.." -> "..v)
     tar.extract_file(fname, v, k)
     table.insert(fls, v)
    end
    if manifest.post ~= nil then
     manifest:post(fname, tar)
    end
   end
  else
   print("Error loading manifest: "..manifest)
  end
 end
 db_installed_add(self, package_string, fls)
end

local function get_deps_tree_recursion(self, package_string, res, seen)
 --local name, version = parse_package_string(package_string)
 table.insert(seen, package_string)
 for _,v in ipairs(get_level1_deps(self, package_string)) do
  if not contains(res, v) and not db_is_installed(self, v) then
   if contains(seen, v) then
    error("Circular dependecy")
   else
    get_deps_tree_recursion(self, v, res, seen)
   end
  end
 end
 table.insert(res, package_string)
end

function packet_manager.init(self)
 if not filesystem.exists(base_dir) then
  filesystem.makeDirectory(base_dir)
 end
 if not filesystem.exists(temp_dir) then
  filesystem.makeDirectory(temp_dir)
 end
 if not filesystem.exists(base_dir..installed_list) then
  local f = io.open(base_dir..installed_list, "wb")
  f:write("return {}")
  f:close()
 end
 load_installed(self)
end

function packet_manager.update(self)
 download_to_file("https://github.com/DCNick3/OpenComputersRepo/raw/master/"..index_name, base_dir..packages_list)
 local err, res = pcall(function() return dofile(base_dir..packages_list) end)
 if err then
  self.packages_table = res
 else
  error("could not update packages: "..res)
 end
 --var_dump(index_func())
end

function packet_manager.packages(self)
 if self.packages_table ~= nil then
  return self.packages_table
 end
 if not filesystem.exists(base_dir..packages_list) then
  self:update()
  return self.packages_table
 else
  local err, res = pcall(function() return dofile(base_dir..packages_list) end)
  if not err then
   self:update()
   return self.packages_table
  else
   self.packages_table = res
   return self.packages_table
  end
 end
end



function packet_manager.build_dependencies_tree(self, package_string)
 local res = {}
 get_deps_tree_recursion(self, package_string, res, {})
 return res
end

function packet_manager.install(self, package_string)
 local name, version = parse_package_string(package_string)
 if self:packages()[name] == nil then
  error("No such package "..tostring(package_string).." (try updating)")
 end
 if db_is_installed(self, package_string) then
  error("package "..name.." already installed!")
 end
 local dep_tree = self:build_dependencies_tree(package_string)
 print("I'm going to install following: ")
 for k,v in ipairs(dep_tree) do
  print("\t"..v)
 end
 -- TODO Promt user (if no flag...)
 
 
 for k,v in ipairs(dep_tree) do 
  local name, version = parse_package_string(v)
  if self:packages()[name] == nil then
   error("Could not found package "..name.." (try updating)")
  end
  print("Installing "..v)
  local fname = temp_dir..name.."-"..version..".tar"
  download_to_file(address..name.."-"..version..".tar", fname)
  raw_install(self, fname, v)
  filesystem.remove(fname)
 end
 
 -- raw_install(self, fname)
end

function packet_manager.remove(self, package_string)
 print("Removing package "..package_string)
 if not db_is_installed(self, package_string, true) then
  error("Package "..package_string.." is not installed!")
 end
 local files = self.installed[package_string]
 for k,v in pairs(files) do
  filesystem.remove(v)
     print(v.." -> X")
 end
 self.installed[package_string] = nil
 save_installed(self)
end

function packet_manager.list(self)
 local res = {}
 for k,v in pairs(self.installed) do
  table.insert(res, k)
 end
 return res
end

function packet_manager.get_lastest(self, name)
 if self:packages()[name] == nil then
  error("No such package (try updating)")
 end
 return tostring(self:packages()[name])..tostring(self:packages()[name].versions[#self:packages()[name].versions])
end

function packet_manager.files(self, package_string)
 return self.installed[package_string]
end

return packet_manager