

local ecs = {}



---@class Entity
local Entity = {}
local Entity_mt = {__index = Entity}


---@class View
local View = {}
local View_mt = {__index = View}


---@class Attachment
local Attachment = {}





local entities = tools.Set()

local components = {} -- [comp] -> true




-- an "etype" is just a table containing components. No fancy object.
local etypes = {} -- [etype] -> true

local nameToEtype = {} -- [etypeName] -> etype
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
    comps.x = x
    comps.y = y
    local ent = setmetatable(comps, ent_mt)
    for k,v in pairs(comps) do
        ent:addComponent(k,v)
    end
    return ent
end



function ecs.defineEntityType(name, etype)
    assert(not etypes[etype], "Duplicate etype")
    nameToEtype[name] = etype
    nameToEtypeMt[name] = {
        __index = setmetatable(etype, Entity_mt),
        ___typename = name
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






function Entity:addComponent(comp, val)
    local view = compToView[comp]
    rawset(self, comp, val)
end


function Entity:removeComponent(comp)
    rawset(self, comp, nil)
end


function Entity:getEntityType()
end

function Entity:getTypename()

end








ecs.defineComponent("x")
ecs.defineComponent("y")


return ecs

