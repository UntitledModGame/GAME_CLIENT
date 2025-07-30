
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




rawset(_G, "CLIENT_SIDE", true)
rawset(_G, "SERVER_SIDE", false)
-- we are on client-side


-----
-----============================
----- shared globals
-----
----- Shared between client/server for consistency,
----- (And so that there's a SSOT)
require("src.shared.globals")
-----=============================
-----

local ffi = require("ffi")
assert(ffi.abi("le"), "Bad endianness. This game will not run on your computer.")


rawset(_G, "Region",    require "libs.kirigami.region")
rawset(_G, "LUI",       require "libs.LUI")

rawset(_G, "LoadingLogo", require "src.client.misc.LoadingLogo.LoadingLogo")


rawset(_G, "ui",        require "src.client.ui.ui")


rawset(_G, "userService", require("src.client.userService"))


require("src.client.client")







