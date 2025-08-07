
--[[

------------------------------------------
Connection module:

Handles packets, incoming / outgoing
------------------------------------------

]]

local enet = require"enet"



local DO_TYPECHECK = constants.DEBUG


local types = {}

local function makeCheckFunction(typ)
    local expectStr = "Expected " .. typ .. ", got: "
    local function check(x)
        if type(x) ~= typ then
            return nil, expectStr .. tostring(x)
        end
        return true
    end
    return check
end


types.number = makeCheckFunction("number")
types.string = makeCheckFunction("string")
types.boolean = makeCheckFunction("boolean")

types.entity = function(id)
    local ok = type(id) == "number" and ecs.getEntity(id)
    if not ok then
        return false, "Expected entity, got: "
    end
end


local function typechecker(val, typ)
    return types[typ](val)
end







local Writer = tools.SafeClass()

function Writer:init(options)
    tools.inlineMethods(self)

    self.conn = options.conn

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


function Writer:write(packetName, a,b,c,d,e,f)
    local conn = self.conn
    local buffer = self.buffer
    local typelist = conn:getPacketTypelist(packetName)

    if not typelist then
        error("Unknown packet: " .. tostring(packetName))
    end

    local args = #typelist
    local id = conn:getPacketId(packetName)
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
            local ok, er = typechecker(buffer[i], typ)
            if not ok then
                error(("Bad packet value: %s, arg %d :: %s"):format(packetName, typeIndex, er))
            end
        end

        if typ == "entity" then
            local ent = buffer[i]
            -- transform the entity to be serialized "properly":
            local data = ent:getId()
            buffer[i] = data -- will either be a number, or pckr string,
            -- representing the serialized ent
        end
    end
end













local Reader = tools.SafeClass()

local KEYS = {"conn"}

function Reader:init(buffer, options)
    tools.assertKeys(options, KEYS)
    self.conn = options.conn
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


local function readPacketData(reader, conn, packetName)
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
    local typelist = conn.nameToPacketTypelist[packetName]
    local dataToEntity = conn.dataToEntity

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
            local ok, er = typechecker(val, typ)
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
    local conn = self.conn
    local id = self.buffer[self.i]
    if not id then
        self:finish()
        return nil
    end

    local packetName, a,b,c,d,e,f
    packetName = conn:getPacketName(id)
    if not packetName then
        self:fail()
        log.error("Unknown packet id: " .. tostring(id))
        return nil
    end

    a,b,c,d,e,f = readPacketData(self, conn, packetName)
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















---@alias ClientInfo {clientId:string, username:string, status:integer, peer:userdata}


---@class Conn
---@field packetTypes table
---@field currPacketId integer only available server-side
---@field packetNameToId table<string, integer>
---@field packetIdToName table<integer, string>
---@field clientIdToInfo table<string, ClientInfo>
---@field peerToInfo table<userdata, ClientInfo>
---@field clientHost any clientside only
---@field onlineHost any serverside only
---@field localHost any serverside only
local Conn = {}
local Conn_mt = {__index = Conn}


local CLIENT_JOINED = 0
local CLIENT_AUTHENTICATED = 1
local CLIENT_READY = 2



function Conn:hostServer()
    local ipport = ip .. ":" .. tostring(port or 0)
    self.onlineHost = enet.host_create(ipport)

    self.localHost = enet.host_create("127.0.0.0:" .. tostring(constants.LOCALHOST_UDP_PORT))
end



---@param ip string
---@param port number
function Conn:createClient(ip, port)
    self.clientHost = enet.host_create()
    self.clientHost:connect(ip .. ":" .. port)
end




local function newConn()
    local self = {}

    self.packetTypes = {--[[
        [packetName] -> {"entity", "number", "number"}
    ]]}

    if SERVER_SIDE then
        self.currPacketId = 0
    end
    self.packetIdToName = {} -- [id] -> name
    self.packetNameToId = {} -- [name] -> id

    self.broadcastBuffer = {}
    -- self.unicastBuffers = {}

    self.clientIdToInfo = {--[[
        [clientId] -> {
            status = CLIENT_JOINED or CLIENT_AUTHENTICATED or CLIENT_READY
            username = "john_69",
            peer = enetPeer,
            clientId = clientId
        }
    ]]}
    self.peerToInfo = {} -- { [peer] -> info }   (same as above, but from enet-peer mapping)

    return setmetatable(self, Conn_mt)
end




---@param self Conn
---@param name string
---@param id integer
local function setPacketId(self, name, id)
    assert(not self.packetNameToId[name], "Overwriting packet???")
    self.packetIdToName[id] = name
    self.packetNameToId[name] = id
end



--- Parses and validates ConnectJson,
---  client -> server
---@param tabl table
---@return boolean, string?
local function validateConnectJson(tabl)
    if tabl.connectJson ~= "connectJson" then
        return false, "Invalid ConnectJson"
    end
    if type(tabl.auth) ~= "string" then
        return false, "Bad type for auth"
    end
    if type(tabl.clientId) ~= "string" then
        return false, "Bad type for clientId"
    end
    if type(tabl.username) ~= "string" then
        return false, "Bad type for username"
    end
    return true
end


---@param data string
---@return boolean
---@return string?
local function tryDeserConnectJson(data)
    local ok, tabl
    ok, tabl = pcall(json.decode, data)
    if not ok then
        return false, "Couldnt decode ConnectJson: " .. tostring(tabl)
    end
    return validateConnectJson(tabl)
end



--- Parses and validates ClientInitJson,
---  server -> client
---@param tabl_or_string table|string
local function clientInitJson(tabl_or_string)
    local tabl
    if type(tabl_or_string) == "string" then
        tabl = json.decode(tabl_or_string)
    else
        tabl = tabl_or_string
    end

    assert(tabl.clientInitJson == "clientInitJson")
    assert(tabl.packetNameToId)
    -- todo: put mod-versions here? 
    -- That way, player can check that everything is installed correctly
end





---@param pName string
---@param types string[]
function Conn:definePacketType(pName, types)
    self.packetTypes[pName] = types
    if SERVER_SIDE then
        setPacketId(self, pName, self.currPacketId)
    end
end

function Conn:getPacketTypelist(pType)
    return self.packetTypes[pType]
end

function Conn:getPacketName(id)
    return self.packetIdToName[id]
end



function Conn:unicast(clientId, packetName, a,b,c,d,e)

end


function Conn:broadcast(packetName, a,b,c,d,e)
end


function Conn:flush()
end



local function dispatchReceive(self, ev)
    local data = ev.data
    local peer = ev.peer -- ENet peer

    if SERVER_SIDE then

    else assert(CLIENT_SIDE)
        
    end
end


---@param self Conn
---@param ev any
local function dispatchDisconnect(self, ev)
    local data = ev.data
    local peer = ev.peer

    if SERVER_SIDE then
        local clInfo = self.peerToInfo[ev.peer]
        self.peerToInfo[ev.peer] = nil
        self.clientIdToInfo[clInfo.clientId] = nil
        ecs.call("@clientDisconnected", clInfo.clientId)
    end
end


local function dispatchConnect(self, ev)
    if CLIENT_SIDE then
        
    else -- SERVER:
        -- do nothing yet. Wait for auth.
    end
end



local dispatch = {
    receive = dispatchReceive,
    disconnect = dispatchDisconnect,
    connect = dispatchConnect
}




local function pollPackets(self)
    local host = self.offlineEnetHost
    local ev = host:service()
    while ev do
        dispatch[ev.type](self, ev)
        ev = host:service()
    end

    if self.isOnline then
        host = self.enetHost
        ev = host:service()
        while ev do
            dispatch[ev.type](self, ev)
            ev = host:service()
        end
    end
end



function Conn:update(dt)
    pollPackets(self)
end




return newConn

