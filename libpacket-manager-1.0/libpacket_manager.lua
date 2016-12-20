local component = require("component")
local internet = require("internet")
local internet_raw = component.internet
local filesystem = require("filesystem")

-- Some hack for debugging 
-- package.loaded.tar = nil

local var_dump = require("var_dump")
local serprint = require("serprint")
local tar = require("tar")

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