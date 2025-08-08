

---@class config
local config = {}


local MAX_INSTRUCTIONS = constants.MOD_PATH

local MOD_PATH = constants.MOD_PATH
local MOD_CONFIG_FILE = constants.MOD_CONFIG_FILE



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





function config.tryLoadModConfig(modname)
    local cfgAPI = makeAPI(modname)

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
        return false, "Config execution timed out for module '" .. modname .. "': possible infinite loop"
    end
    if not success then
        return false, ("Failed to load config:" .. modname .. "': " .. tostring(result))
    end

    if type(result) ~= "table" then
        return false, "Mod config didnt return table"
    end

    return result
end




return config

