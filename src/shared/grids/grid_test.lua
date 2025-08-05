--NOTE: (flam) - maybe we should use a unit testing framework?

local Grid = require("src.shared.grids.grid")

function TestGrid()
    assert(type(Grid) == "table")

    print("Testing defineCellType and getCellType...")
    Grid.defineCellType("mod:test", "test cell")
    assert(Grid.getCellType("mod:test") == "test cell")

    assert(Grid.getGround(0, 0) == nil)

    print("Testing setGround and getGround...")
    Grid.setGround(0, 0, "ground0")
    assert(Grid.getGround(0, 0) == "ground0")
    Grid.setGround(1, 1, "ground1")
    assert(Grid.getGround(1, 1) == "ground1")

    print("Testing setGroundFallback...")
    Grid.setGroundFallback("fallback")
    assert(Grid.getGround(3, 3) == "fallback")

    print("Testing setCell and getCell...")
    Grid.setCell(0, 0, "cell0")
    assert(Grid.getCell(0, 0) == "cell0")

    Grid.setCell(1, 1, "cell1")
    assert(Grid.getCell(1, 1) == "cell1")

    Grid.setCell(25, 25, "cell25")
    assert(Grid.getCell(25, 25) == "cell25")

    Grid.setCell(26, 26, "cell26")
    assert(Grid.getCell(26, 26) == "cell26")

    Grid.setCell(27, 27, "cell27")
    assert(Grid.getCell(27, 27) == "cell27")

    Grid.setCell(31, 31, "cell31")
    assert(Grid.getCell(31, 31) == "cell31")

    print("Testing clearCell...")
    Grid.clearCell(1, 1)
    assert(Grid.getCell(1, 1) == nil)

    do
        print("Testing worldToGrid...")
        local xx = 128
        local yy = 128
        local gx, gy = Grid.worldToGrid(xx, yy)
        assert(gx == 4)
        assert(gy == 4)

        print("Testing gridToWorld...")
        local wx, wy = Grid.gridToWorld(gx, gy)
        assert(wx == xx)
        assert(wy == yy)
    end

    print("Testing getChunk...")
    do
        local cx, cy = Grid.getChunk(0, 0)
        assert(cx == 0)
        assert(cy == 0)
    end

    do
        local cx, cy = Grid.getChunk(16, 16)
        assert(cx == 0)
        assert(cy == 0)
    end

    do
        local cx, cy = Grid.getChunk(32, 32)
        assert(cx == 1)
        assert(cy == 1)
    end

    print("Testing getLocalPos...")
    do
        local lx, ly = Grid.getLocalPos(32, 32)
        assert(lx == 0)
        assert(ly == 0)
    end

    do
        local lx, ly = Grid.getLocalPos(31, 31)
        assert(lx == 31)
        assert(ly == 31)
    end

    do
        print("Testing foreachInChunk...")
        Grid.foreachInChunk(0, 0, function(cell, gx, gy)
            if cell == "cell0" then
                assert(gx == 0)
                assert(gy == 0)
            elseif cell == nil then
                assert(gx >= 0 and gx <= 31)
                assert(gy >= 0 and gy <= 31)
            elseif cell == "cell31" then
                assert(gx == 31)
                assert(gy == 31)
            end
        end)
    end

    do
        print("Testing iterateNeighbors...")
        Grid.iterateNeighbors(26, 26, function(dx, dy, gx, gy)
            if dx == -1 and dy == 0 then
                assert(gx == 25 and gy == 26)
            elseif dx == 1 and dy == 0 then
                assert(gx == 27 and gy == 26)
            elseif dx == 0 and dy == -1 then
                assert(gx == 26 and gy == 25)
            elseif dx == 0 and dy == 1 then
                assert(gx == 26 and gy == 27)
            end
        end)
    end

    print("All test passed!")
end

TestGrid()
