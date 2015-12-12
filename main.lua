-- #################
-- INIT AND SHUTDOWN
-- #################

-- Runs once when the game loads
function love.load()
    --math.randomseed(os.time())
    --math.random()

    Timer = require "lib.timer"
    GS = require "lib.venus"
    GS.timer = Timer
    GS.effect = "fade"
    GS.duration = 1
    GS.registerEvents()

    game = require "src.game"

    GS.switch(game)
end

-- Runs once when closing down the game
function love.quit()
end

-- #############
-- WINDOW EVENTS
-- #############

-- Resize event
function love.resize(w, h)
end

-- When window gains or loses focus
function love.focus(focus)
end

-- Called when window visibility changes
function love.visible(visible)
end

-- ###############
-- KEYBOARD EVENTS
-- ###############

-- On keyboard keypress
function love.keypressed(key, unicode)
end

-- On keyboard keyrelease
function love.keyreleased(key, unicode)
end

-- When text is entered
function love.textinput(text)
end

-- ############
-- MOUSE EVENTS
-- ############

-- When mouse enter and leaves
function love.mousefocus(focus)
end

-- On mousepress
function love.mousepressed(x, y, button)
end

-- On mousereleased
function love.mousereleased(x, y, button)
end

-- When the mouse moves
function love.mousemoved(x, y, dx, dy)
end

-- ########
-- JOYSTICK
-- ########

-- When joystick is connected (also after love.load for every joystick!)
function love.joystickadded(joystick)
end

-- When joystick is disconnected
function love.joystickremoved(joystick)
end

-- More axis moving?
function love.joystickaxis(joystick, axis, value)
end

-- Joystick hat... sheesh.
function love.joystickhat(joystick, hat, direction)
end

-- Joystick buttonpress
function love.joystickpressed(joystick, button)
end

-- button released.
function love.joystickreleased(joystick, button)
end

-- When gamepad axis is moved
function love.gamepadaxis(joystick, axis)
end

-- On gamepad button press
function love.gamepadpressed(joystick, button)
end

-- When button is released
function love.gamepadreleased(joystick, button)
end

-- #########
-- GAME LOOP
-- #########

-- Main function (using default for now)
-- function love.run()
-- end

-- Rendering
function love.draw()
end

-- Updates with variable delta time
function love.update(dt)
    Timer.update(dt)
end
