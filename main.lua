
love.graphics.setDefaultFilter("nearest", "nearest")


setmetatable(_G, {__index = function(_,k)
    error("Undefined variable: "..tostring(k), 2)
end;
__newindex = function(_,k,_)
    error("Non local created: " .. tostring(k), 2)
end})


local constants = require("src.shared.constants")
love.filesystem.setIdentity(constants.FILESYSTEM_IDENTITY)




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




function love.load(args)

    local hasArg = {}
    for i, arg in ipairs(args) do
        hasArg[arg] = true
    end

    if hasArg["--server"] then
        rawset(_G, "SERVER_SIDE", true)
        rawset(_G, "CLIENT_SIDE", false)

    else
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


