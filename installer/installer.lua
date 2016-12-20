local component = require("component")
local internet = require("internet")
local internet_raw = component.internet
local os = require("os")
local filesystem = require("filesystem")

local libpm_url = "https://github.com/DCNick3/OpenComputersRepo/raw/master/installer/libpacket_manager_no_dep.lua"

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

local fname = os.tmpname()
download_to_file(libpm_url, fname)
local libpm = dofile(fname)
filesystem.remove(fname)
libpm:init()
libpm:update()

local packages_to_install = {"libtar-1.0", "libserprint-1.0", "libvar_dump-1.0", "libpacket-manager-1.0", "packet-manager-1.0"}

for _,v in pairs(packages_to_install) do
 local r, e = pcall(libpm.install, libpm, v)
 if not e then
  print("Error: "..e)
  print("... while installing "..v)
  os.exit(-1)
 end
end
