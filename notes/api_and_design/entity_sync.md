

# Entity syncing API:

We should have explicit syncing.

However, we should also provide implicit tools for syncing entities
implicitly when the player "just wants it to work".

----

# idea:
We shouldn't have complex implicit-syncing in `Conn` module.

For `"entity"` sync type, we always sync the id.  
If the id isn't on the client, the packet read fails





















## OLD IDEAS, (DONT DO THIS!)
## OLD IDEAS, (DONT DO THIS!)
## OLD IDEAS, (DONT DO THIS!)
## OLD IDEAS, (DONT DO THIS!)
## OLD IDEAS, (DONT DO THIS!)

## OLD OPTIONS:

Expose an extra API that calls `sync` automatically:
```lua
e = umg.spawnEntity("my_entity", XYZ)

e = umg.spawnAndSyncEntity("my_entity", XYZ)
-- ^^^ the trouble with this approach is that modders might just start
-- calling it for everything... which sucks.
-- So I dislike this.
-- Maybe better to have a "3rd" system that determines HOW we sync stuff.
-- EG: "sync all stuff globally"
-- EG: "sync all stuff globally"
```

EG:
```lua
e = umg.spawnEntity("my_entity", XYZ)

-- EZ-SYNC MOD:
if server then
    umg.on("@spawnEntity", function(e)
        spawnOnClients(e)
    end)

    umg.on("@deleteEntity", function(e)
        deleteOnClients(e)
    end)
end
```




