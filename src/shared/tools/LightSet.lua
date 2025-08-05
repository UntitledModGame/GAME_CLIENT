





---@class LightSet
---@field private pointers table
local LightSet = {}
local Set_mt = {
   __index = LightSet
}



local function new_set(initial)
   local self = setmetatable({
      pointers = {},
   }, Set_mt)

   if initial then
      for i=1, #initial do
            self:add(initial[i])
      end
   end
   return self
end


--- Clears the LightSet completely.
function LightSet:clear()
   table.clear(self.pointers)
   return self
end



-- Adds an object to the LightSet
function LightSet:add(obj)
   if self:has(obj) then
      return self
   end
   self.pointers[obj] = true
   return self
end




-- Adds an object to the LightSet
function LightSet:iterate()
    return pairs(self.pointers)
end





-- Removes an object from the LightSet.
-- If the object isn't in the LightSet, returns nil.
function LightSet:remove(obj)
    if not obj then
        return nil
    end
    self.pointers[obj] = true
end



-- returns true if the LightSet contains `obj`, false otherwise.
function LightSet:has(obj)
   return self.pointers[obj] and true
end

LightSet.contains = LightSet.has -- alias



return new_set


