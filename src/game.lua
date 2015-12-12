local k = love.keyboard
local g = love.graphics
local m = love.mouse
local win = love.window
local sti = require "lib.sti"

game = {}

function game:init()
    g.setBackgroundColor(255, 255, 255)

    self.map = sti.new("assets/map.lua")
    self.map:addCustomLayer("GameObjects", 3)

    local playerSpawnProperties = self.map:getObjectProperties("Objects", "PlayerSpawn")

    local GOLayer = self.map.layers["GameObjects"]
    GOLayer.GameObjects = {    
        player = {
            d = {
                w = 8,
                h = 14
            },
            p = {
                x = playerSpawnProperties.x,
                y = playerSpawnProperties.y
            },
            v = {
                x = 0,
                y = 0
            },
            a = {
                x = 0,
                y = 100 -- gravity
            },
            state = {
                grounded = false,
                huggingLeft = false,
                huggingRight = false
            },
            update = function(self, dt)
                local isSpring = function(x, y)
                    return game.map:getTileProperties("Collision", x + 1, y + 1).id == 1
                end
                local isSolid = function(x, y)
                    -- Because why wouldn't it be 1-indexed >_>
                    return game.map:getTileProperties("Collision", x + 1, y + 1).id == 0 or 
                        game.map:getTileProperties("Collision", x + 1, y + 1).id == 1
                end
        
                local lx, uy = game.map:convertScreenToTile(self.p.x, self.p.y)
                local rx, dy = game.map:convertScreenToTile(self.p.x + self.d.w, self.p.y + self.d.h)
     
                -- convertScreenToTile doesn't automatically round (convertTileToScreen doesn't expect integers either!)
                lx = math.floor(lx)
                uy = math.floor(uy)
                rx = math.floor(rx)
                dy = math.floor(dy)

                -- Input
                self.a.x = 0
                self.a.y = 100

                if k.isDown("left") then self.a.x = self.a.x - 100 end
                if k.isDown("right") then self.a.x = self.a.x + 100 end

                -- Vertical movement
                local spring = self.state.grounded and (isSpring(lx, dy + 1) or isSpring(rx, dy + 1))
                local canClimbLeft = self.state.huggingLeft and (isSolid(lx - 1, dy) or isSolid(lx - 1, uy))
                local canClimbRight = self.state.huggingRight and (isSolid(rx + 1, dy) or isSolid(rx + 1, uy))

                -- Physics
                -- Check spring / climbing first
                --
                -- These could very well be "active objects" too
                if spring then
                    self.v.y = -100
                end

                if (canClimbLeft and self.a.x < 0) or (canClimbRight and self.a.x > 0) then
                    self.a.y = -self.a.y
                end
                
                self.v.x = self.v.x + self.a.x * dt
                self.v.y = self.v.y + self.a.y * dt

                local newX = 0
                local newY = 0
                
                newX = self.p.x + self.v.x * dt
                newY = self.p.y + self.v.y * dt

                -- Check that we are not inside a tile after this!
                -- Also set the different state flags
                local nlx, nuy = game.map:convertScreenToTile(newX, newY)
                local nrx, ndy = game.map:convertScreenToTile(newX + self.d.w, newY + self.d.h)

                nlx = math.floor(nlx)
                nuy = math.floor(nuy)
                nrx = math.floor(nrx)
                ndy = math.floor(ndy)

                self.state.huggingLeft = false
                self.state.huggingRight = false
                if self.v.x < 0 then
                    local firstFree = nlx
                    while (isSolid(firstFree, dy) or isSolid(firstFree, uy)) do
                        firstFree = firstFree + 1
                    end

                    if firstFree == nlx then
                        self.p.x = newX
                    else
                        self.p.x = select(1, game.map:convertTileToScreen(firstFree, 0))
                        self.state.huggingLeft = true
                        self.v.x = 0
                    end
                elseif self.v.x > 0 then
                    local firstFree = nrx
                    while (isSolid(firstFree, dy) or isSolid(firstFree, uy)) do
                        firstFree = firstFree - 1
                    end

                    if firstFree == nrx then
                        self.p.x = newX
                    else
                        -- Note the arbitrarily small number substracted! That returns the player to the right tile
                        self.p.x = select(1, game.map:convertTileToScreen(firstFree + 1, 0)) - self.d.w - 0.00001
                        self.state.huggingRight = true
                        self.v.x = 0
                    end
                end

                self.state.grounded = false
                if self.v.y < 0 then
                    local firstFree = nuy
                    while (isSolid(lx, firstFree) or isSolid(rx, firstFree)) do
                        firstFree = firstFree + 1
                    end

                    if firstFree == nuy then
                        self.p.y = newY
                    else
                        self.p.y = select(2, game.map:convertTileToScreen(0, firstFree))
                        self.v.y = 0
                    end
                elseif self.v.y > 0 then
                    local firstFree = ndy
                    while (isSolid(lx, firstFree) or isSolid(rx, firstFree)) do
                        firstFree = firstFree - 1
                    end
                    
                    if firstFree == ndy then
                        self.p.y = newY
                    else
                        -- Small number here too!
                        self.p.y = select(2, game.map:convertTileToScreen(0, firstFree + 1)) - self.d.h - 0.00001
                        self.state.grounded = true
                        self.v.y = 0
                    end
                end
            end,
            draw = function(self)
                g.setColor(100, 100, 100)
                g.rectangle("fill", self.p.x, self.p.y, self.d.w, self.d.h)
                g.setColor(255, 255, 255)
            end
        }
    }

    function GOLayer:draw()
        self.GameObjects.player:draw()
    end

    function GOLayer:update(dt) 
        self.GameObjects.player:update(dt)
    end

    self.settings = {
        window = {
            w = g.getWidth(),
            h = g.getHeight()
        },
        tile = {
            w = 16,
            h = 16
        }
    }
end

-- Also entered, leaving and left
function game:entering()
end

function game:draw()
    g.push()
        local player = self.map.layers["GameObjects"].GameObjects.player
        g.translate(-player.p.x + self.settings.window.w / 2, -player.p.y + self.settings.window.h / 2)
        self.map:setDrawRange(player.p.x - self.settings.window.w / 2, player.p.y - self.settings.window.h / 2, self.settings.window.w, self.settings.window.h)
        self.map:drawLayer(self.map.layers["Collision"])
        self.map:drawLayer(self.map.layers["GameObjects"])
    g.pop()
end

function game:update(dt)
    self.map:update(dt)
end

return game
