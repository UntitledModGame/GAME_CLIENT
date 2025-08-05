

local ecs = {}



---@class Entity
---@field x number
---@field y number
---@field private _id number
local Entity = {}
local Entity_mt = {__index = Entity}





---@class View
---@field _dirtyEntities LightSet
---@field _entities Set
---@field _removedCallbacks Array
---@field _addedCallbacks Array
---@field component string
local View = {}
local View_mt = {__index = View}

---@param comp string
---@return View
local function newView(comp)
    local self = setmetatable({}, View_mt)
    self.component = comp

    -- entities that need to be added/removed
    self._dirtyEntities = tools.LightSet()

    self._addedCallbacks = tools.Array()
    self._removedCallbacks = tools.Array()

    self._entities = tools.Set()

    return self
end



local function View_rawAdd(self, ent)
    if not self._entities:has(ent) then
        for _, cb in ipairs(self._addedCallbacks) do
            cb(ent)
        end
        self._entities:add(ent)
    end
end


---@param self View
---@param ent Entity
local function View_rawRemove(self, ent)
    if self._entities:has(ent) then
        for _, cb in ipairs(self._removedCallbacks) do
            cb(ent)
        end
        self._entities:remove(ent)
    end
end


function View:_flush()
    local c = self.component
    for ent in self._dirtyEntities:iterate() do
        if ent[c] then
            -- add to view
            View_rawAdd(self, ent)
        else
            -- remove from view
            View_rawRemove(self, ent)
        end
    end
    self._dirtyEntities:clear()
end


---@param ent Entity
function View:_addEntity(ent)
    self._dirtyEntities:add(ent)
end

---@param ent Entity
function View:_removeEntity(ent)
    self._dirtyEntities:add(ent)
end



---@class Attachment
local Attachment = {}
--[[
^^^ TODO: are Attachments even worth having???
They feel a bit... weird and bloaty.
Also feels EXTREMELY EASY TO ABUSE.
(a lot of the time, I feel like a component would suffice.)
^^^ We need to be careful with giving modders tools that can be abused.

CRAZY IDEA:
What if Attachments == components?
As in, 

umg.defineComponent("explosive", {
    ["onDeath"] = function(ent)
        print("BOOM.")
    end
})

The downside here is that the player couldn't have multiple attachments
at the same time.

Idk. Also it could be a bit confusing having it like this.
Do a lot of thinking, dont commit to anything yet.
]]




local currentId = 10000 -- (start at 10000 so we dont invoke array-duality)

local entities = tools.Set()
local idToEntity = {} -- [id] -> ent


local components = {} -- [comp] -> true

local events = {} -- [event] -> true

local questions = {} -- [question] -> { reducer: function, defaultValue: function }



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



function ecs.defineEvent(name)
    assert(variables.LOADING, "Can only define events at load time!")
    assert(not events[name], "Redefined event")
    assert(not questions[name], "This was previously defined as a question!")
    events[name] = true
end


function ecs.defineQuestion(name, reducer, defaultValue)
    assert(variables.LOADING, "Can only define questions at load time!")
    assert(not questions[name], "Redefined question")
    assert(not events[name], "This was previously defined as an event!")
    assert(type(reducer) == "function", "Reducer must be function")
    questions[name] = {
        reducer = reducer,
        defaultValue = defaultValue
    }
end



function ecs.call(ev, ...)
    error("nyi")
end
function ecs.on(ev, func)
    error("nyi")
end



function ecs.ask(question, ...)
    error("nyi")
end
function ecs.answer(question, func)
    error("nyi")
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
    currentId = currentId + 1
    ---@diagnostic disable-next-line
    ent._id = currentId
    for k,v in pairs(comps) do
        ent:addComponent(k,v)
    end
    for k,v in pairs(ent:getEntityType()) do
        ent:addComponent(k,v)
    end
    return ent
end


function ecs.getEntity(id)
    return idToEntity[id]
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
    local view = newView(comp)

    compToView[comp] = view
    return view
end





--- marks a component as dirty (ie added/removed.)
--- The system will add/remove it from groups
---@param ent Entity
---@param comp string
local function markDirty(ent, comp)
    local view = compToView[comp]

    error("unfinished.")
    -- view: add 
end


function Entity:rawsetComponent(comp, val)

end

---@param comp string
---@param val any
function Entity:addComponent(comp, val)
    if self[comp] == nil then
        markDirty(self, comp)
        rawset(self, comp, val)
    else
        rawset(self, comp, val)
    end
end


---@param comp string
function Entity:removeComponent(comp)
    if rawget(self, comp) then
        markDirty(self, comp)

        error("RAGH!!! issue here!")
        --[[
        here, there's a terrible bug.
        We can't just markDirty and rawset(comp,nil),
        because then we will have nilled the component 
        WHILST THE ENTITY IS STILL IN GROUPS.

        If we iterate over the view, we expect every entity
        to have `comp`... but with this code, that invariant is broken.

        We need to buffer the comp-removal AND 
        ]]
        rawset(self, comp, nil)
    end
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


---@return table<string, any>
function Entity:getId()
    return getmetatable(self).__index
end


---@return string
function Entity:getTypename()
    return getmetatable(self).___typename
end








ecs.defineComponent("x")
ecs.defineComponent("y")


return ecs

