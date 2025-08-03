


## Grid:
The "grid" is what makes up the "terrain" of the world.
Think of it as like, the block-layer in terraria.

Each grid-point holds a number, which references a string

Inside the grid, there are chunks.

---

## idea:
Have different "grid-layers", 
which are serve different purposes:

- ground-grid: (ground-layer)
- main-grid: (main layer; walls, structures)


# API:

```lua

umg.setGrid(x,y, val)
val = umg.getGrid(x,y)

local worldX, worldY = umg.gridToWorld(gridX, gridY)
local gridX, gridY = umg.worldToGrid(worldX, worldY)

-- ground uses the 
umg.setGround(x,y, val)
val = umg.getGround(x,y)


```


