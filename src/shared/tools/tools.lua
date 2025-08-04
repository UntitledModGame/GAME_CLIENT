


local tools = {}

function tools.path(...)
    return (...):gsub('%.[^%.]+$', '')
end





tools.nullFunction = function() end

tools.identity = function(x) return x end


tools.Set = require(tools.path(...)..".Set")
tools.Array = require(tools.path(...)..".Array")
tools.Class = require(tools.path(...)..".Class")
tools.SafeTable = require(tools.path(...)..".SafeTable")
tools.SafeClass = require(tools.path(...)..".SafeClass")



function tools.assertKeys(tabl, keys)
    --[[
        asserts that `tabl` is a table, 
        and that it has all of the keys listed in the `keys` table.
    ]]
    if type(tabl) ~= "table" then
        error("Expected table, got: " .. type(tabl), 2)
    end
    for _, key in ipairs(keys) do
        if tabl[key] == nil then
            error("Missing key: " .. tostring(key), 2)
        end
    end
end


function tools.injectKeys(tabl, keyTable)
    for k,v in pairs(keyTable) do
        tabl[k] = v
    end
end


function tools.inlineMethods(self)
    --[[
        inline all methods in an object for efficiency,
        such that there is no __index overhead.
        (Just copies over key-vals)
    ]]
    local mt = getmetatable(self)
    for k,v in pairs(mt.__index) do
        self[k] = v
    end
end




local SEP_PATTERN = "%" .. constants.UMG_NAMESPACE_SEPARATOR

function tools.toNamespaced(modName, str)
    --  "modname", "str"  --->   "modname:str"
    if modName:find(SEP_PATTERN) then
        error("Invalid modname: " .. modName)
    end
    return modName .. constants.UMG_NAMESPACE_SEPARATOR .. str
end

function tools.fromNamespaced(namespacedStr)
    --  "modname:str"  --->  "modname", "str"
    local s,_ = namespacedStr:find(SEP_PATTERN)
    if s then
        return namespacedStr:sub(1,s-1), namespacedStr:sub(s+1)
    end
end







function tools.isValidFilename(fname)
    --[[
        if `fname` is a valid filename, returns true.
        Else, returns false.
    ]]
    if type(fname)~="string" then
        return false
    end
    local invalids = "[\"%*%/%:%<%>%?\\%|%+%,%;%=%[%]]"
    local len_before = #fname
    local subbed = fname:gsub(invalids, "")
    if #subbed == len_before then
        return true
    end
end



function tools.removeExtension(fname)
    return fname:gsub("(.*)%..*$","%1")
end

function tools.getExtension(fname)
    return fname:match("%.[^%.]*$")
end

function tools.getFilename(fullpath)
    return fullpath:match("[^/]*$")
end



local function getCallable(x)
    if type(x) == "function" then
        return x
    end
    local mt = getmetatable(x)
    if mt then
        return mt.__call
    end

    return nil
end

function tools.getFuncInfo(x)
    local func = assert(getCallable(x), "not callable")
    local info = debug.getinfo(func, "nS")
    local source

    if info.source and info.linedefined then
        source = info.source..":"..info.linedefined
    else
        -- Yeah fallback
        source = tostring(func)
    end

    return source
end



if constants.TEST then
    -- tests of exten functions
    local exten_tests = {
        ["abc.lua"] = ".lua",
        ["aba.XYZ.xxt"] = ".xxt",
        ["a.a"] = ".a",
        ["000.abc"] = ".abc",
        ["lua."] = "."
    }
    for fname, exten in pairs(exten_tests) do
        if not (tools.getExtension(fname) == exten) then
            error("test failed: " .. fname .. "  " .. exten .. " :: " .. tools.getExtension(fname))
        end
    end
end


return tools

