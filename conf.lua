function love.conf(t)
	t.title = "AStarDemo"
    t.author = "MarekkPie"
    t.identity = nil
    t.version = "11.3.0"
    t.console = false
    t.window.width = 800
    t.window.height = 800
    t.window.fullscreen = false
    t.window.vsync = true
    t.window.fsaa = 0
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
