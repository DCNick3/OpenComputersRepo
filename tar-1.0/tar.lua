local fs = require("filesystem")
local shell = require("shell")

local tar = require("tar")


local args, opts = shell.parse(...)
if #args == 2 then
 if fs.exists(args[1]) and not fs.isDirectory(args[1]) then
  if fs.exists(args[2]) and fs.isDirectory(args[2]) then
   args[2] = fs.canonical(args[2]).."/"
   tar.untar(args[1], args[2])
  else
   print("Bad arg #2. Excepted directory")
  end
 else
  print("Bad arg #1. Excepted file")
 end
else
 print("Simple utilite that supports ONLY UNPACKING!")
 print("Usage: tar <archieve> <destination>")
 print("It accepts FULL PATHs!")
end




