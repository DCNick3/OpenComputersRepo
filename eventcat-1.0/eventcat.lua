local event = require("event")
local ser = require("serprint")
local sh = require("shell")
local computer = require("computer")

local low_level = false

local args, ops = sh.parse(...)

if ops["l"] == true then
 low_level = true;
end

while true do 
 if not low_level then
  local e = table.pack(event.pull())
  for _,v in ipairs(e) do
   io.write(ser.line(v)..", ")
  end
  print()
 else
  local e = table.pack(computer.pullSignal())
  for _,v in ipairs(e) do
   io.write(ser.line(v)..", ")
  end
  print()
 end
end
