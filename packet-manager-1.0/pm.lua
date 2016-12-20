
package.loaded.libpacket_manager = nil


local var_dump = require("var_dump")
local pm = require("libpacket_manager")

local arg = {...}

local operations = 
{
 error_help=function()
  print("Usage:\n\tpm operation [packet]")
  print("Supported operations: help, install, remove, update, installed, aviliable, files")
 end,
 install   =function()
  for _,v in ipairs(arg) do
   pm:install(v)
  end
 end,
 remove    =function()
  for _,v in ipairs(arg) do
   if v == "_all" then
    for _, v in pairs(pm:list()) do
     pm:remove(v)
    end
   else
    pm:remove(v)
   end
  end
 end,
 update    =function()
  pm:update()
 end,
 installed =function()
  local packages = pm:list()
  print("Installed packages:")
  for _,v in ipairs(packages) do
   print("\t"..v)
  end
  if #packages == 0 then
   print("No installed packages!")
  end
 end,
 files     =function()
  print("files of "..arg[1])
  for _,v in ipairs(pm:files(arg[1])) do
   print("\t"..v)
  end
 end,
 aviliable =function()
  print("Aviliable packages:")
  for k,v in pairs(pm:packages()) do
   print("\t"..k)
   for kk,vv in ipairs(v.versions) do
    print("\t\t"..vv)
   end
  end
 end,
}
operations.help = operations.error_help

local operation = arg[1]
table.remove(arg, 1)
if operation == nil then
 operation = "error_help"
end

pm:init()

local op_func = operations[operation]
if op_func == nil then op_func = operations["error_help"] end
op_func()

--pm:update()
--var_dump(pm:build_dependencies_tree("test-program-1.0"));



--pm:install("test-program-1.0")
--pm:remove("test-program-1.0")


