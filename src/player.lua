local k = love.keyboard
local g = love.graphics

local anim8 = require "lib.anim8.anim8"

local GRAVITY = 150
local ACCELERATION = 400
local DRAG = 10 -- Drag coefficient something something
local CLIMB_ACCELERATION = -100
local MAX_VELOCITY_X = 75
local MAX_VELOCITY_Y = 150
local SPRING_VELOCITY = -150

return {
    spritesheet = g.newImage("assets/player.png"),
    currAnimation = nil,
    anims = {
    },
    d = {
        w = 8,
        h = 14,
        sprite = {
            w = 10,
            h = 16
        }
    },
    p = {
        x = 0,
        y = 0
    }, 
    direction = 1,
    v = {
        x = 0,
        y = 0
    },
    a = {
        x = 0,
        y = 0
    },
    state = {
        grounded = false,
        huggingLeft = false,
        huggingRight = false,
        climbing = false
    },
    init = function(self, x, y)
        self.p.x = x
        self.p.y = y

        self.spritesheet:setFilter("nearest", "nearest")
        local grid = anim8.newGrid(self.d.sprite.w, self.d.sprite.h, self.spritesheet:getWidth(), self.spritesheet:getHeight())
        self.anims.placeHolder = anim8.newAnimation(grid(7, 1), 999)
        self.anims.idleLeft = anim8.newAnimation(grid("1-6", 1), 0.35)
        self.anims.idleRight = anim8.newAnimation(grid("1-6", 2), 0.35)
        self.anims.moveLeft = anim8.newAnimation(grid("1-5", 3), 0.1)
        self.anims.moveRight = anim8.newAnimation(grid("1-5", 4), 0.1)
        self.anims.risingLeft = anim8.newAnimation(grid(6, 3), 999)
        self.anims.fallingLeft = anim8.newAnimation(grid(7, 3), 999)
        self.anims.risingRight = anim8.newAnimation(grid(6, 4), 999)
        self.anims.fallingRight = anim8.newAnimation(grid(7, 4), 999)
        self.anims.climbingLeft = anim8.newAnimation(grid("1-4", 5), 0.2)
        self.anims.climbingRight = anim8.newAnimation(grid("1-4", 6), 0.2)
    end,
    update = function(self, map, dt)
        local isSpring = function(x, y)
            local properties = map:getTileProperties("Collision", x + 1, y + 1).properties
            return properties and properties.Spring
        end
        local isSolid = function(x, y)
            -- Because why wouldn't it be 1-indexed >_>
            local properties = map:getTileProperties("Collision", x + 1, y + 1).properties
            return properties and properties.Solid
        end

        local lx, uy = map:convertScreenToTile(self.p.x, self.p.y)
        local rx, dy = map:convertScreenToTile(self.p.x + self.d.w, self.p.y + self.d.h)

        -- convertScreenToTile doesn't automatically round (convertTileToScreen doesn't expect integers either!)
        lx = math.floor(lx)
        uy = math.floor(uy)
        rx = math.floor(rx)
        dy = math.floor(dy)

        -- Input
        self.a.x = 0
        self.a.y = GRAVITY

        if k.isDown("left") then self.a.x = self.a.x - ACCELERATION end
        if k.isDown("right") then self.a.x = self.a.x + ACCELERATION end

        -- Vertical movement
        local spring = self.state.grounded and (isSpring(lx, dy + 1) or isSpring(rx, dy + 1))
        local canClimbLeft = self.state.huggingLeft and (isSolid(lx - 1, dy) or isSolid(lx - 1, uy))
        local canClimbRight = self.state.huggingRight and (isSolid(rx + 1, dy) or isSolid(rx + 1, uy))

        -- Physics
        -- Check spring / climbing first
        --
        -- These could very well be "active objects" too
        if spring then
            self.v.y = SPRING_VELOCITY
        end

        self.state.climbing = false
        if (canClimbLeft and self.a.x < 0) or (canClimbRight and self.a.x > 0) then
            self.a.y = CLIMB_ACCELERATION
            self.state.climbing = true
        end
       
        -- Drag
        if self.a.x == 0 then -- no input
            if self.v.x > 1 then
                self.a.x = -DRAG*self.v.x
            elseif self.v.x < -1 then
                self.a.x = -DRAG*self.v.x
            else
                self.a.x = 0
                self.v.x = 0
            end            
        end

        self.v.x = self.v.x + self.a.x * dt
        -- Cap speed (Should probably handle this through
        -- "diminishing returns")
        if math.abs(self.v.x) > MAX_VELOCITY_X then
            if self.v.x < 0 then
                self.v.x = -MAX_VELOCITY_X
            else
                self.v.x = MAX_VELOCITY_X
            end
        end
        self.v.y = self.v.y + self.a.y * dt
        if math.abs(self.v.y) > MAX_VELOCITY_Y then
            if self.v.y < 0 then
                self.v.y = -MAX_VELOCITY_Y
            else
                self.v.y = MAX_VELOCITY_Y
            end
        end

        local newX = 0
        local newY = 0
        
        newX = self.p.x + self.v.x * dt
        newY = self.p.y + self.v.y * dt

        -- Check that we are not inside a tile after this!
        -- Also set the different state flags
        local nlx, nuy = map:convertScreenToTile(newX, newY)
        local nrx, ndy = map:convertScreenToTile(newX + self.d.w, newY + self.d.h)

        nlx = math.floor(nlx)
        nuy = math.floor(nuy)
        nrx = math.floor(nrx)
        ndy = math.floor(ndy)

        self.state.huggingLeft = false
        self.state.huggingRight = false
        if self.v.x < 0 then
            self.direction = -1

            local firstFree = nlx
            while (isSolid(firstFree, dy) or isSolid(firstFree, uy)) do
                firstFree = firstFree + 1
            end

            if firstFree == nlx then
                self.p.x = newX
            else
                self.p.x = select(1, map:convertTileToScreen(firstFree, 0))
                self.state.huggingLeft = true
                self.v.x = 0
            end
        elseif self.v.x > 0 then
            self.direction = 1
            
            local firstFree = nrx
            while (isSolid(firstFree, dy) or isSolid(firstFree, uy)) do
                firstFree = firstFree - 1
            end

            if firstFree == nrx then
                self.p.x = newX
            else
                -- Note the arbitrarily small number substracted! That returns the player to the right tile
                self.p.x = select(1, map:convertTileToScreen(firstFree + 1, 0)) - self.d.w - 0.00001
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
                self.p.y = select(2, map:convertTileToScreen(0, firstFree))
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
                self.p.y = select(2, map:convertTileToScreen(0, firstFree + 1)) - self.d.h - 0.00001
                self.state.grounded = true
                self.v.y = 0
            end
        end

        -- Change animation
        if self.state.grounded then
            if self.v.x == 0 then
                if self.direction == 1 then
                    self.currAnimation = self.anims.idleRight
                else
                    self.currAnimation = self.anims.idleLeft
                end
            else
                if self.direction == 1 then
                    self.currAnimation = self.anims.moveRight
                else
                    self.currAnimation = self.anims.moveLeft
                end
            end
        elseif self.state.climbing then
            if self.direction == 1 then
                self.currAnimation = self.anims.climbingRight
            else
                self.currAnimation = self.anims.climbingLeft
            end
        else
            if self.v.y < 0 then
                if self.direction == 1 then
                    self.currAnimation = self.anims.risingRight
                else
                    self.currAnimation = self.anims.risingLeft
                end
            else
                if self.direction == 1 then
                    self.currAnimation = self.anims.fallingRight
                else
                    self.currAnimation = self.anims.fallingLeft
                end
            end
        end

        self.currAnimation:update(dt)
    end,
    draw = function(self)
        self.currAnimation:draw(self.spritesheet, self.p.x + (self.d.w - self.d.sprite.w) / 2, self.p.y + (self.d.h - self.d.sprite.h) / 2)
    end
}
