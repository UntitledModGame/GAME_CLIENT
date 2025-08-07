
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













---@class Reader
local Reader = tools.SafeClass()


---@param self Conn
---@param data string
---@return Reader?
---@return string?
local function tryCreateReader(self, data)
    local ok, buffer = pcall(string.buffer.decode,data)
    if ok then
        return Reader(buffer, self)
    end
    return nil, tostring(buffer)
end


---@param buffer string[]
---@param conn Conn
function Reader:init(buffer, conn)
    self.conn = conn
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
---@field packetListeners table<string, function>
---@field clientHost any clientside only
---@field isReady boolean clientisde only
---@field onlineHost any serverside only
---@field localHost any serverside only
local Conn = {}
local Conn_mt = {__index = Conn}


local CLIENT_AUTHENTICATED = 1
local CLIENT_READY = 2


local LOCAL_IPPORT = "localhost:" .. tostring(constants.LOCALHOST_UDP_PORT)


---@param self Conn
local function hostServer(self)
    if launchArgs.localServer then
        self.localHost = enet.host_create(LOCAL_IPPORT)
        assert(self.localHost, "Enet host creation failed.")
    end

    if launchArgs.serverIpPort then
        self.onlineHost = enet.host_create(launchArgs.serverIpPort)
        assert(self.onlineHost, "Enet host creation failed.")
    end

    assert(self.localHost or self.onlineHost, "????")
end


---@param self Conn
local function createClient(self)
    self.clientHost = enet.host_create()
    if launchArgs.localClient then
        self.clientHost:connect("127.0.0.1:"..tostring(constants.LOCALHOST_UDP_PORT))
    else assert(launchArgs.clientIpPort)
        self.clientHost:connect(launchArgs.clientIpPort)
    end
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
            status = CLIENT_AUTHENTICATED or CLIENT_READY
            username = "john_69",
            peer = enetPeer,
            clientId = clientId
        }
    ]]}
    self.peerToInfo = {} -- { [peer] -> info }   (same as above, but from enet-peer mapping)

    self.packetListeners = {} -- [packetName] -> listenFunc

    setmetatable(self, Conn_mt)

    if SERVER_SIDE then
        hostServer(self)
    else assert(CLIENT_SIDE)
        createClient(self)
        self.isReady = false
    end

    return self
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
    if tabl.validateCheck ~= "connectJson" then
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
---@return boolean|table
---@return string?
local function tryDeserConnectJson(data)
    local ok, tabl
    ok, tabl = pcall(json.decode, data)
    if not ok then
        return false, "Couldnt decode ConnectJson: " .. tostring(tabl)
    end
    local ok2, er = validateConnectJson(tabl)
    if not ok2 then
        return false, er
    end
    return tabl
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

    assert(tabl.validateCheck == "clientInitJson")
    assert(tabl.packetNameToId)
    -- todo: put mod-versions here? 
    -- That way, player can check that everything is installed correctly

    return tabl
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


---@param packetName string
---@param func fun(clientId: string, a,b,c,d,e,f)
function Conn:on(packetName, func)
    self.packetListeners[packetName] = func
end


function Conn:unicast(clientId, packetName, a,b,c,d,e)
    assert(SERVER_SIDE, "?")
    
end


function Conn:broadcast(packetName, a,b,c,d,e)
end


function Conn:flush()
end




---@param self Conn
---@param peer any
---@param connectJson any
local function registerClient(self, peer, connectJson)
    local info = {
        clientId = connectJson.clientId,
        status = CLIENT_AUTHENTICATED,
        username = connectJson.username,
        peer = peer
    }
    self.clientIdToInfo[connectJson.clientId] = info
    self.peerToInfo[peer] = info
end



---@param self Conn
---@param data string
---@param func fun(self, packetName, a,b,c,d,e,f)
local function readPacketBundle(self, data, func)
    -- data = decompress(data) --todo: in future have decompression
    local reader, er = tryCreateReader(self, data)
    if not reader then
        log.error("Couldnt create reader: ", er)
        return
    end

    local packetName, a,b,c,d,e,f = reader:read()
    while packetName do
        func(self, packetName, a,b,c,d,e,f)
        packetName, a,b,c,d,e,f = reader:read()
    end

    if reader:hasFailed() then
        local err = a
        log.error("recieved bad packet: ", err)
    end
end


---@param self Conn
---@param ev {data:string, peer:any}
local function dispatchReceive(self, ev)
    local data = ev.data
    local peer = ev.peer -- ENet peer

    if SERVER_SIDE then
        local info = self.peerToInfo[peer]
        if info then
            -- recv normal packet:
            local clientId = info.clientId
            readPacketBundle(self, data, function(packetName, a,b,c,d,e,f)
                local fun = self.packetListeners[packetName]
                if fun then
                    fun(clientId, a,b,c,d,e,f)
                end
            end)
        else
            -- client not joined yet! It's ConnectJson
            local connectJson = assert(tryDeserConnectJson(data))
            -- ^^^ TODO: remove this assertion, replace with proper error handling
            registerClient(self, peer, connectJson)
            log.info("Client authenticated: ", connectJson.clientId)
            peer:send(json.encode(clientInitJson({
                validateCheck = "clientInitJson",
                packetNameToId = self.packetNameToId,
            })))
        end

    else assert(CLIENT_SIDE)
        if self.isReady then
            -- recv packet normally
        else
            local clInitJson = clientInitJson(data)
            assert(clInitJson.validateCheck == "clientInitJson")
            log.info("Recvd clientInitJson: ", data)
            self.packetIdToName = clInitJson.packetIdToName
        end
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
        local connectJson = {
            validateCheck = "connectJson",

            -- TODO: put proper values here
            auth = "... todo ...",
            clientId = tostring(love.math.random(0,10000)),
            username = "playr_" .. tostring(love.math.random(0,10000))
        }
        assert(validateConnectJson(connectJson), "Invalid connectJson")
        log.info("Sending connectJson: ")
        ev.peer:send(json.encode(connectJson))
    else -- SERVER:
        -- do nothing yet. Wait for auth.
    end
end



local dispatch = {
    receive = dispatchReceive,
    disconnect = dispatchDisconnect,
    connect = dispatchConnect
}




local function pollHost(self, host)
    local ok, ev = pcall(host.service, host, 0)
    if not ok then
        log.error(ev)
    end

    while ev do
        dispatch[ev.type](self, ev)

        ok, ev = pcall(host.service, host, 0)
        if not ok then
            log.error(ev)
        end
    end
end


local function pollPackets(self)

    if SERVER_SIDE then
        if self.onlineHost then
            pollHost(self, self.onlineHost)
        end
        if self.localHost then
            pollHost(self, self.localHost)
        end

    else assert(CLIENT_SIDE)
        assert(self.clientHost)
        pollHost(self, self.clientHost)
    end
end



function Conn:update(dt)
    pollPackets(self)
end




return newConn

