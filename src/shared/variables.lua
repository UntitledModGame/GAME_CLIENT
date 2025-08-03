


return setmetatable({

    LOADING = true,
    -- set to `false` when we are done loading.

},

--=======================================
{ -- METATABLE PROTECTION
    __index = function(t,k)
        error("Accessed unknown CONSTANT: " .. tostring(k))
    end;
    __newindex = function(t,k,v) error("??") end;
    __metatable = "protected"
})

