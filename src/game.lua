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

    self.map = sti.new("assets/map.lua")
    self.map:addCustomLayer("GameObjects", 3)

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
        self.GameObjects.player:update(game.map, dt)
    end

    self.settings = {
        window = {
            w = g.getWidth(),
            h = g.getHeight()
        },
        scale = 3
    }

    self.audio = {
        bg = a.newSource("assets/wind.ogg", "stream")
    }
    self.audio.bg:setLooping(true)
    self.audio.bg:play()

    local imgData = img.newImageData(4, 4)
    for i = 0, 3, 1 do
        for j = 0, 3, 1 do
            imgData:setPixel(i, j, 150, 150, 150, 255)
        end
    end
    self.snowParticles = g.newParticleSystem(g.newImage(imgData), 256)
    self.snowParticles:setParticleLifetime(20, 30)
    self.snowParticles:setEmissionRate(10)
    self.snowParticles:setSpeed(50, 100)
    self.snowParticles:setDirection(math.pi/2)
    self.snowParticles:setAreaSpread("normal", 50*16, 0)
    self.snowParticles:start()
end

-- Also entered, leaving and left
function game:entering()
end

function game:draw()
    g.push()
        g.scale(self.settings.scale, self.settings.scale)
        local player = self.map.layers["GameObjects"].GameObjects.player
        g.translate(-player.p.x + self.settings.window.w / (2 * self.settings.scale), -player.p.y + self.settings.window.h / (2 * self.settings.scale))
        self.map:setDrawRange(player.p.x - self.settings.window.w / 2, player.p.y - self.settings.window.h / 2, self.settings.window.w, self.settings.window.h) 
        self.map:drawLayer(self.map.layers["Collision"])
        self.map:drawLayer(self.map.layers["GameObjects"])
        g.draw(self.snowParticles, 50*16, 0)
    g.pop()
end

function game:update(dt)
    self.map:update(dt)
    self.snowParticles:update(dt)
end

return game
