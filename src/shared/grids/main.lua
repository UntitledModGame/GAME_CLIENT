local Grid = require("src.shared.grids.grid")

local camera = {
    x = -360,
    y = -360,
    speed = 360,
    zoom = 1.0,
}

function love.load()
    print("Testing grids")
    local dw, dh = love.window.getDesktopDimensions()
    local ww, wh = 1280, 720
    love.window.setMode(ww, wh)
    love.window.setPosition((dw - ww) / 2, (dh - wh) / 2)
    love.graphics.setDefaultFilter("nearest", "nearest")

    Grid.defineCellType("mod:white", "circle")
    Grid.setCell(1, 1, "mod:white")
    Grid.setCell(1, 4, "mod:white")
    Grid.setCell(4, 1, "mod:white")
    Grid.setCell(4, 4, "mod:white")

    Grid.setCell(0, 0, "top left")
    Grid.setCell(31, 0, "top right")
    Grid.setCell(0, 31, "bottom left")
    Grid.setCell(31, 31, "bottom right")

    Grid.defineCellType("mod:tree", {
        --INFO: (flam) - for now make it like getColor
        getImage = function(cell, x, y)
            if x == 15 and y == 15 then
                return { 1, 0, 0, 0.5 }
            end
            if x == 15 and y == 17 then
                return { 0, 1, 0, 0.5 }
            end
            if x == 17 and y == 15 then
                return { 0, 0, 1, 0.5 }
            end
            if x == 17 and y == 17 then
                return { 1, 1, 0, 0.5 }
            end
            return { 0, 1, 0, 0.5 }
        end
    })

    Grid.setCell(15, 15, "mod:tree")
    Grid.setCell(15, 17, "mod:tree")
    Grid.setCell(17, 15, "mod:tree")
    Grid.setCell(17, 17, "mod:tree")

    Grid.setGroundFallback("fallback")
    Grid.setGround(0, 0, "dirt")
    Grid.setGround(31, 0, "dirt")
    Grid.setGround(0, 31, "dirt")
    Grid.setGround(31, 31, "dirt")
end

function love.update(dt)
    local dx = 0
    local dy = 0
    if love.keyboard.isDown("w") then
        dy = -1
    elseif love.keyboard.isDown("s") then
        dy = 1
    end
    if love.keyboard.isDown("a") then
        dx = -1
    elseif love.keyboard.isDown("d") then
        dx = 1
    end

    camera.x = camera.x + camera.speed * dt * dx
    camera.y = camera.y + camera.speed * dt * dy
end

function love.keypressed(key)
    if key == "n" then
        camera.zoom = camera.zoom / 1.1
    elseif key == "m" then
        camera.zoom = camera.zoom * 1.1
    elseif key == "b" then
        camera.zoom = 1.0
    end
end

function love.draw()
    love.graphics.setBackgroundColor(0, 0, 0, 1)
    local cellSize = Grid.getCellSize()
    local chunkSize = Grid.getChunkSize()

    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)
    love.graphics.scale(camera.zoom)

    local sw, sh = love.graphics.getDimensions()
    local sx, sy = Grid.worldToGrid(0, 0)
    local ex, ey = Grid.worldToGrid(sw, sh)
    local csx, csy = Grid.getChunk(sx, sy)
    local cex, cey = Grid.getChunk(ex, ey)

    local chunkRegion = chunkSize * cellSize

    for cy = csy, cey do
        for cx = csx, cex do
            local chunkX = cx * chunkRegion
            local chunkY = cy * chunkRegion
            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.rectangle("line", chunkX, chunkY, chunkRegion, chunkRegion)

            Grid.foreachInChunk(cx, cy, function(cell, gx, gy)
                local wx, wy = Grid.gridToWorld(gx, gy)
                love.graphics.setColor(0.4, 0.4, 0.4, 1)
                love.graphics.rectangle("line", wx, wy, cellSize, cellSize)

                local ground = Grid.getGround(gx, gy)
                if ground then
                    if ground == "dirt" then
                        love.graphics.setColor(0.7, 0.7, 0.7, 1)
                        love.graphics.rectangle("fill", wx + 1, wy + 1, cellSize - 2, cellSize - 2)
                    elseif ground == "fallback" then
                        love.graphics.setColor(0.7, 0.7, 0.7, 0.3)
                        love.graphics.rectangle("fill", wx + 1, wy + 1, cellSize - 2, cellSize - 2)
                    end
                end

                local main = Grid.getCell(gx, gy)
                if main then
                    local cellType = Grid.getCellType(main)
                    if cellType then
                        if cellType == "circle" then
                            love.graphics.setColor(1, 1, 1, 0.5)
                            love.graphics.circle(
                                "fill",
                                wx + cellSize/2,
                                wy + cellSize/2,
                                cellSize/2,
                                cellSize/2
                            )
                        elseif cellType.getImage then
                            local img = cellType.getImage(main, gx, gy)
                            love.graphics.setColor(img)
                            love.graphics.rectangle("fill", wx + 1, wy + 1, cellSize - 2, cellSize - 2)
                        end
                    end

                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.print(main, wx, wy)
                end
            end)

            local label = "chunk:" .. chunkX .. "," .. chunkY
            local chunkCenterX = chunkX + chunkRegion / 2
            local chunkCenterY = chunkY + chunkRegion / 2
            love.graphics.setColor(1, 1, 0, 1)
            love.graphics.print(label, chunkCenterX, chunkCenterY)
        end
    end

    love.graphics.pop()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Press WASD to move the camera around", 0, 0)
    love.graphics.print("Press n/m to zoom in/out the camera", 0, 16)
    love.graphics.print("Press b to reset camera zoom", 0, 32)
end
