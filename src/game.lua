local k = love.keyboard
local g = love.graphics
local img = love.image
local m = love.mouse
local a = love.audio
local win = love.window
local sti = require "lib.sti"

game = {}

function game:init()
    g.setBackgroundColor(120, 125, 140)

    self.settings = {
        scale = 3,
        baseScale = {
            w = 200,
            h = 150,
            font = 8
        },
        keys = {
            left = nil,
            right = nil
        }
    }

    self.map = sti.new("assets/map.lua")
    self.map:addCustomLayer("GameObjects", 3)

    -- There has to be a better way to handle collisions with objects, but w/e
    local scaleDownProperties = self.map:getObjectProperties("Objects", "ScaleDown")
    local sDX, sDY = self.map:convertScreenToTile(scaleDownProperties.x, scaleDownProperties.y)
    local scaleUpProperties = self.map:getObjectProperties("Objects", "ScaleUp")
    local sUX, sUY = self.map:convertScreenToTile(scaleUpProperties.x, scaleUpProperties.y)

    self.scaleDown = {
        x = math.floor(sDX),
        y = math.floor(sDY),
        pressed = false
    }

    self.scaleUp = {
        x = math.floor(sUX),
        y = math.floor(sUY),
        pressed = false
    }

    self.changeScale = function(self, delta)
        local newScale = self.settings.scale + delta
        if newScale > 0 and newScale < 6 then 
            self.settings.scale = newScale
            g.setNewFont(self.settings.baseScale.font * self.settings.scale)
            win.setMode(self.settings.scale * self.settings.baseScale.w, self.settings.scale * self.settings.baseScale.h)
        end
    end
    g.setNewFont(self.settings.baseScale.font * self.settings.scale)

    local playerSpawnProperties = self.map:getObjectProperties("Objects", "PlayerSpawn")
    local GOLayer = self.map.layers["GameObjects"]
    
    GOLayer.GameObjects = {    
        player = require "src.player"
    }
    GOLayer.GameObjects.player:init(playerSpawnProperties.x, playerSpawnProperties.y)

    function GOLayer:draw()
        self.GameObjects.player:draw()
    end

    function GOLayer:update(dt) 
        self.GameObjects.player:update(game, dt)
    end

    self.audio = {
        bg = a.newSource("assets/wind.ogg", "stream")
    }
    self.audio.bg:setLooping(true)
    self.audio.bg:play()

    self.items = {}
    for index, item in pairs(self.map.layers["Objects"].objects) do
        if item.type == "Item" then
            x, y = self.map:convertScreenToTile(item.x, item.y) -- all items are single tile
            self.items[#self.items + 1] = {
                x = math.floor(x),
                y = math.floor(y),
                description = item.properties.description,
                duration = item.properties.duration,
                collected = false
            }
        end
    end
    self.items.left = #self.items

    self.messages = {}
    self.messages.alpha = 0
end

function game:show(message, duration)
    self.messages[#self.messages + 1] = {
        message = message,
        duration = duration
    }
end

function game:draw()
    local w = self.settings.scale * self.settings.baseScale.w
    local h = self.settings.scale * self.settings.baseScale.h

    g.push()
        g.scale(self.settings.scale, self.settings.scale)
        local player = self.map.layers["GameObjects"].GameObjects.player
        g.translate(-player.p.x + self.settings.baseScale.w / 2.0, -player.p.y + self.settings.baseScale.h / 2.0)
        self.map:setDrawRange(player.p.x - w / 2.0, player.p.y - h / 2.0, w, h)
        self.map:drawLayer(self.map.layers["Background"])
        self.map:drawLayer(self.map.layers["Collision"])
        self.map:drawLayer(self.map.layers["GameObjects"])
        self.map:drawLayer(self.map.layers["Foreground"])
    g.pop()
    if #self.messages > 0 then
        g.setColor(0, 0, 0, self.messages.alpha)
        g.printf(self.messages[1].message, 10, 10, self.settings.baseScale.w * self.settings.scale - 20, "center")
        g.setColor(255, 255, 255)
    end
end

function game:keypressed(key, unicode)
    if not self.settings.keys.left then
        self.settings.keys.left = key
    elseif not self.settings.keys.right and key ~= self.settings.keys.left then
        self.settings.keys.right = key
    end
end

function game:update(dt)
    if not self.configDone and #self.messages == 0 then
        if not self.settings.keys.left then
            self:show("Try moving left", 0.5)
        elseif not self.settings.keys.right then
            self:show("And now right", 0.5) 
        else
            self.configDone = true
            self:show("Left bound to " .. self.settings.keys.left .. ". Right bound to " .. self.settings.keys.right .. ".", 3)
            self:show("I'll leave the rest to you then.", 3)
        end
    end

    if #self.messages > 0 then
        if not self.messages.direction then 
            self.messages.direction = 1 
        elseif self.messages.direction == 0 then
            self.messages[1].duration = self.messages[1].duration - dt
            if self.messages[1].duration < 0 then
                self.messages.direction = -1
            end
        end

        self.messages.alpha = self.messages.alpha + 255*2*self.messages.direction*dt
        if self.messages.alpha > 255 then 
            self.messages.alpha = 255 
            self.messages.direction = 0
        elseif self.messages.alpha < 0 then 
            self.messages.alpha = 0 
            self.messages.direction = nil
            table.remove(self.messages, 1)
        end
    end

    self.map:update(dt)
end

return game
