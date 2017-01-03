local component = require("component")
local os = require("os")
local unicode = require("unicode")
local var_dump = require("var_dump")
local gpu = component.gpu

local width, height = 80, 25
local legends, map

local libmappedscreen
libmappedscreen = {
 setDisplayMap = function(_map) 
  local rows = {}
  local len = nil
  local legends = {}
  for r in string.gmatch(_map, "([^\n]+)") do
   if len == nil then
    len = unicode.len(r)
   else
    if len ~= unicode.len(r) then
     error("Bad map")
    end
   end
   for i = 1, #r do
    local c = unicode.sub(r,i,i)
    if legends[c] ~= nil then
     legends[c] = legends[c] + 1
    else
     legends[c] = 1
    end
   end
   table.insert(rows, r)
  end
  width = len
  height = #rows
  legends = legends
  map = _map
 end,
 display = function(values, screen)
  if screen == "*all" then
   for a in component.list("screen") do
    var_dump(a)
    libmappedscreen.display(values, a)
   end
  else
   if screen == nil then
    screen = component.list("screen")()
   end
   if gpu.getScreen() ~= screen then
    gpu.bind(screen)
   end
   gpu.setResolution(width, height)
   local nums = {}
   local lines = {""}
   for i = 1, #map do
    local c = unicode.sub(map,i,i)
    if c == "\n" then
     table.insert(lines, "")
    elseif values[c] ~= nil then
     local pos
     if nums[c] ~= nil then
      pos = nums[c]
     else
      pos = 1
     end
     nums[c] = pos + 1
     local val = unicode.sub(values[c], pos, pos)
     if unicode.len(val) == 0 then
      val = " "
     end
     lines[#lines] = lines[#lines]..val
    else--if c == " " then
     lines[#lines] = lines[#lines].." "
    end
   end
   for i,l in ipairs(lines) do
    gpu.set(1,i,l)
    --var_dump(i,l);
   end
  end
 end,
};

return libmappedscreen;