local component = require("component")
local os = require("os")
local unicode = require("unicode")
local var_dump = require("var_dump")
local gpu = component.gpu

local libmappedscreen = {
 setDisplayMap = function(self, map) 
  local rows = {}
  local len = nil
  local legends = {}
  for r in string.gmatch(map, "([^\n]+)") do
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
  self.width = len
  self.height = #rows
  self.legends = legends
  self.map = map
 end,
 display = function(self, screen, values)
  gpu.bind(screen)
  gpu.setResolution(self.width, self.height)
  local nums = {}
  local x,y = 1,1
  for i = 1, #self.map do
   local c = unicode.sub(self.map,i,i)
   if c == "\n" then
    y = y + 1
    x = 0
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
    gpu.set(x,y,val)
   elseif c == " " then
    gpu.set(x,y," ")
   end
   x = x + 1
  end
 end,
 width = 80,
 height = 25,
};

return libmappedscreen;