

local Loader = require(".Loader")
local modConfig = require("bridge.mod_config")



local modloader = {}


local currentlyLoadingMod = nil


function modloader.getCurrentlyLoadingMod()
    return currentlyLoadingMod
end



local function loadMod(modname)
    currentlyLoadingMod = modname

    local ldr = Loader(modname)
    ldr:loadMod()

    currentlyLoadingMod = nil
end


function modloader.loadMods(modlist)
    for _, mod in ipairs(modlist)do
        modConfig.getConfig(mod)
    end

    local arr = modConfig.getTopologicallySortedDependencies(modlist)

    for _,modname in ipairs(arr)do
        loadMod(modname)
    end
end


return modloader


