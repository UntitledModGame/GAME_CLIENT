

# EVENTS:


### OPTION-1: events as strings:
```lua
umg.on("mod:myEvent", function(e, ...)
    -- ^^^ nice and simple, very clear.
end)
-- DOWNSIDE: ^^^ Doesn't work with linting!


-- UPSIDES: we can do more exotic stuff:

umg.defineAttachment("mod:myAttachment", {
    init = function(atch, ...)
        -- setup stuff here
    end,
    onAttach = function(atch, ent)

    end,
    ["mod:myEvent"] = func
})


umg.defineEntityType("mod:ent", {
    ["mod:myEvent"] = function(ent, ...)
        -- do stuff
    end
})

```




### OPTION-2: Strongly-typed events:
```lua
mod.myEvent.connect(function(e, ...)
    -- ^^^ strong type-checking here
end)

-- DOWNSIDE-1: we need a namespace for the mod.
-- DOWNSIDE-2: Maybe its harder to do attachments..?

A = Attachment("mod:myAttachment")
A:on() -- blehh its bad.
```





### OPTION 3: Hybrid approach:
```lua
umg.on("mod:myEvent", f)

mod.onMyEvent(f) -- this calls `umg.on` under hood
mod.attachMyEvent(A, f) -- calls A:on under hood

-- ehh, this all feels a bit unweildy.
-- I think its better to stick to OPTION-1, a lot simpler.
```



