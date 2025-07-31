
--[[


userService

responsible for getting/setting username,
and providing clientId.


Right now, there is only ONE username / clientId per program.
Which means we can have userService be static.

]]

local userService = {}


local function getRandomUsername()
    return "plyr_" .. tostring(love.math.random(1000))
end


--[[
    In the future, we should save / load username from a file;
    So the player doesn't need to change username all the time.
    (And/Or we could use steams username by default)
]]
userService.username = getRandomUsername()


-- This should be a steam id!
userService.clientId = tostring(love.math.random(999999))
assert(type(userService.clientId) == "string")



local SETTINGS_FILENAME = "umg_client_settings.json"

local MIN_WINDOW_SIZE = 400


-- Configure variables here
local settings = {
    masterVolume = 100,
    sfxVolume = 40,
    bgmVolume = 25,

    analyticsConsented = false,

    isFullscreen = true,
    windowWidth = 900,
    windowHeight = 1300,
}

local function setupSettings()
    local currentValues
    local f = love.filesystem.openFile(SETTINGS_FILENAME, "r")

    if f then
        local status
        status, currentValues = pcall(json.decode, (f:read()))

        if not status then
            currentValues = nil
        end
    end

    if not currentValues then
        currentValues = {}
    end

    for k, v in pairs(settings) do
        local varType = type(v)
        local savedVar = currentValues[k]

        if type(savedVar) == varType then
            -- Use saved
            settings[k] = savedVar
        end
    end

    love.window.setFullscreen(settings.isFullscreen)

    -- if it gets too small (eg below 200?) it just crashes. Idk why lol
    settings.windowWidth = math.max(MIN_WINDOW_SIZE, settings.windowWidth)
    settings.windowHeight = math.max(MIN_WINDOW_SIZE, settings.windowHeight)

    if not settings.isFullscreen then
        love.window.setMode(settings.windowWidth, settings.windowHeight, {
            resizable = true
        })
    end
end

setupSettings()



function userService.saveSettings()
    -- Save
    local jsondata = json.encode(settings)
    local f = love.filesystem.openFile(SETTINGS_FILENAME, "w")
    f:write(jsondata)
    f:close()
end


---@param volume integer
local function clampVolume(volume)
    return math.min(math.max(math.floor(volume + 0.5), 0), 100)
end

function userService.getMasterVolume()
    settings.masterVolume = clampVolume(settings.masterVolume)
    return settings.masterVolume
end

---@param volume integer
function userService.setMasterVolume(volume)
    assert(type(volume) == "number")
    settings.masterVolume = clampVolume(volume)
end

function userService.getSFXVolume()
    settings.sfxVolume = clampVolume(settings.sfxVolume)
    return settings.sfxVolume
end

---@param volume integer
function userService.setSFXVolume(volume)
    assert(type(volume) == "number")
    settings.sfxVolume = clampVolume(assert(volume))
end

function userService.getBGMVolume()
    settings.bgmVolume = clampVolume(settings.bgmVolume)
    return settings.bgmVolume
end

---@param volume integer
function userService.setBGMVolume(volume)
    assert(type(volume) == "number")
    settings.bgmVolume = clampVolume(assert(volume))
end

---@param isFullscreen boolean
function userService.setFullscreen(isFullscreen)
    assert(type(isFullscreen) == "boolean")
    settings.isFullscreen = isFullscreen
    love.window.setFullscreen(isFullscreen)
end

---@param w number
---@param h number
function userService.resize(w, h)
    assert(type(w) == "number" and type(h) == "number")
    settings.windowWidth = w
    settings.windowHeight = h
end


function userService.isAnalyticsConsentAsked()
    return settings.analyticsConsented
end


function userService.setAnalyticsConsent()
    settings.analyticsConsented = true
end


return userService

