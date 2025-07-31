

local enet = require"enet"






---@class Conn
---@field packetTypes table
---@field knownEntities table<string, table<Entity, boolean>>
local Conn = {}
local Conn_mt = {__index = Conn}


local function newConn()
    local self = {}

    self.packetTypes = {--[[
        [packetName] -> {"entity", "number", "number"}
    ]]}

    if SERVER_SIDE then
        self.knownEntities = {--[[
            [client] -> Set of known entities
        ]]}
    end

    self.broadcastBuffer = {}
    -- self.unicastBuffers = {}

    return setmetatable(self, Conn_mt)
end




---@param clientId string
---@param ent Entity
---@return boolean
function Conn:isEntityKnownTo(clientId, ent)
    local tabl = self.knownEntities[clientId]
    return tabl[ent]
end



---@param clientId string
---@param ent any
function Conn:makeEntityKnownTo(clientId, ent)
    local tabl = self.knownEntities[clientId]
    tabl[ent] = true
end


---@param ent Entity
function Conn:deleteEntity(ent)
    for cl,tabl in pairs(self.knownEntities) do
        tabl[ent] = nil
    end
end


---Iterates over known entities
---@param clientId any
---@return fun(tabl: table<Entity, boolean>, index?: Entity): Entity, boolean
function Conn:iterateKnownEntities(clientId)
    return pairs(self.knownEntities[clientId])
end





function Conn:hostServer(ip)
    local ipport = ip .. ":0"
    self.host = enet.host_create(ipport)
end




function Conn:createClient(ip, port)
    local ipport = ip .. ":0"
    self.host = enet.host_create(ipport)
end



function Conn:definePacketType(pType, types)
    self.packetTypes[pType] = types
end

function Conn:getPacketId(pType)
    return self.packetTypes[pType]
end




function Conn:broadcast(packetName, a,b,c,d,e)

end


function Conn:flush()
end



local function pollLocalPackets(self)
    local host = self.offlineEnetHost
    return function()
        return host:service()
    end
end

local function pollOnlinePackets(self)
    if not self.isOnline then
        return tools.nullFunction
    end
    return function()
        return self.enetHost:service()
    end
end


local function dispatchReceive(self, ev)
    local data = ev.data
    local peer = ev.peer -- ENet peer
end

local function dispatchDisconnect(self, ev)
end

local function dispatchConnect(self, ev)
end



local dispatch = {
    receive = dispatchReceive,
    disconnect = dispatchDisconnect,
    connect = dispatchConnect
}



function Conn:update(dt)
    for ev in pollLocalPackets(self) do
        dispatch[ev.type](self, ev)
    end

    for ev in pollOnlinePackets(self) do
        dispatch[ev.type](self, ev)
    end
end




return newConn

