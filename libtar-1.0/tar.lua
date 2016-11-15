--- A pure-Lua implementation of untar (unpacking .tar archives)
local tar = {}


local var_dump = require("var_dump")

-- local fs = require("luarocks.fs")
-- local dir = require("luarocks.dir")
-- local util = require("luarocks.util")
local filesystem = require("filesystem")

local blocksize = 512

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
      local dirname = filesystem.path(pathname)
      if dirname ~= "" and not filesystem.exists(dirname) then
       local ok, err = filesystem.makeDirectory(dirname)
       if not ok then error(err) end
      end
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
