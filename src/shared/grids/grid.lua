local floor = math.floor

-- Constants for now
local CHUNK_SIZE = 32
local GRID_CELL_SIZE = 32
local NEIGHBORS = {
    { -1, 0 },
    { 1,  0 },
    { 0,  -1 },
    { 0,  1 },
}

local Grid = {
    cellTypes = {},
    mainLayer = {},
    groundLayer = {},
    groundFallback = nil,
}

function Grid.getChunkSize() return CHUNK_SIZE end
function Grid.getCellSize() return GRID_CELL_SIZE end

local function getIndex(x, y)
    return x + y * CHUNK_SIZE
end

local function getChunkKey(x, y)
    --[[
    TODO: maybe we should benchmark this..?
    I think this could be pretty inefficient since it creates
    an allocation under the hood (even though its interned!!)
    Would maybe create an annoying amount of garbage.
    We should seek to optimize this in the future I think.
    
    Take a look a "Negatve integer pairing function Szudzik pairing"
    (ask claude or soemthng)
    ]]
    return x .. "," .. y
end

local function getOrCreateChunk(chunks, x, y)
    local key = getChunkKey(x, y)
    local chunk = chunks[key]
    if not chunk then
        chunk = {}
        chunks[key] = chunk
    end
    return chunk
end

-- GENERAL --

function Grid.getChunk(x, y)
    local cx = floor(x / CHUNK_SIZE)
    local cy = floor(y / CHUNK_SIZE)
    return cx, cy
end

function Grid.getLocalPos(x, y)
    local lx = x % CHUNK_SIZE
    local ly = y % CHUNK_SIZE
    if lx < 0 then lx = lx + CHUNK_SIZE end
    if ly < 0 then ly = ly + CHUNK_SIZE end
    return lx, ly
end

-- LAYERS --

function Grid.foreachInChunk(cx, cy, fnCallback)
    local key = getChunkKey(cx, cy)
    local chunk = Grid.mainLayer[key]
    if not chunk then
        return
    end

    for i = 0, (CHUNK_SIZE * CHUNK_SIZE) - 1, 1 do
        local lx = i % CHUNK_SIZE
        local ly = floor(i / CHUNK_SIZE)
        local gx = cx * CHUNK_SIZE + lx
        local gy = cy * CHUNK_SIZE + ly
        fnCallback(chunk[i], gx, gy)
    end
end

function Grid.iterateNeighbors(gx, gy, fnCallback)
    for _, neighbor in ipairs(NEIGHBORS) do
        -- TODO: (flam) - I think we should check for out of bounds
        local nx = gx + neighbor[1]
        local ny = gy + neighbor[2]
        fnCallback(neighbor[1], neighbor[2], nx, ny)
    end
end

-- GROUND LAYER --

function Grid.setGround(x, y, val)
    local cx, cy = Grid.getChunk(x, y)
    local lx, ly = Grid.getLocalPos(x, y)
    local chunk = getOrCreateChunk(Grid.groundLayer, cx, cy)
    chunk[getIndex(lx, ly)] = val
end

function Grid.getGround(x, y)
    local cx, cy = Grid.getChunk(x, y)
    local lx, ly = Grid.getLocalPos(x, y)
    local key = getChunkKey(cx, cy)
    local chunk = Grid.groundLayer[key]
    local val = chunk and chunk[getIndex(lx, ly)]
    return val or Grid.groundFallback
end

function Grid.setGroundFallback(val)
    Grid.groundFallback = val
end

-- MAIN LAYER --

function Grid.setCell(x, y, val)
    local cx, cy = Grid.getChunk(x, y)
    local lx, ly = Grid.getLocalPos(x, y)
    local chunk = getOrCreateChunk(Grid.mainLayer, cx, cy)
    chunk[getIndex(lx, ly)] = val
end

function Grid.getCell(x, y)
    local cx, cy = Grid.getChunk(x, y)
    local lx, ly = Grid.getLocalPos(x, y)
    local key = getChunkKey(cx, cy)
    local chunk = Grid.mainLayer[key]
    if not chunk then
        return nil
    end
    return chunk[getIndex(lx, ly)]
end

function Grid.clearCell(x, y)
    Grid.setCell(x, y, nil)
end

-- WORLD/GRID CONVERSION --

function Grid.gridToWorld(gx, gy)
    return gx * GRID_CELL_SIZE, gy * GRID_CELL_SIZE
end

function Grid.worldToGrid(wx, wy)
    return floor(wx / GRID_CELL_SIZE), floor(wy / GRID_CELL_SIZE)
end

-- CELL --
-- INFO: (flam) - possible keys in data:
--                  - getImage (function)
--                  - onTick (function)
--                  - physics (table)
function Grid.defineCellType(name, data)
    Grid.cellTypes[name] = data
end

function Grid.getCellType(name)
    return Grid.cellTypes[name]
end

return Grid
