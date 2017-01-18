local shell = require("shell")
local os = require("os")
local fs = require("filesystem")

local args, opts = shell.parse(...)

if opts.h or opts.help then
 print("Usage: shrun <shell-script>")
 os.exit()
end

if #args ~= 1 then
 print("Except one parameter")
 os.exit()
end

if not fs.exists(shell.resolve(args[1])) then
 print("file not found")
 os.exit()
end

if fs.isDirectory(shell.resolve(args[1])) then
 print(args[1].." is directory")
 os.exit()
end

for l in io.lines(args[1]) do
 local r, e = shell.execute(l)
 if not r then
  print("Error: ")
  print(e)
  print("While executing "..l)
 end
end
