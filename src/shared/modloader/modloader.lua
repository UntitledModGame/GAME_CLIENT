

local Loader = require(".Loader")
local modConfig = require(".mod_config")



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
        local cfg = assert(modConfig.tryLoadModConfig())
    end
end


return modloader


