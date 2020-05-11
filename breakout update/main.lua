require 'src/Dependencies'

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('Breakout')

    math.randomseed(os.time())

    gFonts = {
        ['small'] = love.graphics.setNewFont('fonts/font.ttf', 8),
        ['medium'] = love.graphics.setNewFont('fonts/font.ttf', 16),
        ['large'] = love.graphics.setNewFont('fonts/font.ttf', 32),
    }

    gTexture = {
        ['background'] = love.graphics.newImage('graphics/background.png'),
        ['arrow'] = love.graphics.newImage('graphics/arrows.png'),
        ['main'] = love.graphics.newImage('graphics/breakout.png'),
        ['heart'] = love.graphics.newImage('graphics/hearts.png'),
        ['particle'] = love.graphics.newImage('graphics/particle.png')
    }

    gFrames = {
        ['paddles'] = generateQuadPaddles(gTexture['main']),
        ['balls'] = generateQuadBalls(gTexture['main']),
        ['bricks'] = generateQuadBricks(gTexture['main']),
        ['hearts'] = generateQuads(gTexture['heart'], 10, 9),
        ['arrows'] = generateQuads(gTexture['arrow'], 24, 24),
        ['powerups'] = generateQuadPowerups(gTexture['main'])
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true,
        canvas = false
    })

    gSounds = {
        ['paddle-hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall-hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static'),
        ['confirm'] = love.audio.newSource('sounds/confirm.wav', 'static'),
        ['select'] = love.audio.newSource('sounds/select.wav', 'static'),
        ['no-select'] = love.audio.newSource('sounds/no-select.wav', 'static'),
        ['brick-hit-1'] = love.audio.newSource('sounds/brick-hit-1.wav', 'static'),
        ['brick-hit-2'] = love.audio.newSource('sounds/brick-hit-2.wav', 'static'),
        ['hurt'] = love.audio.newSource('sounds/hurt.wav', 'static'),
        ['victory'] = love.audio.newSource('sounds/victory.wav', 'static'),
        ['recover'] = love.audio.newSource('sounds/recover.wav', 'static'),
        ['high-score'] = love.audio.newSource('sounds/high_score.wav', 'static'),
        ['pause'] = love.audio.newSource('sounds/pause.wav', 'static'),
        ['metal-hit'] = love.audio.newSource('sounds/metal_hit.wav', 'static'),
        ['powerup'] = love.audio.newSource('sounds/powerup.wav', 'static'),
        ['paddle-up'] = love.audio.newSource('sounds/paddle_up.wav', 'static'),
        ['paddle-down'] = love.audio.newSource('sounds/paddle_down.wav', 'static'),

        ['music'] = love.audio.newSource('sounds/music.wav', 'static')
    }

    gPowerups = {
        ['key'] = Key(),
        ['add-balls'] = AddBalls() 
    }

    gStateMachine = StateMachine {
        ['start'] = function() return StartState() end,
        ['play'] = function() return PlayState() end,
        ['serve'] = function() return ServeState() end,
        ['game-over'] = function() return GameOverState() end,
        ['victory'] = function() return VictoryState() end,
        ['high-scores'] = function() return HighScoreState() end,
        ['enter-high-scores'] = function() return EnterHighScoreState() end,
        ['paddle-select'] = function() return PaddleSelectState() end,
    }
    gStateMachine:change('start', {highScores = loadHighScores()})

    gSounds['music']:play()
    gSounds['music']:setLooping(true)

    love.keyboard.keysPressed = {}
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)
    gStateMachine:update(dt)

    love.keyboard.keysPressed = {}
    
    print('Hi probablykory')
end

function love.keypressed(key)
    love.keyboard.keysPressed[key] = true
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

function love.draw()
    push:start()

    local backgroundWidth = gTexture['background']:getWidth()
    local backgroundHeight = gTexture['background']:getHeight()

    love.graphics.draw(gTexture['background'], 0, 0, 0, VIRTUAL_WIDTH / (backgroundWidth - 1), 
        VIRTUAL_HEIGHT / (backgroundHeight - 1))

    gStateMachine:render()

    displayFPS()

    push:finish()
end

function loadHighScores()
    love.filesystem.setIdentity('breakout')

    if love.filesystem.getInfo('breakout.lst', 'file') == nil then
        local scores = ''
        for i = 10, 1, -1 do
            scores = scores .. "SKY\n"
            scores = scores .. tostring(i * 1000) .. '\n'
        end

        love.filesystem.write('breakout.lst', scores)
    end

    local name  = true
    local currentName = nil
    local counter = 1

    local scores = {}

    for i = 1, 10 do
        scores[i] = {
            name = nil,
            score = nil
        }
    end

    for line in love.filesystem.lines('breakout.lst') do
        if name then
            scores[counter].name = string.sub(line, 1, 3)
        else
            scores[counter].score = tonumber(line)
            counter = counter + 1
        end

        name = not name
    end

    return scores
end

function displayFPS()
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 5, 5)
    love.graphics.setColor(1, 1, 1, 1)
end

function renderHealth(health)
    local healthX = VIRTUAL_WIDTH - 100

    for i = 1, health do
        love.graphics.draw(gTexture['heart'], gFrames['hearts'][1], healthX, 4)
        healthX = healthX + 11
    end

    for i = 1, 3 - health do
        love.graphics.draw(gTexture['heart'], gFrames['hearts'][2], healthX, 4)
        healthX = healthX + 11
    end
end

function renderScore(score)
    love.graphics.setFont(gFonts['small'])
    love.graphics.print('Score:', VIRTUAL_WIDTH - 60, 5)
    love.graphics.printf(tostring(score), VIRTUAL_WIDTH - 45, 5, 40, 'right')
end