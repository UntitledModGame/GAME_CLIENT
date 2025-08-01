
--[[

------------------------------------------
Connection module:

Handles packets, incoming / outgoing
------------------------------------------

]]

local enet = require"enet"







local Writer = tools.SafeClass()

function Writer:init(options)
    tools.inlineMethods(self)

    self.boxer = options.boxer

    self.buffer = {} -- where the packets actually live
    self.size = 0
end

local encode = string.buffer.encode
function Writer:flush()
    local data = encode(self.buffer)
    self.buffer = {}
    self.size = 0
    return data
end


local add = table.insert

local function push6(self, id, a,b,c,d,e,f)
    local buf = self.buffer
    self.size = self.size + 7
    add(buf, id)
    add(buf, a)
    add(buf, b)
    add(buf, c)
    add(buf, d)
    add(buf, e)
    add(buf, f)
end

local function push5(self, id, a,b,c,d,e)
    local buf = self.buffer
    self.size = self.size + 6
    add(buf, id)
    add(buf, a)
    add(buf, b)
    add(buf, c)
    add(buf, d)
    add(buf, e)
end

local function push4(self, id, a,b,c,d)
    local buf = self.buffer
    self.size = self.size + 5
    add(buf, id)
    add(buf, a)
    add(buf, b)
    add(buf, c)
    add(buf, d)
end

local function push3(self, id, a,b,c)
    local buf = self.buffer
    self.size = self.size + 4
    add(buf, id)
    add(buf, a)
    add(buf, b)
    add(buf, c)
end

local function push2(self, id, a,b)
    local buf = self.buffer
    self.size = self.size + 3
    add(buf, id)
    add(buf, a)
    add(buf, b)
end

local function push1(self, id, a)
    local buf = self.buffer
    self.size = self.size + 2
    add(buf, id)
    add(buf, a)
end

local function push(self, id)
    local buf = self.buffer
    self.size = self.size + 1
    add(buf, id)
end


local pushers = {
    [0] = push,
    [1] = push1,
    [2] = push2,
    [3] = push3,
    [4] = push4,
    [5] = push5,
    [6] = push6
}


local DO_TYPECHECK = constants.DEBUG

local function assertType(self, packetName, val, typ, typeIndex)
    local ok, er = self.boxer.typechecker(val, typ)
    if not ok then
        error(("Bad packet value: %s, arg %d :: %s"):format(packetName, typeIndex, er))
    end
end


function Writer:write(packetName, a,b,c,d,e,f)
    local boxer = self.boxer
    local buffer = self.buffer
    local typelist = boxer:getPacketTypelist(packetName)

    if not typelist then
        error("Unknown packet: " .. tostring(packetName))
    end

    local args = #typelist
    local id = boxer:getPacketId(packetName)
    if not id then
        error("packetName was not registered: " .. packetName)
    end

    local fn = pushers[args]
    fn(self, id, a,b,c,d,e,f)

    local start, finish = (self.size-args) + 1, self.size

    for i=start, finish do
        local typeIndex = (i-start) + 1
        local typ = typelist[typeIndex]

        if DO_TYPECHECK then
            assertType(self, packetName, buffer[i], typ, typeIndex)
        end

        if typ == "entity" then
            local ent = buffer[i]
            -- transform the entity to be serialized "properly":
            local data = boxer.entityToData(ent)
            buffer[i] = data -- will either be a number, or pckr string,
            -- representing the serialized ent
        end
    end
end













local Reader = tools.SafeClass()

local KEYS = {"boxer"}

function Reader:init(buffer, options)
    tools.assertKeys(options, KEYS)
    self.boxer = options.boxer
    self.buffer = buffer
    self.failed = false
    self.i = 1
end

local function getRegularData(reader, num_args)
    --[[
        Returns data from a regular packet
        TODO:
        Convert this to a table-based switch
    ]]
    local buffer = reader.buffer
    local i = reader.i
    reader.i = i + num_args

    if num_args == 0 then
        return
    elseif num_args == 1 then
        return buffer[i]
    elseif num_args == 2 then
        return buffer[i], buffer[i + 1]
    elseif num_args == 3 then
        return buffer[i], buffer[i + 1], buffer[i + 2]
    elseif num_args == 4 then
        return buffer[i], buffer[i + 1], buffer[i + 2], buffer[i+3]
    elseif num_args == 5 then
        return buffer[i], buffer[i + 1], buffer[i + 2], buffer[i+3], buffer[i+4]
    elseif num_args == 6 then
        return buffer[i],  buffer[i + 1], buffer[i + 2],
                buffer[i+3], buffer[i+4], buffer[i+5]
    end
end


local function readPacketData(reader, boxer, packetName)
    --[[
        Transforms a regular packet, checks types,
        then returns data.

        transforms the next packet within the reader,
        assuming that it's a regular packet.

        (Basically just transforms strings/numbers 
            into entities when appropriate)
    ]]
    local i = reader.i
    local buffer = reader.buffer
    local typelist = boxer.nameToPacketTypelist[packetName]
    local dataToEntity = boxer.dataToEntity

    local packetSize = #typelist -- packet-size indicated by size of typelist

    i = i + 1
    reader.i = i

    for u=i, (i+packetSize)-1 do
        -- transform everything
        local j = (u - i) + 1
        local typ = typelist[j]
        if typ == "entity" then
            buffer[u] = dataToEntity(buffer[u])
        end
        local val = buffer[u]

        if SERVER_SIDE then
            -- only do checks on server-side
            local ok, er = boxer.typechecker(val, typ)
            -- its an error!
            if not ok then
                log.error("Error reading packet: ", er)
                reader:fail()
                return
            end
        end
    end

    return getRegularData(reader, packetSize)
end


function Reader:read()
    --[[
        reads the next packet in the buffer,
        and increments the reader position.
    ]]
    local boxer = self.boxer
    local id = self.buffer[self.i]
    if not id then
        self:finish()
        return nil
    end

    local packetName, a,b,c,d,e,f
    packetName = boxer:getPacketName(id)
    if not packetName then
        self:fail()
        log.error("Unknown packet id: " .. tostring(id))
        return nil
    end

    a,b,c,d,e,f = readPacketData(self, boxer, packetName)
    if self:hasFailed() then
        return nil
    end
    return packetName, a,b,c,d,e,f
end


function Reader:isFinished()
    return self.finished
end

function Reader:hasFailed()
    return self.failed
end

function Reader:fail()
    self.failed = true
    self:finish()
end

function Reader:finish()
    self.finished = true
end

















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

