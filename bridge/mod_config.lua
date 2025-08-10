
local tsort = require(".tsort")


---@class modConfig
local modConfig = {}


local MAX_INSTRUCTIONS = constants.MOD_PATH

local MOD_PATH = constants.MOD_PATH
local MOD_CONFIG_FILE = constants.MOD_CONFIG_FILE



local configCache = {--[[
    [modname] -> mod-config

    eg: 
    ["john:fire_mod"] -> {dependencies = {...}, type=..}
]]}



local function isInstalled(modname)
    return love.filesystem.getInfo(constants.MOD_PATH .. "/" .. modname)
end




local function makeAPI(modname)
    local modConfigAPI = {}

    local stringlib = {
        char = string.char,
        upper = string.upper,
        lower = string.lower,
        find = string.find,
        sub = string.sub,
        gsub = string.gsub,
    }

    local tablelib = {
        insert = table.insert,
        remove = table.remove,
        concat = table.concat,
    }

    local umgc = {
        string = stringlib,
        table = tablelib
    }

    function umgc.getOS()
        return love.system.getOS()
    end

    ---@return string
    function umgc.getModname()
        return modname
    end

    ---@return boolean
    function umgc.isDebug()
        return constants.DEBUG
    end

    modConfigAPI.umgc = umgc

    return modConfigAPI
end





---@param modname string
---@return table?
---@return string?
function modConfig.tryLoadModConfig(modname)
    local cfgAPI = makeAPI(modname)

    error("we cant use love API here! This code is meant to be cross-platform. ")
    -- remove love.* API from everywhere in the file.
    -- instead of reading mod-config file directly; load it outside, and pass lua-code in as a string
    -- (same with OS; pass OS through the args)

    local configPath = MOD_PATH .. "/" .. modname .. "/" .. MOD_CONFIG_FILE
    local configContent, err = love.filesystem.read(configPath)
    if not configContent then
        error("Config file not found or could not be read: " .. configPath .. " (" .. tostring(err) .. ")")
    end

    local maxInstructions = MAX_INSTRUCTIONS -- if goes above this amount, infinite loop.
    local instructionCount = 0
    local timeoutReached = false

    local function timeoutHook()
        instructionCount = instructionCount + 1
        if instructionCount > maxInstructions then
            timeoutReached = true
            error("Config execution timeout: possible infinite loop in " .. modname)
        end
    end

    local success, result

    local oldHook = debug.gethook()
    debug.sethook(timeoutHook, "", 1000)
    success, result = pcall(function()
        local chunk, loadErr = load(configContent, "@" .. configPath, "t", cfgAPI)
        if not chunk then
            error("Failed to compile config: " .. tostring(loadErr))
        end
        return chunk()
    end)
    debug.sethook(oldHook)

    if timeoutReached then
        return nil, "Config execution timed out for module '" .. modname .. "': possible infinite loop"
    end
    if not success then
        return nil, ("Failed to load config:" .. modname .. "': " .. tostring(result))
    end

    if type(result) ~= "table" then
        return nil, "Mod config didnt return table"
    end

    return result
end



---@param modname string
---@return table
function modConfig.getConfig(modname)
    if configCache[modname] then
        return configCache[modname]
    end
    -- for future; fail gracefully if config loading fails.
    local cfg = assert(modConfig.tryLoadModConfig(modname))
    configCache[modname] = cfg
    return cfg
end




local function getShallowDependencies(modname)
    -- gets shallow-dependencies
    local config = modConfig.getConfig(modname)
    if config.dependencies then
        local arr = tools.Array(config.dependencies)
        if not arr:find(modname) then
            arr:add(modname)
        end
        return arr
    else
        return tools.Array({modname})
    end
end





local addDepsTc = typecheck.assert("string", "table", "table")
local function addDeps(modname, seen_deps, graph)
    addDepsTc(modname, seen_deps, graph)
    if seen_deps[modname] then
        return
    end
    seen_deps[modname] = true
    local deps = getShallowDependencies(modname)
    if (not deps) or (#deps <= 1) then
        -- No dependencies, therefore, add an unconnected node.
        graph:add(modname)
        return
    end

    for _, depname in ipairs(deps) do
        -- add dependencies to graph
        if modname ~= depname then
            graph:add(modname, depname)
        end
        addDeps(depname, seen_deps, graph)
    end
end



local function reversed(t)
    local r = {}
    for i = #t, 1, -1 do r[#r+1] = t[i] end
    return r
end


function modConfig.getTopologicallySortedDependencies(modlist)
    --[[
        returns modlist, topologically sorted by dependency
    ]]
    local graph = tsort.new()

    local seen_deps = {} -- ensure we don't do duplicates

    for _, modname in ipairs(modlist) do
        addDeps(modname, seen_deps, graph)
    end

    local tabl = graph:sort()
    if not tabl then
        -- TODO: What do we do here? Fail gracefully maybe...?
        error("Circular dependency in the mod list!")
    end
    reversed(tabl)
    return tabl
end





return modConfig

