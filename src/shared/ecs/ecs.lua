

---@class ecs
local ecs = {}



---@class Entity
---@field x number
---@field y number
---@field private ___id number
local Entity = {}
local Entity_mt = {__index = Entity}





---@class View
---@field _addBuffer LightSet
---@field _remBuffer LightSet
---@field _entities Set
---@field _removedCallbacks Array
---@field _addedCallbacks Array
---@field component string
local View = {}
local View_mt = {__index = View}



local currentId = 10000 -- (start at 10000 so we dont invoke array-duality)

local entities = tools.Set()

---@type table<integer, Entity>
local idToEntity = {} -- [id] -> ent


---@type table<string, true>
local components = {} -- [comp] -> true

---@type table<string, true>
local events = {} -- [event] -> true

---@type table<string, {reducer: function, defaultValue: any}>
local questions = {} -- [question] -> { reducer: function, defaultValue: any }



-- an "etype" is just a table containing components. No fancy object.
---@type table<string, true>
local etypes = {} -- [etype] -> true

---@type table<string, table>
local nameToEtypeMt = {} -- [etypeName] -> etype_mt

---@type table<string, View>
local compToView = {} -- [comp] -> View
---@type table<View, true>
local isView = {} -- [view] -> true 











---@param comp string
---@return View
local function newView(comp)
    local self = setmetatable({}, View_mt)
    self.component = comp

    -- entities that need to be added/removed
    self._addBuffer = tools.LightSet()
    self._remBuffer = tools.LightSet()

    self._addedCallbacks = tools.Array()
    self._removedCallbacks = tools.Array()

    self._entities = tools.Set()

    isView[self] = true
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

        -- we set it to nil here (during buffering) to avoid errors.
        --  If we nil it during iteration, a system might iterate through a view,
        --  and find that the entity has the comp as nil.
        ent:rawsetComponent(self.component, nil)
    end
end


function View:_flush()
    for ent in self._remBuffer:iterate() do
        View_rawRemove(self, ent)
    end
    for ent in self._addBuffer:iterate() do
        View_rawAdd(self, ent)
    end
    self._addBuffer:clear()
    self._remBuffer:clear()
end


---@param ent Entity
function View:_addEntity(ent)
    self._remBuffer:remove(ent)
    self._addBuffer:add(ent)
end

---@param ent Entity
function View:_removeEntity(ent)
    self._addBuffer:remove(ent)
    self._remBuffer:add(ent)
end

---@param f fun(ent: Entity)
function View:onAdded(f)
    self._addedCallbacks:add(f)
end

---@param f fun(ent: Entity)
function View:onRemoved(f)
    self._addedCallbacks:add(f)
end

function View:ipairs()
    return ipairs(self._entities)
end

function View:size()
    return self._entities:size()
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



function ecs.flush()
    for _, view in pairs(compToView) do
        view:_flush()
    end
end


function ecs.clear()
    error("TODO: untested!")
    for ent in entities:iterate() do
        ent:delete()
    end
    entities:clear()
    ecs.flush()
end




---@param etypeName string
---@param x any
---@param y any
---@return Entity|table<string,any>
function ecs.newEntity(etypeName, x,y, comps)
    local ent_mt = nameToEtypeMt[etypeName]
    comps = comps or {}
    local ent = setmetatable(comps, ent_mt)
    ---@cast ent Entity
    ent.x = x
    ent.x = y
    currentId = currentId + 1
    ---@diagnostic disable-next-line
    ent.___id = currentId
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


function ecs.exists(ent)
    return entities:has(ent)
end





if constants.DEBUG_INTERCEPT_ENTITY_COMPONENTS then
    error("not yet implemented.")

    function Entity:components(ent)
        return pairs(ent.___debugproxy)
    end
    function Entity.rawsetComponent(ent, comp, val)
        rawset(ent.___debugproxy, comp, val)
    end
else

    function Entity.components(ent)
        return pairs(ent)
    end
    Entity.rawsetComponent = rawset

end


local function shouldRecurse(obj, ctx)
    if type(obj) ~= "table" then
        return false -- dont recurse into non tables
    end
    if ctx.seen[obj] then
        return false -- we have already seen the object, dont recurse
    end
    if isView[obj] then
        return false -- it's a group, dont recurse
    end

    return true
end



local function deepDelete(obj, ctx)
    ctx.seen[obj] = true
    if type(obj) == "table" then
        for k,v in pairs(obj) do
            -- delete all the key values
            if shouldRecurse(v, ctx) then
                deepDelete(v, ctx)
            end
            if shouldRecurse(k, ctx) then
                deepDelete(k, ctx)
            end
        end
    end
    if ecs.exists(obj) then
        -- it's an entity!
        obj:delete(ctx)
    end
end


local function deepClone(x, ctx)
    local seen = ctx.seen
    if seen[x] then
        return seen[x]
    end
    if shouldRecurse(x, ctx) then
        if ecs.exists(x) then
            -- its an entity
            return x:clone(ctx)
        else
            -- its a table or some other object
            local new_x = {}
            seen[x] = new_x
            for k,v in pairs(x) do
                new_x[deepClone(k, ctx)] = deepClone(v, ctx)
            end
            setmetatable(new_x, getmetatable(x))
            return new_x
        end
    end
    if type(x) == "userdata" and type(x.clone) == "function" then
        -- probably is a love2d object
        local cloned = x:clone()
        seen[x] = cloned
        return cloned
    end
    -- else, it's probably just POD
    return x
end



local function newRecurseContext(ent)
    return {
        seen = {[ent] = true},
    }
end


function Entity:shallowDelete()
    error("NOT YET IMPLEMENTED! there should be buffering here.")

    for _, view in pairs(compToView) do
        view:_removeEntity(self)
    end
    entities:remove(self)
    idToEntity[self.___id] = nil
end


function Entity:deepDelete(ctx)
    ctx = ctx or newRecurseContext(self)
    -- deletes an entity, AND deletes entities that this ent references.
    for comp, val in self:components() do
        if shouldRecurse(val, ctx) then
            deepDelete(val, ctx)
        end
    end

    self:shallowDelete()
end


function Entity:deepClone(ctx)
    if ctx and ctx.seen[self] then
        return ctx.seen[self]
    end
    ctx = ctx or newRecurseContext(self)

    local clonedComps = {}
    for comp, val in self:components() do
        if shouldRecurse(val, ctx) then
            clonedComps[comp] = deepClone(val, ctx)
        else
            clonedComps[comp] = val
        end
    end

    local cloned = ecs.newEntity(self:getTypename(), self.x, self.y, clonedComps)
    ctx.seen[self] = cloned

    return cloned
end


Entity.clone = Entity.deepClone

Entity.delete = Entity.deepDelete



---@param comp string
---@param val any
function Entity:addComponent(comp, val)
    if self[comp] == nil then
        local v = compToView[comp]
        if v then
            v:_addEntity(self)
        end
    end
    self:rawsetComponent(comp, val)
end


---@param comp string
function Entity:removeComponent(comp)
    if rawget(self, comp) then
        local v = compToView[comp]
        if v then
            v:_removeEntity(self)
        end
        self:rawsetComponent(comp, nil)
    end
end


---@param comp string
---@return boolean
function Entity:isRegularComponent(comp)
    return rawget(self,comp)
end

function Entity:isSharedComponent(comp)
    return self:getEntityType()[comp] ~= nil
end



---@return table<string, any>
function Entity:getEntityType()
    return getmetatable(self).__index
end


---@return integer
function Entity:getId()
    return self.___id
end


---@return string
function Entity:getTypename()
    return getmetatable(self).___typename
end








ecs.defineComponent("x")
ecs.defineComponent("y")


return ecs

