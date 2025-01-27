function love.load()
    -- Game state
    gameState = "menu"  -- can be "menu", "game", or "upgrades"
    menuState = "animating"  -- can be "animating" or "ready"
    
    -- Get the window dimensions
    windowWidth = love.graphics.getWidth()
    windowHeight = love.graphics.getHeight()

    -- Load and set up background music
    backgroundMusic = love.audio.newSource("music/main_song.wav", "stream")
    backgroundMusic:setLooping(true)  -- Make the music loop
    backgroundMusic:setVolume(0.5)    -- Set to 50% volume, adjust as needed
    backgroundMusic:play()            -- Start playing immediately
    
    -- Menu properties
    menuFont = love.graphics.newFont(48)
    buttonFont = love.graphics.newFont(24)
    
    -- Button properties
    buttonWidth = 200
    buttonHeight = 60
    buttonX = windowWidth/2 - buttonWidth/2
    buttonTargetY = windowHeight/2 + 100  -- Final Y position
    buttonY = windowHeight + buttonHeight  -- Start off-screen
    
    -- Title animation properties
    titleY = windowHeight/3 + 100
    mrX = -200  -- Start off-screen left
    squaryX = windowWidth + 200  -- Start off-screen right
    targetMrX = 0  -- Will be calculated
    targetSquaryX = 0  -- Will be calculated
    animationTimer = 0
    animationPhase = 1  -- 1: sliding text, 2: bullet explosion, 3: button slide, 4: done
    
    -- Animation speeds
    slideDuration = 1.0
    buttonSlideDuration = 0.8
    bulletSpeed = 250
    bulletFadeSpeed = 0.7
    
    -- Title bullet properties
    titleBullets = {}
    
    -- Calculate final text positions
    local title = "Mr. Squary"
    local titleWidth = menuFont:getWidth(title)
    local mrWidth = menuFont:getWidth("Mr. ")
    local squaryWidth = menuFont:getWidth("Squary")
    titleCenterX = windowWidth/2 - titleWidth/2
    targetMrX = titleCenterX
    targetSquaryX = titleCenterX + mrWidth
    
    -- Set the background color to white
    love.graphics.setBackgroundColor(1, 1, 1)
    
    -- Define boundary box dimensions (smaller square)
    boundaryWidth = 200
    boundaryHeight = 200
    boundaryX = windowWidth/2 - boundaryWidth/2
    boundaryY = windowHeight/2 - boundaryHeight/2
    
    -- Define player properties
    playerSize = 50
    playerX = windowWidth/2 - playerSize/2
    playerY = windowHeight/2 - playerSize/2
    
    -- Health system
    maxHealth = 3
    currentHealth = maxHealth
    healthBarWidth = 300
    healthBarHeight = 30
    healthBarX = windowWidth/2 - healthBarWidth/2
    healthBarY = 20
    damageAnimTimer = 0
    damageAnimDuration = 0.5
    lastDamagedHealth = currentHealth
    invulnerableTime = 0.5
    lastHitTime = -invulnerableTime
    isInvulnerable = false
    
    -- Screen shake properties
    shakeTime = 0
    shakeDuration = 0.3
    shakeAmount = 6
    shakeOffset = {x = 0, y = 0}
    
    -- Define movement speed (pixels per second)
    maxSpeed = 200
    slowdownDistance = 100
    
    -- Bullet properties
    bullets = {}
    bulletSpeed = 250
    bulletRadius = 8
    bulletSpawnRate = 0.8
    minBulletSpawnRate = 0.3  -- Fastest spawn rate (lower = faster)
    bulletSpawnRateDecrease = 0.002  -- Changed from 0.01 to 0.002 for slower difficulty increase
    bulletTimer = 0
    homingStrength = 0.5
    gameTime = 0  -- Track how long the current game has been running
    
    -- Create canvas for CRT effect
    canvas = love.graphics.newCanvas()
    
    -- Shader code remains the same
    shaderCode = [[
        extern vec2 screen;
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
            vec4 pixel = Texel(texture, texture_coords);
            float scanline = sin(texture_coords.y * screen.y * 1.5) * 0.15;
            pixel.rgb -= scanline;
            vec2 uv = texture_coords;
            uv = uv * 2.0 - 1.0;
            float d = length(uv);
            uv = uv * (1.0 - d * 0.03);
            uv = (uv + 1.0) * 0.5;
            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                return vec4(0.0, 0.0, 0.0, 1.0);
            }
            float vignette = 1.0 - d * 0.5;
            pixel.rgb *= vignette;
            return pixel;
        }
    ]]
    
    shader = love.graphics.newShader(shaderCode)
    
    -- Upgrade screen properties
    upgradeFont = love.graphics.newFont(48)
    upgradeButtonFont = love.graphics.newFont(24)
    smallFont = love.graphics.newFont(20)
    
    -- Continue button properties
    continueButtonWidth = 200
    continueButtonHeight = 60
    continueButtonX = windowWidth - continueButtonWidth - 20  -- 20 pixels from right edge
    continueButtonY = windowHeight - continueButtonHeight - 20  -- 20 pixels from bottom edge
    
    -- Camera/panning properties
    cameraX = 0
    cameraY = 0
    isDragging = false
    lastMouseX = 0
    lastMouseY = 0
    
    -- Health upgrade properties
    healthUpgradeWidth = 300
    healthUpgradeHeight = 300
    healthUpgradeX = windowWidth/2 - healthUpgradeWidth/2
    healthUpgradeY = windowHeight/2 - healthUpgradeHeight/2
    healthUpgradeProgress = 0
    healthUpgradeAnimProgress = 0
    healthUpgradeComplete = false
    fillAnimationDuration = 0.5
    fillAnimationTimer = 0
    isAnimating = false
    
    -- Currency system
    redDots = 0
    redDotTimer = 0
    redDotCollectRate = 1  -- Collect one per second
    
    -- Upgrade costs
    healthUpgradeCosts = {20, 40, 70, 110, 160}
    
    -- Load sound effects
    clickSound = love.audio.newSource("music/click.wav", "static")
    hurtSound = love.audio.newSource("music/hitHurt.wav", "static")
    
    -- Upgrade system
    upgrades = {
        health = {
            name = "Max Health",
            description = "Increase maximum health",
            levels = {
                {cost = 20, value = 1},
                {cost = 40, value = 1},
                {cost = 70, value = 1},
                {cost = 110, value = 1},
                {cost = 160, value = 1}
            },
            progress = 0,
            requires = nil,
            position = {x = 400, y = 100}
        },
        
        speed = {
            name = "Movement Speed",
            description = "Move faster",
            levels = {
                {cost = 30, value = 25},
                {cost = 60, value = 25},
                {cost = 100, value = 25}
            },
            progress = 0,
            requires = {health = 2},
            position = {x = 50, y = 300}
        },
        
        invulnerability = {
            name = "Invulnerability",
            description = "Longer invincibility after hits",
            levels = {
                {cost = 50, value = 0.2},
                {cost = 90, value = 0.2},
                {cost = 140, value = 0.2}
            },
            progress = 0,
            requires = {health = 3},
            position = {x = 400, y = 400}
        },
        
        slowdown = {
            name = "Bullet Slowdown",
            description = "Reduce bullet speed",
            levels = {
                {cost = 80, value = 25},
                {cost = 130, value = 25},
                {cost = 190, value = 25}
            },
            progress = 0,
            requires = {speed = 1},
            position = {x = 50, y = 600}
        },
        
        boundary = {
            name = "Larger Area",
            description = "Increase play area",
            levels = {
                {cost = 100, value = 20},
                {cost = 150, value = 20},
                {cost = 200, value = 20}
            },
            progress = 0,
            requires = {health = 2, speed = 1},
            position = {x = 400, y = 700}
        },
        
        dodging = {
            name = "Dodge Master",
            description = "Temporary speed boost when near bullets",
            levels = {
                {cost = 120, value = 50},
                {cost = 180, value = 50},
                {cost = 250, value = 50}
            },
            progress = 0,
            requires = {speed = 2},
            position = {x = 50, y = 900}
        },
        
        regeneration = {
            name = "Health Regen",
            description = "Slowly recover health over time",
            levels = {
                {cost = 200, value = 0.1},
                {cost = 300, value = 0.1},
                {cost = 400, value = 0.1}
            },
            progress = 0,
            requires = {health = 4},
            position = {x = 400, y = 1000}
        },
        
        bulletRepulsion = {
            name = "Bullet Repulsion",
            description = "Push nearby bullets away",
            levels = {
                {cost = 250, value = 50},
                {cost = 350, value = 50},
                {cost = 450, value = 50}
            },
            progress = 0,
            requires = {invulnerability = 2},
            position = {x = 750, y = 700}
        }
    }
    
    -- Upgrade tree visual properties
    upgradeBoxWidth = 300
    upgradeBoxHeight = 150
    upgradeBoxPadding = 30
    
    -- Track unlocked upgrades
    unlockedUpgrades = {"health"}
    
    -- Add animation properties for upgrades
    upgradeAnimations = {}
    fillAnimationDuration = 0.5
    
    -- Add fade-in animation for newly unlocked upgrades
    upgradeAppearAnimations = {}
    appearAnimationDuration = 0.5
    
    -- Question system
    questionActive = false
    currentQuestion = nil
    questionAnswered = {}  -- Track which upgrades have been attempted
    
    -- Questions database
    questions = {
        {
            question = "What does CPU stand for?",
            options = {
                "Central Processing Unit",
                "Computer Personal Unit",
                "Central Program Utility",
                "Computer Processing Unit"
            },
            correct = 1
        },
        {
            question = "Which of these is a programming language?",
            options = {
                "Microsoft Word",
                "Python",
                "Firefox",
                "Keyboard"
            },
            correct = 2
        },
        {
            question = "What does HTML stand for?",
            options = {
                "High Text Markup Language",
                "Hyper Text Making Language",
                "Hyper Text Markup Language",
                "High Text Making Language"
            },
            correct = 3
        },
        {
            question = "Which symbol is used for single-line comments in Lua?",
            options = {
                "//",
                "#",
                "--",
                "/*"
            },
            correct = 3
        },
        {
            question = "What does RAM stand for?",
            options = {
                "Random Access Memory",
                "Read Access Memory",
                "Random Available Memory",
                "Read Available Memory"
            },
            correct = 1
        },
        {
            question = "Which data structure operates on a LIFO principle?",
            options = {
                "Queue",
                "Stack",
                "Array",
                "Tree"
            },
            correct = 2
        },
        {
            question = "What is the binary number 1010 in decimal?",
            options = {
                "8",
                "12",
                "10",
                "14"
            },
            correct = 3
        },
        {
            question = "Which of these is NOT a loop structure?",
            options = {
                "while",
                "switch",
                "for",
                "repeat"
            },
            correct = 2
        }
    }
    
    -- Question UI properties
    questionBoxWidth = windowWidth
    questionBoxHeight = windowHeight
    questionBoxX = 0
    questionBoxY = 0
    optionHeight = 60  -- Made smaller
    optionPadding = 15  -- Made smaller
    selectedAnswer = nil
    wrongAnswer = nil
    isAnswerCorrect = nil  -- New variable to track if answer was correct
    
    -- Icon properties
    iconSize = 20
    iconHovered = nil
    
    -- Reset questionAnswered each round
    function resetQuestionAnswered()
        questionAnswered = {}
        for name, _ in pairs(upgrades) do
            questionAnswered[name] = false
        end
    end
    
    resetQuestionAnswered()
end

function love.mousepressed(x, y, button, istouch, presses)
    if gameState == "menu" then
        -- Check if play button is clicked
        if button == 1 then  -- Left mouse button
            if x >= buttonX and x <= buttonX + buttonWidth and
               y >= buttonY and y <= buttonY + buttonHeight then
                clickSound:play()  -- Play click sound
                gameState = "game"
                -- Reset game state
                currentHealth = maxHealth
                bullets = {}
                playerX = windowWidth/2 - playerSize/2
                playerY = windowHeight/2 - playerSize/2
                gameTime = 0  -- Reset game time when starting new game
                bulletTimer = 0
            end
        end
    elseif gameState == "upgrades" then
        if questionActive then
            if button == 1 then
                local optionsStartY = windowHeight/2
                for i, _ in ipairs(currentQuestion.options) do
                    local optionY = optionsStartY + (i-1) * (optionHeight + optionPadding)
                    if x >= windowWidth/4 and
                       x <= windowWidth/4 + windowWidth/2 and
                       y >= optionY and
                       y <= optionY + optionHeight then
                        selectedAnswer = i
                        isAnswerCorrect = (i == currentQuestion.correct)
                        
                        if isAnswerCorrect then
                            upgrades[currentQuestion.upgradeName].hasDiscount = true
                            upgrades[currentQuestion.upgradeName].removeDiscountAfterPurchase = true
                        else
                            upgrades[currentQuestion.upgradeName].hasDiscount = false
                        end
                        
                        -- Keep the question visible longer
                        love.timer.sleep(1)
                        questionActive = false
                        return
                    end
                end
            end
            return
        end
        
        if button == 2 then  -- Right mouse button
            isDragging = true
            lastMouseX = x
            lastMouseY = y
        elseif button == 1 then  -- Left mouse button
            local adjustedX = x - cameraX
            local adjustedY = y - cameraY
            
            -- Check for question icon clicks
            for name, upgrade in pairs(upgrades) do
                if isUpgradeUnlocked(name) and not questionAnswered[name] and
                   upgrade.progress < #upgrade.levels then
                    local iconX = upgrade.position.x + upgradeBoxWidth - iconSize
                    local iconY = upgrade.position.y + iconSize
                    local dx = adjustedX - iconX
                    local dy = adjustedY - iconY
                    if dx * dx + dy * dy <= (iconSize/2) * (iconSize/2) then
                        questionActive = true
                        currentQuestion = questions[love.math.random(#questions)]
                        currentQuestion.upgradeName = name
                        questionAnswered[name] = true
                        selectedAnswer = nil
                        wrongAnswer = nil
                        return
                    end
                end
            end
            
            -- Check continue button and upgrade clicks...
            if x >= continueButtonX and x <= continueButtonX + continueButtonWidth and
               y >= continueButtonY and y <= continueButtonY + continueButtonHeight then
                clickSound:play()
                startNewRound()
                return
            end
            
            -- Check upgrade clicks (need camera adjustment)
            local adjustedX = x - cameraX
            local adjustedY = y - cameraY
            
            for name, upgrade in pairs(upgrades) do
                if isUpgradeUnlocked(name) and
                   adjustedX >= upgrade.position.x and
                   adjustedX <= upgrade.position.x + upgradeBoxWidth and
                   adjustedY >= upgrade.position.y and
                   adjustedY <= upgrade.position.y + upgradeBoxHeight then
                    if canAffordUpgrade(name) then
                        clickSound:play()
                        purchaseUpgrade(name)
                    end
                    return
                end
            end
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if button == 2 then  -- Right mouse button
        isDragging = false
    end
end

function checkCollision(x1, y1, w1, h1, x2, y2, r)
    -- Get the center of the square
    local squareCenterX = x1 + w1/2
    local squareCenterY = y1 + h1/2
    
    -- Get the distance between the circle's center and the square's center
    local dx = math.abs(x2 - squareCenterX)
    local dy = math.abs(y2 - squareCenterY)
    
    -- If the circle is too far away, there's no collision
    if dx > (w1/2 + r) then return false end
    if dy > (h1/2 + r) then return false end
    
    -- If the circle is close enough to the square's edges, there's a collision
    if dx <= (w1/2) then return true end
    if dy <= (h1/2) then return true end
    
    -- Check corner collision
    local cornerDistance = (dx - w1/2)^2 + (dy - h1/2)^2
    return cornerDistance <= (r^2)
end

function spawnBullet()
    local bullet = {}
    local side = love.math.random(1, 3)  -- 1 = top, 2 = left, 3 = right
    
    -- Calculate a random target point within the boundary box
    local targetX = love.math.random(boundaryX, boundaryX + boundaryWidth)
    local targetY = love.math.random(boundaryY, boundaryY + boundaryHeight)
    
    if side == 1 then  -- top
        bullet.x = love.math.random(0, windowWidth)
        bullet.y = -bulletRadius
    elseif side == 2 then  -- left
        bullet.x = -bulletRadius
        bullet.y = love.math.random(0, windowHeight)
    else  -- right
        bullet.x = windowWidth + bulletRadius
        bullet.y = love.math.random(0, windowHeight)
    end
    
    -- Calculate direction towards target point
    local dx = targetX - bullet.x
    local dy = targetY - bullet.y
    local dist = math.sqrt(dx * dx + dy * dy)
    
    -- Normalize direction
    bullet.dx = dx / dist
    bullet.dy = dy / dist
    
    table.insert(bullets, bullet)
end

function updateBullets(dt)
    -- Update invulnerability state
    isInvulnerable = (love.timer.getTime() - lastHitTime) < invulnerableTime
    
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        
        -- Calculate direction to player
        local dx = (playerX + playerSize/2) - bullet.x
        local dy = (playerY + playerSize/2) - bullet.y
        local dist = math.sqrt(dx * dx + dy * dy)
        
        if dist > 0 then
            dx = dx / dist
            dy = dy / dist
            
            -- Interpolate between current direction and direction to player
            bullet.dx = bullet.dx + (dx - bullet.dx) * homingStrength * dt
            bullet.dy = bullet.dy + (dy - bullet.dy) * homingStrength * dt
            
            -- Normalize direction
            local speed = math.sqrt(bullet.dx * bullet.dx + bullet.dy * bullet.dy)
            bullet.dx = bullet.dx / speed
            bullet.dy = bullet.dy / speed
        end
        
        -- Update position
        bullet.x = bullet.x + bullet.dx * bulletSpeed * dt
        bullet.y = bullet.y + bullet.dy * bulletSpeed * dt
        
        -- Check collision with player using more accurate hitbox
        if checkCollision(playerX, playerY, playerSize, playerSize, bullet.x, bullet.y, bulletRadius) then
            table.remove(bullets, i)
            
            if not isInvulnerable then
                hurtSound:play()  -- Play hurt sound
                lastDamagedHealth = currentHealth
                currentHealth = currentHealth - 1
                damageAnimTimer = damageAnimDuration
                lastHitTime = love.timer.getTime()
                
                -- Trigger screen shake when hit
                shakeTime = shakeDuration
                shakeOffset = {x = 0, y = 0}
            end
        -- Remove bullets that are off screen
        elseif bullet.x < -50 or bullet.x > windowWidth + 50 or
               bullet.y < -50 or bullet.y > windowHeight + 50 then
            table.remove(bullets, i)
        end
    end
end

function updateScreenShake(dt)
    if shakeTime > 0 then
        shakeTime = shakeTime - dt
        local shakePower = (shakeTime / shakeDuration) * shakeAmount
        shakeOffset.x = love.math.random(-shakePower, shakePower)
        shakeOffset.y = love.math.random(-shakePower, shakePower)
    else
        shakeOffset.x = 0
        shakeOffset.y = 0
    end
end

function createTitleBullets()
    local numBullets = 20
    local centerX = windowWidth/2
    local centerY = titleY + menuFont:getHeight()/2
    
    for i = 1, numBullets do
        local angle = (i / numBullets) * math.pi * 2
        local bullet = {
            x = centerX,
            y = centerY,
            dx = math.cos(angle) * bulletSpeed,
            dy = math.sin(angle) * bulletSpeed,
            alpha = 1
        }
        table.insert(titleBullets, bullet)
    end
end

function love.update(dt)
    if gameState == "menu" then
        if menuState == "animating" then
            animationTimer = animationTimer + dt
            
            if animationPhase == 1 then
                -- Slide in text
                local progress = math.min(animationTimer / slideDuration, 1)
                local easing = 1 - (1 - progress) * (1 - progress)  -- Ease out quad
                
                mrX = -200 + (targetMrX + 200) * easing
                squaryX = windowWidth + 200 - ((windowWidth + 200) - targetSquaryX) * easing
                
                if progress >= 1 then
                    animationPhase = 2
                    animationTimer = 0
                    createTitleBullets()
                end
                
            elseif animationPhase == 2 then
                -- Update title bullets
                for i = #titleBullets, 1, -1 do
                    local bullet = titleBullets[i]
                    bullet.x = bullet.x + bullet.dx * dt
                    bullet.y = bullet.y + bullet.dy * dt
                    bullet.alpha = bullet.alpha - dt * bulletFadeSpeed
                    
                    if bullet.alpha <= 0 then
                        table.remove(titleBullets, i)
                    end
                end
                
                if #titleBullets == 0 then
                    animationPhase = 3  -- Start button slide
                    animationTimer = 0
                end
                
            elseif animationPhase == 3 then
                -- Slide in button
                local progress = math.min(animationTimer / buttonSlideDuration, 1)
                local easing = 1 - (1 - progress) * (1 - progress)  -- Ease out quad
                
                buttonY = windowHeight + buttonHeight - 
                         ((windowHeight + buttonHeight) - buttonTargetY) * easing
                
                if progress >= 1 then
                    animationPhase = 4
                    menuState = "ready"
                end
            end
        end
    elseif gameState == "game" then
        -- Check if health is zero
        if currentHealth <= 0 then
            gameState = "upgrades"
            return
        end
        
        -- Update damage animation timer
        if damageAnimTimer > 0 then
            damageAnimTimer = damageAnimTimer - dt
        end
        
        -- Update screen shake
        updateScreenShake(dt)
        
        -- Existing player movement code
        mouseX = love.mouse.getX()
        mouseY = love.mouse.getY()
        
        local dx = mouseX - (playerX + playerSize/2)
        local dy = mouseY - (playerY + playerSize/2)
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance > 0 then
            dx = dx / distance
            dy = dy / distance
            
            local currentSpeed = maxSpeed
            if distance < slowdownDistance then
                currentSpeed = maxSpeed * (distance / slowdownDistance)
            end
            
            playerX = playerX + dx * currentSpeed * dt
            playerY = playerY + dy * currentSpeed * dt
            
            playerX = math.max(boundaryX, math.min(boundaryX + boundaryWidth - playerSize, playerX))
            playerY = math.max(boundaryY, math.min(boundaryY + boundaryHeight - playerSize, playerY))
        end
        
        -- Update game time and bullet spawn rate
        gameTime = gameTime + dt
        local currentSpawnRate = math.max(minBulletSpawnRate, 
            bulletSpawnRate - (gameTime * bulletSpawnRateDecrease))
        
        -- Update bullet spawning
        bulletTimer = bulletTimer + dt
        if bulletTimer >= currentSpawnRate then
            spawnBullet()
            bulletTimer = 0
        end
        
        -- Update bullets and check collisions
        updateBullets(dt)
        
        -- Collect red dots over time
        redDotTimer = redDotTimer + dt
        if redDotTimer >= redDotCollectRate then
            redDots = redDots + 1
            redDotTimer = redDotTimer - redDotCollectRate
        end
        
        -- Apply regeneration if unlocked
        if healthRegenRate and healthRegenRate > 0 then
            if currentHealth < maxHealth then
                currentHealth = math.min(maxHealth, currentHealth + healthRegenRate * dt)
            end
        end
        
        -- Apply dodge boost if near bullets
        if dodgeSpeedBoost and dodgeSpeedBoost > 0 then
            local nearBullet = false
            for _, bullet in ipairs(bullets) do
                local dx = bullet.x - (playerX + playerSize/2)
                local dy = bullet.y - (playerY + playerSize/2)
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist < 100 then  -- Within 100 pixels
                    nearBullet = true
                    break
                end
            end
            if nearBullet then
                maxSpeed = maxSpeed + dodgeSpeedBoost
            end
        end
        
        -- Apply bullet repulsion
        if bulletRepulsionForce and bulletRepulsionForce > 0 then
            for _, bullet in ipairs(bullets) do
                local dx = bullet.x - (playerX + playerSize/2)
                local dy = bullet.y - (playerY + playerSize/2)
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist < bulletRepulsionForce then
                    local force = (bulletRepulsionForce - dist) / bulletRepulsionForce
                    bullet.x = bullet.x + (dx / dist) * force * dt * 100
                    bullet.y = bullet.y + (dy / dist) * force * dt * 100
                end
            end
        end
    elseif gameState == "upgrades" then
        -- Update panning
        if isDragging then
            local mouseX, mouseY = love.mouse.getPosition()
            local dx = mouseX - lastMouseX
            local dy = mouseY - lastMouseY
            cameraX = cameraX + dx
            cameraY = cameraY + dy
            lastMouseX = mouseX
            lastMouseY = mouseY
        end
        
        -- Update fill animation
        if isAnimating then
            fillAnimationTimer = fillAnimationTimer + dt
            local progress = fillAnimationTimer / fillAnimationDuration
            
            if progress >= 1 then
                isAnimating = false
                healthUpgradeAnimProgress = healthUpgradeProgress
            else
                -- Smooth easing
                progress = 1 - (1 - progress) * (1 - progress)  -- Ease out quad
                healthUpgradeAnimProgress = healthUpgradeProgress - 1 + progress
            end
        end
        
        -- Update upgrade animations
        for name, anim in pairs(upgradeAnimations) do
            anim.timer = anim.timer + dt
            if anim.timer >= fillAnimationDuration then
                upgradeAnimations[name] = nil
            end
        end
        
        -- Update appear animations
        for name, anim in pairs(upgradeAppearAnimations) do
            anim.timer = anim.timer + dt
            if anim.timer >= appearAnimationDuration then
                upgradeAppearAnimations[name] = nil
            end
        end
    end
end

function drawUpgradeTree()
    -- Draw connections first
    love.graphics.setColor(0.7, 0.7, 0.7)
    for name, upgrade in pairs(upgrades) do
        if upgrade.requires then
            for reqName, reqLevel in pairs(upgrade.requires) do
                local reqUpgrade = upgrades[reqName]
                if isUpgradeUnlocked(name) then
                    love.graphics.line(
                        reqUpgrade.position.x + upgradeBoxWidth/2,
                        reqUpgrade.position.y + upgradeBoxHeight,
                        upgrade.position.x + upgradeBoxWidth/2,
                        upgrade.position.y
                    )
                end
            end
        end
    end
    
    -- Draw upgrade boxes
    for name, upgrade in pairs(upgrades) do
        local isUnlocked = isUpgradeUnlocked(name)
        local canUnlock = canUnlockUpgrade(name)
        
        if isUnlocked or canUnlock then
            -- Draw white background
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("fill",
                upgrade.position.x,
                upgrade.position.y,
                upgradeBoxWidth,
                upgradeBoxHeight
            )
            
            -- Draw progress fill if applicable
            if isUnlocked and upgrade.progress > 0 then
                love.graphics.setColor(0, 0.8, 0, 0.5)
                
                local fillProgress = upgrade.progress
                if upgradeAnimations[name] then
                    local t = upgradeAnimations[name].timer / fillAnimationDuration
                    t = 1 - (1 - t) * (1 - t)
                    fillProgress = upgradeAnimations[name].startProgress + 
                        (upgradeAnimations[name].targetProgress - upgradeAnimations[name].startProgress) * t
                end
                
                local fillHeight = (upgradeBoxHeight * fillProgress) / #upgrade.levels
                love.graphics.rectangle("fill",
                    upgrade.position.x,
                    upgrade.position.y + upgradeBoxHeight - fillHeight,
                    upgradeBoxWidth,
                    fillHeight
                )
            end
            
            -- Set box outline color
            if isUnlocked then
                if upgrade.progress >= #upgrade.levels then
                    love.graphics.setColor(0, 0.8, 0)
                else
                    if canAffordUpgrade(name) then
                        love.graphics.setColor(1, 1, 0)
                    else
                        love.graphics.setColor(0.8, 0.8, 0.8)
                    end
                end
            else
                if canUnlock then
                    love.graphics.setColor(0.5, 0.5, 1)
                else
                    love.graphics.setColor(0.5, 0.5, 0.5)
                end
            end
            
            -- Draw box outline
            love.graphics.rectangle("line",
                upgrade.position.x,
                upgrade.position.y,
                upgradeBoxWidth,
                upgradeBoxHeight
            )
            
            -- Draw name and progress
            if isUnlocked then
                love.graphics.setColor(0, 0, 0)
                love.graphics.setFont(upgradeButtonFont)
                love.graphics.printf(upgrade.name,
                    upgrade.position.x + upgradeBoxPadding,
                    upgrade.position.y + upgradeBoxPadding,
                    upgradeBoxWidth - upgradeBoxPadding * 2,
                    "center"
                )
                
                -- Draw progress text
                local progressText = upgrade.progress .. "/" .. #upgrade.levels
                love.graphics.setFont(smallFont)
                love.graphics.printf(progressText,
                    upgrade.position.x + upgradeBoxPadding,
                    upgrade.position.y + upgradeBoxHeight - upgradeBoxPadding - smallFont:getHeight(),
                    upgradeBoxWidth - upgradeBoxPadding * 2,
                    "center"
                )
                
                -- Draw cost if not maxed
                if upgrade.progress < #upgrade.levels then
                    -- Draw red dot
                    love.graphics.setColor(1, 0, 0)
                    love.graphics.circle("fill",
                        upgrade.position.x + upgradeBoxWidth/2 - 15,
                        upgrade.position.y + upgradeBoxHeight/2,
                        bulletRadius
                    )
                    
                    -- Calculate costs
                    local baseCost = upgrade.levels[upgrade.progress + 1].cost
                    local finalCost = upgrade.hasDiscount and math.floor(baseCost * 0.9) or baseCost
                    
                    if upgrade.hasDiscount then
                        -- Draw discounted price first
                        love.graphics.setColor(0, 0.7, 0)  -- Green for discount
                        love.graphics.print(finalCost,
                            upgrade.position.x + upgradeBoxWidth/2 + 5,
                            upgrade.position.y + upgradeBoxHeight/2 - smallFont:getHeight()/2
                        )
                        
                        -- Draw original price after the discounted price
                        local discountedWidth = smallFont:getWidth(tostring(finalCost))
                        love.graphics.setColor(0.7, 0.7, 0.7)  -- Gray for original price
                        love.graphics.print(baseCost,
                            upgrade.position.x + upgradeBoxWidth/2 + 15 + discountedWidth,
                            upgrade.position.y + upgradeBoxHeight/2 - smallFont:getHeight()/2
                        )
                        
                        -- Draw strikethrough
                        local originalX = upgrade.position.x + upgradeBoxWidth/2 + 15 + discountedWidth
                        local originalWidth = smallFont:getWidth(tostring(baseCost))
                        love.graphics.line(
                            originalX,
                            upgrade.position.y + upgradeBoxHeight/2,
                            originalX + originalWidth,
                            upgrade.position.y + upgradeBoxHeight/2
                        )
                    else
                        -- Draw normal price
                        love.graphics.setColor(0, 0, 0)
                        love.graphics.print(finalCost,
                            upgrade.position.x + upgradeBoxWidth/2 + 5,
                            upgrade.position.y + upgradeBoxHeight/2 - smallFont:getHeight()/2
                        )
                    end
                end
            end
            
            -- Draw question mark icon if applicable
            if isUnlocked and not questionAnswered[name] and upgrade.progress < #upgrade.levels then
                drawQuestionIcon(
                    upgrade.position.x + upgradeBoxWidth - iconSize,
                    upgrade.position.y + iconSize,
                    name
                )
            end
        end
    end
end

function love.draw()
    -- Always draw to canvas first, regardless of game state
    love.graphics.setCanvas(canvas)
    love.graphics.clear(1, 1, 1)  -- Clear to white
    
    if gameState == "menu" then
        -- Draw menu with simple style
        love.graphics.setColor(0, 0, 1)  -- Blue square in background
        love.graphics.rectangle("fill", 
            windowWidth/2 - 75,  -- Centered square
            windowHeight/3 - 75,
            150, 150)
            
        -- Draw title with animation
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(menuFont)
        
        -- Draw "Mr. "
        love.graphics.print("Mr. ", mrX, titleY)
        
        -- Draw "Squary"
        love.graphics.print("Squary", squaryX, titleY)
        
        -- Draw title bullets
        love.graphics.setColor(1, 0, 0)
        for _, bullet in ipairs(titleBullets) do
            love.graphics.setColor(1, 0, 0, bullet.alpha)
            love.graphics.circle("fill", bullet.x, bullet.y, 8)
        end
        
        -- Always draw button (it will slide up from bottom)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight)
        love.graphics.setFont(buttonFont)
        local playText = "PLAY"
        local playWidth = buttonFont:getWidth(playText)
        love.graphics.print(playText, 
            buttonX + buttonWidth/2 - playWidth/2,
            buttonY + buttonHeight/2 - buttonFont:getHeight()/2)
    elseif gameState == "game" then
        -- Existing game drawing code
        love.graphics.push()
        love.graphics.translate(shakeOffset.x, shakeOffset.y)
        
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", boundaryX, boundaryY, boundaryWidth, boundaryHeight)
        
        love.graphics.setColor(0, 0, 1)
        love.graphics.rectangle("fill", playerX, playerY, playerSize, playerSize)
        
        love.graphics.setColor(1, 0, 0)
        for _, bullet in ipairs(bullets) do
            love.graphics.circle("fill", bullet.x, bullet.y, bulletRadius)
        end
        
        love.graphics.pop()
        
        -- Draw health bar
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", healthBarX, healthBarY, healthBarWidth, healthBarHeight)
        
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", healthBarX + 1, healthBarY + 1, 
            (healthBarWidth - 2) * (currentHealth / maxHealth), healthBarHeight - 2)
        
        if damageAnimTimer > 0 then
            love.graphics.setColor(1, 0, 0)
            local animationProgress = damageAnimTimer / damageAnimDuration
            local damageWidth = (healthBarWidth - 2) * (lastDamagedHealth - currentHealth) / maxHealth
            local startX = healthBarX + 1 + (healthBarWidth - 2) * currentHealth / maxHealth
            love.graphics.rectangle("fill", startX, healthBarY + 1, 
                damageWidth * animationProgress, healthBarHeight - 2)
        end
        
        -- Draw red dot counter in top-left
        love.graphics.setColor(1, 0, 0)  -- Set to red color
        love.graphics.circle("fill", 30, 30, bulletRadius)  -- Red dot icon
        love.graphics.setColor(0, 0, 0)  -- Set back to black for text
        love.graphics.setFont(smallFont)
        love.graphics.print(" " .. redDots, 45, 20)
    elseif gameState == "upgrades" then
        -- Draw upgrade tree with camera transform
        love.graphics.push()
        love.graphics.translate(cameraX, cameraY)
        drawUpgradeTree()
        love.graphics.pop()
        
        -- Draw fixed UI elements
        -- "UPGRADES" text
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(upgradeFont)
        local upgradesText = "UPGRADES"
        local textWidth = upgradeFont:getWidth(upgradesText)
        love.graphics.print(upgradesText, windowWidth/2 - textWidth/2, 20)
        
        -- Continue button shadow
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill",
            continueButtonX + 5,
            continueButtonY + 5,
            continueButtonWidth,
            continueButtonHeight
        )
        
        -- Continue button
        love.graphics.setColor(1, 1, 1)  -- White background
        love.graphics.rectangle("fill",
            continueButtonX,
            continueButtonY,
            continueButtonWidth,
            continueButtonHeight
        )
        love.graphics.setColor(0, 0, 0)  -- Black outline
        love.graphics.rectangle("line",
            continueButtonX,
            continueButtonY,
            continueButtonWidth,
            continueButtonHeight
        )
        
        -- Continue button text
        love.graphics.setFont(upgradeButtonFont)
        local continueText = "CONTINUE"
        local continueWidth = upgradeButtonFont:getWidth(continueText)
        love.graphics.print(continueText,
            continueButtonX + continueButtonWidth/2 - continueWidth/2,
            continueButtonY + continueButtonHeight/2 - upgradeButtonFont:getHeight()/2
        )
        
        -- Red dot counter
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", 30, 30, bulletRadius)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(smallFont)
        love.graphics.print(" " .. redDots, 45, 20)
        
        -- Draw question interface on top of everything if active
        if questionActive then
            drawQuestion()
        end
    end
    
    -- Always apply CRT effect, regardless of game state
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    
    shader:send("screen", {windowWidth, windowHeight})
    
    love.graphics.setShader(shader)
    love.graphics.draw(canvas)
    love.graphics.setShader()
end

-- Add these helper functions
function isUpgradeUnlocked(name)
    for _, unlockedName in ipairs(unlockedUpgrades) do
        if name == unlockedName then
            return true
        end
    end
    return false
end

function canUnlockUpgrade(name)
    local upgrade = upgrades[name]
    if not upgrade.requires then return true end
    
    for reqName, reqLevel in pairs(upgrade.requires) do
        if upgrades[reqName].progress < reqLevel then
            return false
        end
    end
    return true
end

function purchaseUpgrade(name)
    local upgrade = upgrades[name]
    if upgrade.progress >= #upgrade.levels then return end
    
    local baseCost = upgrade.levels[upgrade.progress + 1].cost
    local finalCost = upgrade.hasDiscount and math.floor(baseCost * 0.9) or baseCost
    
    if redDots >= finalCost then
        redDots = redDots - finalCost
        local value = upgrade.levels[upgrade.progress + 1].value
        
        -- Start fill animation
        upgradeAnimations[name] = {
            startProgress = upgrade.progress,
            targetProgress = upgrade.progress + 1,
            timer = 0
        }
        
        applyUpgrade(name, value)
        upgrade.progress = upgrade.progress + 1
        
        -- Remove discount after purchase if it was a one-time discount
        if upgrade.removeDiscountAfterPurchase then
            upgrade.hasDiscount = false
            upgrade.removeDiscountAfterPurchase = false
        end
        
        -- Check for new unlocks
        for otherName, otherUpgrade in pairs(upgrades) do
            if not isUpgradeUnlocked(otherName) and canUnlockUpgrade(otherName) then
                table.insert(unlockedUpgrades, otherName)
                upgradeAppearAnimations[otherName] = {
                    timer = 0
                }
            end
        end
    end
end

function applyUpgrade(name, value)
    if name == "health" then
        maxHealth = maxHealth + value
        currentHealth = maxHealth
    elseif name == "speed" then
        maxSpeed = maxSpeed + value
    elseif name == "invulnerability" then
        invulnerableTime = invulnerableTime + value
    elseif name == "slowdown" then
        bulletSpeed = math.max(100, bulletSpeed - value)  -- Don't go below 100
    elseif name == "boundary" then
        boundaryWidth = boundaryWidth + value
        boundaryHeight = boundaryHeight + value
        boundaryX = windowWidth/2 - boundaryWidth/2
        boundaryY = windowHeight/2 - boundaryHeight/2
    elseif name == "dodging" then
        dodgeSpeedBoost = (dodgeSpeedBoost or 0) + value
    elseif name == "regeneration" then
        healthRegenRate = (healthRegenRate or 0) + value
    elseif name == "bulletRepulsion" then
        bulletRepulsionForce = (bulletRepulsionForce or 0) + value
    end
end

function canAffordUpgrade(upgradeName)
    local upgrade = upgrades[upgradeName]
    if upgrade.progress >= #upgrade.levels then 
        return false 
    end
    local baseCost = upgrade.levels[upgrade.progress + 1].cost
    local finalCost = upgrade.hasDiscount and math.floor(baseCost * 0.9) or baseCost
    return redDots >= finalCost
end

function drawQuestionIcon(x, y, name)
    -- Draw the question mark icon
    love.graphics.setColor(0.3, 0.3, 1)
    if iconHovered == name then
        love.graphics.setColor(0.5, 0.5, 1)
    end
    love.graphics.circle("fill", x, y, iconSize/2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(smallFont)
    love.graphics.printf("?", x - iconSize/2, y - smallFont:getHeight()/2, iconSize, "center")
    
    -- Draw tooltip if hovered
    if iconHovered == name then
        -- Set up tooltip text
        local tooltipText = "Answer a computer science question correct\nto gain a 10% discount on the current price."
        
        -- Calculate actual text dimensions with extra padding
        local textWidth = smallFont:getWidth(tooltipText) + 40  -- Increased padding
        local _, textWrappedHeight = smallFont:getWrap(tooltipText, 280)  -- Increased width
        local textHeight = #textWrappedHeight * smallFont:getHeight() + 30  -- Increased padding
        
        -- Calculate tooltip dimensions based on text
        local tooltipWidth = 280  -- Increased width
        local tooltipHeight = textHeight
        local tooltipX = x + iconSize
        local tooltipY = y - tooltipHeight/2
        
        -- Draw black background box
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", 
            tooltipX, 
            tooltipY, 
            tooltipWidth, 
            tooltipHeight,
            5
        )
        
        -- Draw white border
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("line", 
            tooltipX, 
            tooltipY, 
            tooltipWidth, 
            tooltipHeight,
            5
        )
        
        -- Draw tooltip text with more padding
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(
            tooltipText,
            tooltipX + 15,  -- Increased padding
            tooltipY + 15,  -- Increased padding
            tooltipWidth - 30,  -- Adjusted for increased padding
            "left"
        )
    end
end

function drawQuestion()
    if not questionActive or not currentQuestion then return end
    
    -- Darken background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    
    -- Draw question
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(upgradeFont)
    love.graphics.printf(currentQuestion.question, 
        100, 
        windowHeight/8,
        windowWidth - 200, 
        "center"
    )
    
    -- Draw options starting from middle of screen
    local optionsStartY = windowHeight/2
    for i, option in ipairs(currentQuestion.options) do
        local optionY = optionsStartY + (i-1) * (optionHeight + optionPadding)
        
        -- Set the background color
        if selectedAnswer then
            if i == selectedAnswer then
                if isAnswerCorrect then
                    love.graphics.setColor(0, 1, 0, 0.8)  -- Green for correct
                else
                    love.graphics.setColor(1, 0, 0, 0.8)  -- Red for wrong
                end
            elseif i == currentQuestion.correct and not isAnswerCorrect then
                love.graphics.setColor(0, 1, 0, 0.8)  -- Show correct answer
            else
                love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
            end
        else
            love.graphics.setColor(0.9, 0.9, 0.9, 0.8)
        end
        
        -- Draw option box
        love.graphics.rectangle("fill",
            windowWidth/4,
            optionY,
            windowWidth/2,
            optionHeight,
            10
        )
        
        -- Draw option border
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("line",
            windowWidth/4,
            optionY,
            windowWidth/2,
            optionHeight,
            10
        )
        
        -- Option text
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(upgradeButtonFont)
        love.graphics.printf(option,
            windowWidth/4 + 20,
            optionY + optionHeight/2 - upgradeButtonFont:getHeight()/2,
            windowWidth/2 - 40,
            "center"
        )
    end
end

function checkQuestionClick(x, y)
    if not questionActive or not currentQuestion then return end
    
    for i, _ in ipairs(currentQuestion.options) do
        local optionY = windowHeight/2 + (i-1) * (optionHeight + optionPadding)
        if x >= windowWidth/4 and
           x <= windowWidth/4 + windowWidth/2 and
           y >= optionY and
           y <= optionY + optionHeight then
            selectedAnswer = i
            if i == currentQuestion.correct then
                -- Correct answer - apply discount
                local upgrade = upgrades[currentQuestion.upgradeName]
                upgrade.hasDiscount = true
            else
                -- Wrong answer
                wrongAnswer = i
                upgrade.hasDiscount = false
            end
            -- Wait a moment before closing question
            love.timer.sleep(0.5)
            questionActive = false
            return true
        end
    end
    return false
end

function love.mousemoved(x, y, dx, dy)
    if gameState == "upgrades" then
        -- Check for icon hover
        local adjustedX = x - cameraX
        local adjustedY = y - cameraY
        iconHovered = nil
        
        for name, upgrade in pairs(upgrades) do
            if isUpgradeUnlocked(name) and not questionAnswered[name] and
               upgrade.progress < #upgrade.levels then
                local iconX = upgrade.position.x + upgradeBoxWidth - iconSize
                local iconY = upgrade.position.y + iconSize
                local dx = adjustedX - iconX
                local dy = adjustedY - iconY
                if dx * dx + dy * dy <= (iconSize/2) * (iconSize/2) then
                    iconHovered = name
                    break
                end
            end
        end
    end
end

-- Add this to your gameState change code (where you switch to upgrades)
function enterUpgradeState()
    gameState = "upgrades"
    resetQuestionAnswered()  -- Reset question availability each round
    -- Reset any other upgrade state as needed
end

-- Add this to where you transition to game state
function startNewRound()
    gameState = "game"
    currentHealth = maxHealth
    bullets = {}
    playerX = windowWidth/2 - playerSize/2
    playerY = windowHeight/2 - playerSize/2
    questionAnswered = {}
    selectedAnswer = nil
    isAnswerCorrect = nil  -- Reset the answer state
    -- Reset all upgrade discounts
    for name, upgrade in pairs(upgrades) do
        upgrade.hasDiscount = false
        questionAnswered[name] = false
    end
end