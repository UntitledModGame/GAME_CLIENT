
love.graphics.setDefaultFilter("nearest", "nearest")


setmetatable(_G, {__index = function(_,k)
    error("Undefined variable: "..tostring(k), 2)
end;
__newindex = function(_,k,_)
    error("Non local created: " .. tostring(k), 2)
end})


local constants = require("src.shared.constants")
love.filesystem.setIdentity(constants.FILESYSTEM_IDENTITY)


local json = require("libs.json")



--[[

When the game starts,
the launcher passes some args:

- is_host: bool
- gamemode: string
- world: string
- ip: string
- port: number


We just join the server, launch the game, etc

]]



--[[
this table serves as a description for what launchArgs SHOULD LOOK LIKE.
(NOT ACTUAL VALUES!!!)
]]
local LAUNCH_ARGS = {
    kind = "server" or "client",
    modlist = {"mod", "list", "goes", "here"},

    localClient = true or false,
    clientIpPort = "ip:port" or nil,
    -- if this ^^^^ is given; client is connecting to online server

    localServer = true or false,
    serverIpPort = "ip:port" or nil, -- 
    -- if this ^^^^ is given; server is hosting an online server
}



---@param args any
---@return {kind:"server"|"client", modlist:string[], localClient?:boolean, clientIpPort:string, localServer?:boolean, serverIpPort:string}
local function doLaunchArgs(args)
    local jsonStr = {}
    for i, arg in ipairs(args) do
        table.insert(jsonStr, arg)
    end

    local launchArgs = json.decode(table.concat(jsonStr))

    local isServer = launchArgs.kind == "server"
    local isClient = launchArgs.kind == "client"
    assert(isClient or isServer)
    assert((not isClient) or launchArgs.localClient or launchArgs.clientIpPort)
    assert((not isServer) or launchArgs.localServer or launchArgs.serverIpPort)

    for k, v in pairs(LAUNCH_ARGS) do
        if not launchArgs[k] then
            -- if a defined key doesn't exist; set it to false.
            -- This way we avoid __index errors
            launchArgs[k] = false
        end
    end

    -- defensive __index, ensures we dont access undefined args
    setmetatable(launchArgs, {
        __index = function(_t, k)
            error("Undefined launch-arg: " .. tostring(k))
        end
    })
    return launchArgs
end



function love.load(args)
    rawset(_G, "launchArgs", doLaunchArgs(args))

    if launchArgs.kind == "server" then
        rawset(_G, "SERVER_SIDE", true)
        rawset(_G, "CLIENT_SIDE", false)

    else assert(launchArgs.kind == "client")
        rawset(_G, "CLIENT_SIDE", true)
        rawset(_G, "SERVER_SIDE", false)
        love.window = require("love.window")
        love.window.setMode(800, 600)
    end

    -- shared globals
    -- Shared between client/server for consistency,
    -- (And so that there's a SSOT)
    require("src.shared.globals")
    --=============================

    local ffi = require("ffi")
    assert(ffi.abi("le"), "Bad endianness. This game will not run on your computer.")


    print((SERVER_SIDE and "Server booted") or "Client loaded")
end




function love.draw()
end


function love.update(dt)
end

