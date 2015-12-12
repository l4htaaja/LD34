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
        player = require "src.player"
    }
    GOLayer.GameObjects.player.p.x = playerSpawnProperties.x
    GOLayer.GameObjects.player.p.y = playerSpawnProperties.y

    function GOLayer:draw()
        self.GameObjects.player:draw()
    end

    function GOLayer:update(dt) 
        self.GameObjects.player:update(game.map, dt)
    end

    self.settings = {
        window = {
            w = g.getWidth(),
            h = g.getHeight()
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
