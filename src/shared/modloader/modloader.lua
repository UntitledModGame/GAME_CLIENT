

local Loader = require(".Loader")
local modConfig = require(".mod_config")



local modloader = {}


local currentlyLoadingMod = nil


function modloader.getCurrentlyLoadingMod()
    return currentlyLoadingMod
end


function modloader.load(modlist)
    for _, mod in ipairs(modlist)do
        modConfig.getConfig(mod)
    end
end


return modloader


