local internet = require("internet")
local event = require("event")
local os = require("os")
local fs = require("filesystem")
 
local exceptions = {["DCNick"]=true}
 
local function time_global()
 while true do
  local res, t = pcall(internet.request("http://www.timeapi.org/utc/in+three+hours?format=\d/\m/\y%20\I:\M:\S%20\p"))
  if res then
   return t
  end
 end
end
 
local function ret_false()
 return false
end
 
event.shouldSoftInterrupt = ret_false
event.shouldInterrupt = ret_false
 
if not fs.exists("/var") then
 fs.makeDirectory("/var")
end
if not fs.exists("/var/log") then
 fs.makeDirectory("/var/log")
end
if not fs.exists("/var/log/motion.log") then
 io.open("/var/log/motion.log", "w"):close()
end
 
while true do
 local n,_,_,k,p,player = event.pull()
 if n == "motion" then
  if exceptions[player] ~= true then
   --print(player.." detected!")
   local f = io.open("/var/log/motion.log", "a")
   local time = time_global();
   f:write("["..time.."] "..player.."\n")
   f:close()
  end
 elseif n == "key_down" --[[and exceptions[p] == true]] and k == 41 then
  os.exit()
 end
end

