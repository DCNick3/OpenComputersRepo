function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

local index 
if file_exists("index.lua") then
 index = dofile("index.lua")
else
 index = dofile("index_pretty.lua")
end

local function exportstring( s )
 return string.format("%q", s)
end

local serprint = require("serprint")


local args = {...}
if args[1] == "list" then
 for p, v in pairs(index) do
  for _,version in ipairs(v.versions) do
   print(tostring(p).."-"..tostring(version))
  end
 end
elseif args[1] == "size" then
 local name = string.match(args[2], "([a-zA-Z-_0-9]+)-[0-9.]+")
 local version = string.match(args[2], "[a-zA-Z-_0-9]+-([0-9.]+)")
 local size = tonumber(args[3])
 if index[name].sizes == nil then
  index[name].sizes = {}
 end
 index[name].sizes[version]=size
end

local h = io.open("index.lua", "wb")
h:write(serprint.dump(index))
h:close()
