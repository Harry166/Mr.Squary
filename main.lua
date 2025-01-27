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
    continueButtonX = windowWidth/2 - continueButtonWidth/2
    continueButtonY = windowHeight - continueButtonHeight - 20
    
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
    healthUpgradeCosts = {40, 80, 150, 210, 250}
    
    -- Load sound effects
    clickSound = love.audio.newSource("music/click.wav", "static")
    hurtSound = love.audio.newSource("music/hitHurt.wav", "static")
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
        if button == 2 then  -- Right mouse button
            isDragging = true
            lastMouseX = x
            lastMouseY = y
        elseif button == 1 then  -- Left mouse button
            -- Adjust coordinates for camera position
            local adjustedX = x - cameraX
            local adjustedY = y - cameraY
            
            -- Check if health upgrade button is clicked
            if not healthUpgradeComplete and not isAnimating and
               adjustedX >= healthUpgradeX and adjustedX <= healthUpgradeX + healthUpgradeWidth and
               adjustedY >= healthUpgradeY and adjustedY <= healthUpgradeY + healthUpgradeHeight then
                if healthUpgradeProgress < 5 and canAffordUpgrade() then
                    clickSound:play()  -- Play click sound
                    redDots = redDots - healthUpgradeCosts[healthUpgradeProgress + 1]
                    isAnimating = true
                    fillAnimationTimer = 0
                    healthUpgradeAnimProgress = healthUpgradeProgress
                    healthUpgradeProgress = healthUpgradeProgress + 1
                    maxHealth = maxHealth + 1
                    currentHealth = maxHealth
                    
                    if healthUpgradeProgress >= 5 then
                        healthUpgradeComplete = true
                    end
                end
            end
            
            -- Check if continue button is clicked
            if adjustedX >= continueButtonX and adjustedX <= continueButtonX + continueButtonWidth and
               adjustedY >= continueButtonY and adjustedY <= continueButtonY + continueButtonHeight then
                clickSound:play()  -- Play click sound
                gameState = "game"
                currentHealth = maxHealth
                bullets = {}
                playerX = windowWidth/2 - playerSize/2
                playerY = windowHeight/2 - playerSize/2
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
    end
end

function canAffordUpgrade()
    if healthUpgradeProgress >= 5 then return false end
    return redDots >= healthUpgradeCosts[healthUpgradeProgress + 1]
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
        -- Draw red dot counter in top-left (outside of camera transform)
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", 30, 30, bulletRadius)
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(smallFont)
        love.graphics.print(" " .. redDots, 45, 20)
        
        -- Apply camera transform
        love.graphics.push()
        love.graphics.translate(cameraX, cameraY)
        
        -- Draw "UPGRADES" text at top
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(upgradeFont)
        local upgradesText = "UPGRADES"
        local textWidth = upgradeFont:getWidth(upgradesText)
        love.graphics.print(upgradesText, windowWidth/2 - textWidth/2, 50)
        
        -- Draw health upgrade square with color based on affordability
        if healthUpgradeProgress < 5 then
            if canAffordUpgrade() then
                love.graphics.setColor(1, 1, 0)  -- Yellow if can afford
            else
                love.graphics.setColor(1, 0, 0)  -- Red if can't afford
            end
        else
            love.graphics.setColor(0, 0, 0)  -- Black if complete
        end
        love.graphics.rectangle("line", healthUpgradeX, healthUpgradeY, healthUpgradeWidth, healthUpgradeHeight)
        
        -- Draw fill progress
        if healthUpgradeAnimProgress > 0 then
            love.graphics.setColor(0, 1, 0, 0.5)
            local fillHeight = (healthUpgradeHeight / 5) * healthUpgradeAnimProgress
            love.graphics.rectangle("fill", 
                healthUpgradeX, 
                healthUpgradeY + healthUpgradeHeight - fillHeight, 
                healthUpgradeWidth, 
                fillHeight)
        end
        
        -- Draw upgrade text
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(upgradeButtonFont)
        local buttonText = "MAX HEALTH"
        local buttonTextWidth = upgradeButtonFont:getWidth(buttonText)
        love.graphics.print(buttonText,
            healthUpgradeX + healthUpgradeWidth/2 - buttonTextWidth/2,
            healthUpgradeY + healthUpgradeHeight/2 - upgradeButtonFont:getHeight()/2)
        
        -- Draw progress text
        local progressText = healthUpgradeProgress .. "/5"
        local progressTextWidth = upgradeButtonFont:getWidth(progressText)
        love.graphics.print(progressText,
            healthUpgradeX + healthUpgradeWidth/2 - progressTextWidth/2,
            healthUpgradeY + healthUpgradeHeight/2 + upgradeButtonFont:getHeight())
            
        -- Draw cost at bottom of upgrade square
        if not healthUpgradeComplete then
            love.graphics.setFont(smallFont)
            love.graphics.setColor(1, 0, 0)  -- Set to red color
            love.graphics.circle("fill", 
                healthUpgradeX + healthUpgradeWidth/2 - 30, 
                healthUpgradeY + healthUpgradeHeight - 25,
                bulletRadius)
            love.graphics.setColor(0, 0, 0)  -- Set back to black for text
            love.graphics.print(" " .. healthUpgradeCosts[healthUpgradeProgress + 1],  -- Removed colon, added space
                healthUpgradeX + healthUpgradeWidth/2 - 10,
                healthUpgradeY + healthUpgradeHeight - 35)
        end
        
        -- Draw continue button
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", continueButtonX, continueButtonY, continueButtonWidth, continueButtonHeight)
        love.graphics.setFont(upgradeButtonFont)
        local continueText = "CONTINUE"
        local continueWidth = upgradeButtonFont:getWidth(continueText)
        love.graphics.print(continueText,
            continueButtonX + continueButtonWidth/2 - continueWidth/2,
            continueButtonY + continueButtonHeight/2 - upgradeButtonFont:getHeight()/2)
        
        love.graphics.pop()
    end
    
    -- Always apply CRT effect, regardless of game state
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    
    shader:send("screen", {windowWidth, windowHeight})
    
    love.graphics.setShader(shader)
    love.graphics.draw(canvas)
    love.graphics.setShader()
end