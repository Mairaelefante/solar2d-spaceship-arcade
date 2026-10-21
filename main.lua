
display.setStatusBar(display.HiddenStatusBar)

local physics = require("physics")
physics.start()
physics.setGravity(0,0)

math.randomseed(os.time())

local centerX = display.contentCenterX
local centerY = display.contentCenterY
local screenW = display.contentWidth
local screenH = display.contentHeight

local score = 0
local lives = 3
local gameEnded = false

local stars = {}
local meteors = {}

local starTimer
local meteorTimer

local background = display.newImageRect("assets/background.png", screenW, screenH)
background.x = centerX
background.y = centerY

local fontName = "assets/FredokaOne-Regular.ttf"

local hudGroup = display.newGroup()
local gameGroup = display.newGroup()
local uiGroup = display.newGroup()

local scoreText = display.newText({
    parent = hudGroup,
    text = "Score: 0",
    x = 90,
    y = 40,
    font = fontName,
    fontSize = 34
})

local livesText = display.newText({
    parent = hudGroup,
    text = "Lives: 3",
    x = screenW - 90,
    y = 40,
    font = fontName,
    fontSize = 34
})

local player = display.newImageRect(gameGroup, "assets/spaceship.png", 90, 90)
player.x = centerX
player.y = screenH - 110

physics.addBody(player, "kinematic", {
    radius = 35,
    isSensor = true
})

player.myName = "player"

local function updateHUD()
    scoreText.text = "Score: " .. score
    livesText.text = "Lives: " .. lives
end

local function removeObject(obj, list)
    if obj and obj.removeSelf then
        for i = #list, 1, -1 do
            if list[i] == obj then
                table.remove(list, i)
                break
            end
        end
        display.remove(obj)
    end
end

local function spawnStar()
    if gameEnded then return end

    local star = display.newImageRect(gameGroup, "assets/star.png", 52, 52)
    star.x = math.random(40, screenW - 40)
    star.y = -40
    star.myName = "star"

    physics.addBody(star, "dynamic", {
        radius = 22,
        isSensor = true
    })

    star.gravityScale = 0
    star:setLinearVelocity(0, math.random(180, 260))

    stars[#stars+1] = star
end

local function spawnMeteor()
    if gameEnded then return end

    local meteor = display.newImageRect(gameGroup, "assets/meteor.png", 64, 64)
    meteor.x = math.random(40, screenW - 40)
    meteor.y = -50
    meteor.myName = "meteor"

    physics.addBody(meteor, "dynamic", {
        radius = 28,
        isSensor = true
    })

    meteor.gravityScale = 0
    meteor:setLinearVelocity(0, math.random(220, 320))

    meteors[#meteors+1] = meteor
end

local function cleanupOffscreen()
    for i = #stars, 1, -1 do
        local s = stars[i]
        if s and s.y > screenH + 80 then
            removeObject(s, stars)
        end
    end

    for i = #meteors, 1, -1 do
        local m = meteors[i]
        if m and m.y > screenH + 80 then
            removeObject(m, meteors)
        end
    end
end

local function endGame()
    if gameEnded then return end
    gameEnded = true

    timer.cancel(starTimer)
    timer.cancel(meteorTimer)

    local overlay = display.newRect(uiGroup, centerX, centerY, screenW, screenH)
    overlay:setFillColor(0,0,0,0.75)

    local gameOverText = display.newText({
        parent = uiGroup,
        text = "GAME OVER",
        x = centerX,
        y = centerY - 80,
        font = fontName,
        fontSize = 44
    })

    local finalScore = display.newText({
        parent = uiGroup,
        text = "Final Score: " .. score,
        x = centerX,
        y = centerY - 20,
        font = fontName,
        fontSize = 30
    })

    local button = display.newRoundedRect(uiGroup, centerX, centerY + 80, 180, 60, 18)
    button:setFillColor(0.1, 0.6, 1)

    local buttonText = display.newText({
        parent = uiGroup,
        text = "Restart",
        x = centerX,
        y = centerY + 80,
        font = fontName,
        fontSize = 28
    })

    local function restartGame()
        for i = #stars, 1, -1 do
            removeObject(stars[i], stars)
        end

        for i = #meteors, 1, -1 do
            removeObject(meteors[i], meteors)
        end

        uiGroup:removeSelf()
        uiGroup = display.newGroup()

        score = 0
        lives = 3
        gameEnded = false

        player.x = centerX

        updateHUD()

        starTimer = timer.performWithDelay(700, spawnStar, 0)
        meteorTimer = timer.performWithDelay(1100, spawnMeteor, 0)
    end

    button:addEventListener("tap", restartGame)
end

local function onCollision(event)
    if event.phase ~= "began" then return end

    local obj1 = event.object1
    local obj2 = event.object2

    if not obj1 or not obj2 then return end

    local names = obj1.myName .. "-" .. obj2.myName

    if names == "player-star" or names == "star-player" then
        local starObj = obj1.myName == "star" and obj1 or obj2
        removeObject(starObj, stars)

        score = score + 1
        updateHUD()

    elseif names == "player-meteor" or names == "meteor-player" then
        local meteorObj = obj1.myName == "meteor" and obj1 or obj2
        removeObject(meteorObj, meteors)

        lives = lives - 1
        updateHUD()

        if lives <= 0 then
            endGame()
        end
    end
end

Runtime:addEventListener("collision", onCollision)

local function onTouch(event)
    if gameEnded then return true end

    if event.phase == "began" or event.phase == "moved" then
        player.x = event.x

        local halfWidth = player.width * 0.5

        if player.x < halfWidth then
            player.x = halfWidth
        end

        if player.x > screenW - halfWidth then
            player.x = screenW - halfWidth
        end
    end

    return true
end

Runtime:addEventListener("touch", onTouch)

local function gameLoop()
    cleanupOffscreen()
end

Runtime:addEventListener("enterFrame", gameLoop)

updateHUD()

starTimer = timer.performWithDelay(700, spawnStar, 0)
meteorTimer = timer.performWithDelay(1100, spawnMeteor, 0)
