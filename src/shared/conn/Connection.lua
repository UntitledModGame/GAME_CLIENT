

local enet = require"enet"




---@class Conn
---@field packetTypes table
local Conn = {}
local Conn_mt = {__index = Conn}


local function newConn()
    local self = {}

    self.packetTypes = {--[[
        [packetName] -> {"entity", "number", "number"}
    ]]}

    self.broadcastBuffer = {}
    -- self.unicastBuffers = {}

    return setmetatable(self, Conn_mt)
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

function Conn:getPacketType(pType)
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

