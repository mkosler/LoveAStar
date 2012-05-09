function love.conf(t)
	t.title = "AStarDemo"
    t.author = "MarekkPie"
    t.identity = nil
    t.version = "0.8.0"
    t.console = false
    t.screen.width = 800
    t.screen.height = 800
    t.screen.fullscreen = false
    t.screen.vsync = true
    t.screen.fsaa = 0
    t.modules.joystick = false
    t.modules.audio = false
    t.modules.keyboard = true
    t.modules.event = true
    t.modules.image = false
    t.modules.graphics = true
    t.modules.timer = true
    t.modules.mouse = true
    t.modules.sound = false
    t.modules.physics = false
end
