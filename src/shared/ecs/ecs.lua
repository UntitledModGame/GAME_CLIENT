

local ecs = {}



---@class Entity
---@field x number
---@field y number
local Entity = {}
local Entity_mt = {__index = Entity}





---@class View
---@field private _dirtyEntities LightSet
---@field private _entities Set
---@field component string
local View = {}
local View_mt = {__index = View}

local function newView(comp)
    local self = {}
    self.component = comp

    -- entities that need to be added/removed
    self._dirtyEntities = tools.LightSet()

    self._entities = tools.Set()
end


function View:_flush()
    local c = self.component
    for ent in self._dirtyEntities:iterate() do
        if ent[c] then
            -- add to view

        else
            -- remvoe from view

        end
    end
end


---@class Attachment
local Attachment = {}





local entities = tools.Set()

local components = {} -- [comp] -> true




-- an "etype" is just a table containing components. No fancy object.
local etypes = {} -- [etype] -> true

local nameToEtypeMt = {} -- [etypeName] -> etype_mt

local compToView = {} -- [comp] -> View



function ecs.finalize()
end



function ecs.defineComponent(name)
    assert(variables.LOADING, "Can only define components at load time!")
    assert(not components[name], "Redefined component")
    components[name] = true
end




---@param etypeName string
---@param x any
---@param y any
function ecs.newEntity(etypeName, x,y, comps)
    local ent_mt = nameToEtypeMt[etypeName]
    comps = comps or {}
    local ent = setmetatable(comps, ent_mt)
    ---@cast ent Entity
    ent.x = x
    ent.x = y
    for k,v in pairs(comps) do
        ent:addComponent(k,v)
    end
    for k,v in pairs(ent:getEntityType()) do
        ent:addComponent(k,v)
    end
    return ent
end



function ecs.defineEntityType(name, etype)
    assert(not etypes[etype], "Used the same table for 2 entity-types!")

    nameToEtypeMt[name] = {
        ___typename = name,
        __index = setmetatable(etype, Entity_mt),
    }

    etypes[etype] = true
end



---@param comp string
---@return View
function ecs.view(comp)
    local view = setmetatable({
        component = comp
    }, View_mt)

    compToView[comp] = view
    return view
end






---@param comp string
---@param val any
function Entity:addComponent(comp, val)
    local view = compToView[comp]
    rawset(self, comp, val)
end


---@param comp string
function Entity:removeComponent(comp)
    local view = compToView[comp]
    rawset(self, comp, nil)
end


---@param comp string
---@return boolean
function Entity:isRegularComponent(comp)
    return rawget(self,comp)
end



---@return table<string, any>
function Entity:getEntityType()
    return getmetatable(self).__index
end

---@return string
function Entity:getTypename()
    return getmetatable(self).___typename
end








ecs.defineComponent("x")
ecs.defineComponent("y")


return ecs

