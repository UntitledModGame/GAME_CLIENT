

local Loader = require(".Loader")
local config = require(".config")



local modloader = {}


local currentlyLoadingMod = nil


function modloader.getCurrentlyLoadingMod()
    return currentlyLoadingMod
end



function modloader.load(modlist)
    local modGraph = make_topo_sorted()
    for _, mod in ipairs(modlist)do
        currentlyLoadingMod = mod
        -- for future; fail gracefully if config loading fails.
        local cfg = assert(config.tryLoadModConfig())
    end
end


return modloader


