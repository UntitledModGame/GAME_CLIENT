
-- EVERYTHING HERE MUSTTT BE A CONSTANT!!!

local DEV_MODE = false
-- This is slightly sophisticated DEV_MODE check.
-- Basically we assume DEV_MODE if:
-- * `.git` is present in (and only in) the game directory
-- * is not fused.
do
    if love.filesystem.getInfo(".git", "directory") then
        local path = love.filesystem.getRealDirectory(".git")
        DEV_MODE = path == love.filesystem.getSource() and not love.filesystem.isFused()
    end
end


return setmetatable({
    VERSION = "0.0.0";

    DEV_MODE = DEV_MODE,

    FILESYSTEM_IDENTITY = "umg",

    DISCORD_LINK = "https://discord.gg/Pd4nwmy2HJ";

    LOCALHOST_UDP_PORT = 57843;
    -- udp-port to be used for localhost server. 
    -- (This means we don't need to do weird port-discovery stuff)

    SERVER_CONNECT_TIMEOUT = 8; -- anything more than this is a timeout.

    ENET_REGULAR_CHANNEL = 0; -- ENet channel for regular packets
    ENET_UNRELIABLE_CHANNEL = 1; -- Channel for unreliable packets.

    SHOULD_COMPRESS = false; -- true/false, depending on whether compression
    -- should be used for ENet packets.  (uses LZ4)

    MAX_PLAYERS = 32;

    TEXTURE_ATLAS_SIZE = 4096; -- X by X pixels

    ONLINE_MODES = {
        -- server online modes enum
        "online", "raw", "offline",
        online = "online", -- online, thru hpuncher
        offline = "offline", -- offline
        raw = "raw" -- online, but not thru hpuncher. (Port forwd most likely)
    };

    SHOW_SPLASH = false;

    TEST = true; -- Do we want to do testing?

    DEBUG = true; -- Do we want debug msgs?

    DEBUG_INTERCEPT_ENTITY_COMPONENTS = false, -- Do we want to intercept entity-component reads/writes?
    -- useful for highly aggressive debugging; 
    -- eg. "where in the code was `ent.x` set to a string?")

    DEFAULT_CONSOLE_LOG_LEVEL = DEV_MODE and "info" or "warn",
    CONSOLE_LOG_LEVEL_ENVVAR = "UMG_CONSOLE_LOG_LEVEL",
    DEFAULT_FILE_LOG_LEVEL = DEV_MODE and "none" or "info",
    FILE_LOG_LEVEL_ENVVAR = "UMG_FILE_LOG_LEVEL",

    LOVE_EVENTS = {
        "load", "draw", "update", "keypressed", "keyreleased", 
        "textinput", "mousepressed", "mousemoved", "mousereleased",
        "wheelmoved", "focus", "resize", "threaderror",
        "filedropped", "directorydropped" -- There are some more
    };

    KNOWN_UMG_EVENTS = {
        "@tick",
        "@load",
        "@clientConnected", "@clientDisconnected",
        "@quit",
        "@draw", "@update",
        "@keypressed", "@textinput", "@keyreleased",
        "@resize",
        "@wheelmoved", "@mousepressed", "@mousereleased", "@mousemoved",
        "@entityInit", "@newEntityType",
        "@debugComponentAccess", "@debugComponentChange",
    },

    KNOWN_UMG_QUESTIONS = {
        -- no questions are emitted by the engine (yet)
    },

    PROFILE_EVENT_BUS = false, -- true = emits event bus profiling data in milliseconds.

    UMG_NAMESPACE_SEPARATOR = ":", -- author:mod
    UMG_MOD_FOLDER_NAMESPACE_SEPARATOR = "@", -- author:mod --> author@mod for filesystem

    PCKR_API_REGISTER_PREFIX = "@", -- prepend this to any register alias used while modding.
    BOXER_BUILTIN_PACKET_PREFIX = "@", -- prepend this to builtin packet names

    FILE_SEP = "/", -- use forward slash for file separation

    ENTITY_DATA_FILE = "entity_data.pckr", -- stores entity-data
    SAVE_DATA_PATH = "saves/",
    CLIENT_SAVE_DATA_PATH = "clientdata/",

    -- mod path for %appdata% only for experimental mods (see _modloader.md)
    MOD_PATH = "mods/",
    MOD_CONFIG_FILE = "umg_mod.lua",

    MOD_REQUIRE_CHUNK_PREFIX = "[mods] ", -- when error is thrown, prefix with this

    INTERNAL_PATH = "internal_DONT_TOUCH/", -- the directory path for interally used files
    TEMP_PATH = "temporary/", -- temporary files
},





--=======================================
{ -- METATABLE PROTECTION
    __index = function(t,k)
        error("Accessed unknown CONSTANT: " .. tostring(k))
    end;
    __newindex = function(t,k,v) error("??") end;
    __metatable = "protected"
})

