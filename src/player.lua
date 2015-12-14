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

local rectIntersect = function(x1, y1, w1, h1, x2, y2, w2, h2)
    return not ((x1 > (x2 + w2)) or ((x1 + w1) < x2) or (y1 > (y2 + h2)) or ((y1 + h1) < y2))
end

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
    update = function(self, game, dt)
        local isSpring = function(x, y)
            local properties = game.map:getTileProperties("Collision", x + 1, y + 1).properties
            return properties and properties.Spring
        end
        local isSolid = function(x, y)
            -- Because why wouldn't it be 1-indexed >_>
            local properties = game.map:getTileProperties("Collision", x + 1, y + 1).properties
            return properties and properties.Solid
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
        self.a.y = GRAVITY

        if game.settings.keys.left and k.isDown(game.settings.keys.left) then self.a.x = self.a.x - ACCELERATION end
        if game.settings.keys.right and k.isDown(game.settings.keys.right) then self.a.x = self.a.x + ACCELERATION end

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
        local nlx, nuy = game.map:convertScreenToTile(newX, newY)
        local nrx, ndy = game.map:convertScreenToTile(newX + self.d.w, newY + self.d.h)

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
                self.p.x = select(1, game.map:convertTileToScreen(firstFree, 0))
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

        -- Check intersections with objects in the world
        nlx, nuy = game.map:convertScreenToTile(self.p.x, self.p.y)
        nrx, ndy = game.map:convertScreenToTile(self.p.x + self.d.w, self.p.y + self.d.h)

        nlx = math.floor(nlx)
        nuy = math.floor(nuy)
        nrx = math.floor(nrx)
        ndy = math.floor(ndy)

        for index, item in ipairs(game.items) do
            local show = false
            if (item.x == nlx or item.x == nrx) and
                (item.y == nuy or item.y == ndy) then
                if not item.collected then
                    item.collected = true
                    if not self.foundFirst then
                        game:show("Looks like you found yourself a time capsule of sorts. Let's see what's in here...", 3)
                    end
                    game:show("You found: " .. item.description, item.duration)
                    if not self.foundFirst then
                        self.foundFirst = true
                        game:show("You catalogue the item and continue your journey.", 3)
                    end
                    game.items.left = game.items.left - 1
                    show = true
                elseif (#game.messages == 0) then
                    game:show("You have already been here. I guess no one minds if you take another look though.", 2.5)
                    game:show("You found: " .. item.description, item.duration)
                    show = true
                end
                
                if show then
                    if game.items.left > 0 then
                        local form1 = " is "
                        local form2 = " item"
                        if game.items.left > 1 then
                            form1 = " are "
                            form2 = form2 .. "s" 
                        end
                        game:show("You have a hunch that there " .. form1 .. " still " .. game.items.left .. form2 .. " left...", 2)
                    else
                        game:show("You have a feeling that everything worth finding has now been found.", 5)
                        game:show("This concludes your current assignment as a planetary observer.", 7)
                    end
                end
                break
            end
        end

        if (game.scaleDown.x == nlx or game.scaleDown.x == nrx) and 
            (game.scaleDown.y == nuy or game.scaleDown.y == ndy) then
            if not game.scaleDown.pressed then
                game:changeScale(-1)
                game.scaleDown.pressed = true
            end
        else
            game.scaleDown.pressed = false
        end

        if (game.scaleUp.x == nlx or game.scaleUp.x == nrx) and
            (game.scaleUp.y == nuy or game.scaleUp.y == ndy) then
            if not game.scaleUp.pressed then
                game:changeScale(1)
                game.scaleUp.pressed = true
            end
        else
            game.scaleUp.pressed = false
        end

        if self.currAnimation then self.currAnimation:update(dt) end
    end,
    draw = function(self)
        self:checkAnimation()
        self.currAnimation:draw(self.spritesheet, self.p.x + (self.d.w - self.d.sprite.w) / 2, self.p.y + (self.d.h - self.d.sprite.h) / 2)
    end,
    checkAnimation = function(self)
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
    end
}
