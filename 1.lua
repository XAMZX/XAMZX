-- AutoFollowAndBuy.lua
-- Универсальный скрипт для следования и покупки Pipi Kiwi

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- === НАСТРОЙКИ ===
local TARGET_NAME = "Pipi Kiwi"
local TOGGLE_KEY = Enum.KeyCode.RightShift
local BUY_KEY = Enum.KeyCode.E
local FOLLOW_DISTANCE = 6
local HOLD_E_TIME = 1.5
local SEARCH_INTERVAL = 1.0
local STUCK_TIME = 5 -- секунд до активации хаотичных движений
local CHAOTIC_MOVE_TIME = 3 -- длительность хаотичных движений

-- === СОСТОЯНИЕ ===
local autoBuyEnabled = false
local currentTarget = nil
local isBuying = false
local purchasedTargets = {}
local lastPurchaseTime = 0
local lastDistance = math.huge
local lastDistanceChangeTime = 0
local isChaoticMoving = false
local isUIVisible = true
local guiDragging = false
local dragStartPosition = nil

-- === UI ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoBuyGUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Основной фрейм
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 180)
MainFrame.Position = UDim2.new(0, 10, 0, 10)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Верхняя панель для перемещения
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 25)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 8)
TopBarCorner.Parent = TopBar

-- Заголовок
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 5, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Text = "AutoBuy Pipi Kiwi"
TitleLabel.TextScaled = true
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

-- Кнопка сворачивания
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 25, 0, 25)
MinimizeButton.Position = UDim2.new(1, -55, 0, 0)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Text = "-"
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextScaled = true
MinimizeButton.Parent = TopBar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 6)
MinimizeCorner.Parent = MinimizeButton

-- Кнопка закрытия (для теста)
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -25, 0, 0)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "X"
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextScaled = true
CloseButton.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

-- Контентная область
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -25)
ContentFrame.Position = UDim2.new(0, 0, 0, 25)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0, 0)
StatusLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.Text = "AutoBuy: OFF"
StatusLabel.TextScaled = true
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.Parent = ContentFrame

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -20, 0, 80)
InfoLabel.Position = UDim2.new(0, 10, 0, 40)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoLabel.Text = "Press RightShift to toggle\nTarget: None\nDistance: -\nStatus: Ready"
InfoLabel.TextScaled = true
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Parent = ContentFrame

local StatsLabel = Instance.new("TextLabel")
StatsLabel.Size = UDim2.new(1, -20, 0, 30)
StatsLabel.Position = UDim2.new(0, 10, 0, 125)
StatsLabel.BackgroundTransparency = 1
StatsLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
StatsLabel.Text = "Purchased: 0 | Stuck: 0"
StatsLabel.TextScaled = true
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
StatsLabel.Parent = ContentFrame

-- Переменные для хаотичных движений
local stuckCount = 0
local chaoticMoveStartTime = 0

local function updateUI(status, info, stats)
    if status then
        StatusLabel.Text = "AutoBuy: " .. status
        StatusLabel.BackgroundColor3 = autoBuyEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
    else
        StatusLabel.Text = "AutoBuy: " .. (autoBuyEnabled and "ON" or "OFF")
        StatusLabel.BackgroundColor3 = autoBuyEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(100, 0, 0)
    end
    
    if info then
        InfoLabel.Text = info
    end
    
    if stats then
        StatsLabel.Text = stats
    end
end

-- === ФУНКЦИИ ПЕРЕМЕЩЕНИЯ GUI ===
local function toggleUIVisibility()
    isUIVisible = not isUIVisible
    if isUIVisible then
        ContentFrame.Visible = true
        MinimizeButton.Text = "-"
        -- Плавное появление
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(ContentFrame, tweenInfo, {Size = UDim2.new(1, 0, 1, -25)})
        tween:Play()
    else
        MinimizeButton.Text = "+"
        -- Плавное исчезновение
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(ContentFrame, tweenInfo, {Size = UDim2.new(1, 0, 0, 0)})
        tween:Play()
        task.wait(0.3)
        ContentFrame.Visible = false
    end
end

-- Обработчики для перемещения GUI
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        guiDragging = true
        dragStartPosition = Vector2.new(input.Position.X, input.Position.Y)
        MainFrame.Selectable = true
    end
end)

TopBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        guiDragging = false
        MainFrame.Selectable = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if guiDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPosition
        local newPosition = UDim2.new(
            MainFrame.Position.X.Scale, 
            MainFrame.Position.X.Offset + delta.X,
            MainFrame.Position.Y.Scale, 
            MainFrame.Position.Y.Offset + delta.Y
        )
        
        -- Ограничиваем позицию в пределах экрана
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local frameSize = MainFrame.AbsoluteSize
        
        newPosition = UDim2.new(
            math.clamp(newPosition.X.Scale, 0, 1 - frameSize.X/viewportSize.X),
            math.clamp(newPosition.X.Offset, 0, viewportSize.X - frameSize.X),
            math.clamp(newPosition.Y.Scale, 0, 1 - frameSize.Y/viewportSize.Y),
            math.clamp(newPosition.Y.Offset, 0, viewportSize.Y - frameSize.Y)
        )
        
        MainFrame.Position = newPosition
        dragStartPosition = Vector2.new(input.Position.X, input.Position.Y)
    end
end)

MinimizeButton.MouseButton1Click:Connect(toggleUIVisibility)

CloseButton.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
    print("🔒 GUI скрыто. Для показа включите скрипт заново.")
end)

-- === СИСТЕМА ЦЕЛЕЙ ===
local function getTargetId(target)
    if not target then return nil end
    local targetHRP = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head") or target.PrimaryPart
    if targetHRP then
        local pos = targetHRP.Position
        return string.format("%s_%.1f_%.1f_%.1f", target.Name, pos.X, pos.Y, pos.Z)
    end
    return tostring(target)
end

local function isTargetPurchased(target)
    local targetId = getTargetId(target)
    return purchasedTargets[targetId] == true
end

local function markTargetAsPurchased(target)
    local targetId = getTargetId(target)
    purchasedTargets[targetId] = true
    lastPurchaseTime = os.time()
    
    -- Обновляем статистику
    local purchasedCount = 0
    for _ in pairs(purchasedTargets) do
        purchasedCount = purchasedCount + 1
    end
    StatsLabel.Text = string.format("Purchased: %d | Stuck: %d", purchasedCount, stuckCount)
    
    print("✅ Цель куплена: " .. targetId)
end

-- === ХАОТИЧНЫЕ ДВИЖЕНИЯ ===
local function startChaoticMovement()
    if isChaoticMoving then return end
    
    isChaoticMoving = true
    chaoticMoveStartTime = os.time()
    stuckCount = stuckCount + 1
    
    print("🔄 Активация хаотичных движений...")
    updateUI(nil, "Target: Found\nStatus: STUCK!\nChaotic movement activated", nil)
    
    -- Создаем случайные точки для движения
    local randomPoints = {}
    local currentPos = hrp.Position
    
    for i = 1, 5 do
        local randomDir = Vector3.new(
            math.random(-20, 20),
            0,
            math.random(-20, 20)
        )
        table.insert(randomPoints, currentPos + randomDir)
    end
    
    -- Двигаемся по случайным точкам
    local chaoticThread = task.spawn(function()
        for _, point in ipairs(randomPoints) do
            if not isChaoticMoving then break end
            humanoid:MoveTo(point)
            task.wait(0.5)
        end
        
        -- Завершаем хаотичные движения
        isChaoticMoving = false
        lastDistanceChangeTime = os.time()
        lastDistance = math.huge
        
        print("✅ Хаотичные движения завершены")
        if currentTarget then
            updateUI(nil, "Target: Found\nStatus: Resuming...\nChaotic movement finished", nil)
        end
    end)
    
    -- Автоматическое завершение через CHAOTIC_MOVE_TIME секунд
    task.delay(CHAOTIC_MOVE_TIME, function()
        if isChaoticMoving then
            isChaoticMoving = false
            task.cancel(chaoticThread)
            print("✅ Хаотичные движения завершены по таймеру")
        end
    end)
end

local function checkIfStuck(currentDist)
    local currentTime = os.time()
    
    if currentDist >= lastDistance - 1 then -- Не приближаемся или стоим на месте
        if lastDistanceChangeTime == 0 then
            lastDistanceChangeTime = currentTime
        elseif currentTime - lastDistanceChangeTime > STUCK_TIME then
            -- Застряли более STUCK_TIME секунд
            if not isChaoticMoving then
                startChaoticMovement()
            end
        end
    else
        -- Двигаемся нормально
        lastDistanceChangeTime = currentTime
    end
    
    lastDistance = currentDist
end

-- === ПОИСК ЦЕЛЕЙ ===
local function findNearestTarget()
    local nearest, nearestDist = nil, math.huge
    local foundCount = 0
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == TARGET_NAME and obj:IsA("Model") then
            local targetHRP = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or target.PrimaryPart
            if targetHRP and targetHRP.Parent then
                foundCount = foundCount + 1
                
                -- Пропускаем купленные цели
                if isTargetPurchased(obj) then
                    continue
                end
                
                local dist = (hrp.Position - targetHRP.Position).Magnitude
                if dist < nearestDist then
                    nearest = obj
                    nearestDist = dist
                end
            end
        end
    end
    
    print("🔍 Найдено целей: " .. foundCount .. ", доступно: " .. (nearest and "1" or "0"))
    return nearest
end

local function getTargetPosition(target)
    if not target then return nil end
    local targetHRP = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head") or target.PrimaryPart
    return targetHRP and targetHRP.Position or nil
end

local function isTargetValid(target)
    if not target or not target.Parent then return false end
    local targetHRP = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head") or target.PrimaryPart
    return targetHRP and targetHRP.Parent ~= nil
end

-- === ПОКУПКА ===
local function pressE()
    print("🔼 Нажимаем E...")
    VirtualInputManager:SendKeyEvent(true, BUY_KEY, false, game)
    task.wait(HOLD_E_TIME)
    VirtualInputManager:SendKeyEvent(false, BUY_KEY, false, game)
    print("🔽 Отпускаем E")
end

-- === ОСНОВНОЙ ЦИКЛ ===
task.spawn(function()
    while task.wait(SEARCH_INTERVAL) do
        if not autoBuyEnabled then 
            if currentTarget then
                currentTarget = nil
                updateUI(nil, "Press RightShift to toggle\nTarget: None\nDistance: -\nStatus: Ready", nil)
            end
            continue 
        end

        -- Проверяем текущую цель
        if currentTarget and not isTargetValid(currentTarget) then
            print("❌ Цель исчезла")
            currentTarget = nil
        end

        -- Ищем новую цель
        if not currentTarget and not isChaoticMoving then
            local newTarget = findNearestTarget()
            if newTarget then
                currentTarget = newTarget
                local targetId = getTargetId(newTarget)
                print("🎯 Новая цель: " .. targetId)
                updateUI(nil, "Target: Found\nMoving to target...\nDistance: ...\nStatus: Moving", nil)
                -- Сбрасываем таймер застревания при новой цели
                lastDistanceChangeTime = os.time()
                lastDistance = math.huge
            else
                updateUI(nil, "Target: None\nNo available targets\nSearching...\nStatus: Searching", nil)
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not autoBuyEnabled or not currentTarget or not isTargetValid(currentTarget) or isBuying or isChaoticMoving then 
        return 
    end

    local targetPos = getTargetPosition(currentTarget)
    if not targetPos then
        currentTarget = nil
        return
    end

    local dist = (hrp.Position - targetPos).Magnitude

    -- Проверяем не застряли ли мы
    checkIfStuck(dist)

    -- Обновляем UI с дистанцией
    local statusText = isChaoticMoving and "Chaotic Moving" 
                     : (dist <= FOLLOW_DISTANCE) and "Ready to Buy" 
                     : "Moving"
    
    updateUI(nil, string.format("Target: Found\nStatus: %s\nDistance: %d studs\nAction: Following", statusText, math.floor(dist)), nil)

    if dist > FOLLOW_DISTANCE then
        -- Двигаемся к цели
        humanoid:MoveTo(targetPos)
    else
        -- Покупаем
        isBuying = true
        updateUI("BUYING!", "Target: Found\nStatus: BUYING NOW!\nDistance: " .. math.floor(dist) .. "\nAction: Purchasing", nil)
        
        print("💰 Начинаем покупку...")
        pressE()
        
        -- Помечаем как купленную
        markTargetAsPurchased(currentTarget)
        
        -- Сбрасываем цель и таймеры
        currentTarget = nil
        lastDistanceChangeTime = 0
        lastDistance = math.huge
        
        task.wait(1)
        isBuying = false
        
        updateUI(nil, "Target: None\nPurchase complete!\nSearching...\nStatus: Searching", nil)
        print("✅ Покупка завершена, ищем следующую цель")
    end
end)

-- === УПРАВЛЕНИЕ ===
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == TOGGLE_KEY then
        autoBuyEnabled = not autoBuyEnabled
        if autoBuyEnabled then
            updateUI("ON", "Target: Searching...\nStatus: Enabled\nLooking for targets...\nAction: Started", nil)
            currentTarget = nil
            isBuying = false
            isChaoticMoving = false
            lastDistanceChangeTime = 0
            lastDistance = math.huge
            print("🔛 AutoBuy ВКЛЮЧЕН")
        else
            updateUI("OFF", "Target: None\nStatus: Disabled\nPress RightShift to enable\nAction: Stopped", nil)
            currentTarget = nil
            isChaoticMoving = false
            print("🔴 AutoBuy ВЫКЛЮЧЕН")
        end
    end
end)

-- === ОБНОВЛЕНИЕ ПЕРСОНАЖА ===
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    hrp = character:WaitForChild("HumanoidRootPart")
    currentTarget = nil
    isBuying = false
    isChaoticMoving = false
    lastDistanceChangeTime = 0
    lastDistance = math.huge
    updateUI(nil, "Target: None\nCharacter respawned\nReady to search\nStatus: Ready", nil)
    print("🔄 Персонаж обновлен")
end)

-- === АВТООЧИСТКА ===
task.spawn(function()
    while task.wait(60) do -- Каждую минуту
        local currentTime = os.time()
        local toRemove = {}
        
        for targetId, purchaseTime in pairs(purchasedTargets) do
            if currentTime - purchaseTime > 300 then -- 5 минут
                table.insert(toRemove, targetId)
            end
        end
        
        for _, targetId in ipairs(toRemove) do
            purchasedTargets[targetId] = nil
        end
        
        if #toRemove > 0 then
            print("🔄 Очищено " .. #toRemove .. " старых целей")
            -- Обновляем статистику
            local purchasedCount = 0
            for _ in pairs(purchasedTargets) do
                purchasedCount = purchasedCount + 1
            end
            StatsLabel.Text = string.format("Purchased: %d | Stuck: %d", purchasedCount, stuckCount)
        end
    end
end)

-- === ДЕБАГ ФУНКЦИИ ===
local function debugTargets()
    print("=== ДЕБАГ ЦЕЛЕЙ ===")
    local allCount, availableCount = 0, 0
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == TARGET_NAME and obj:IsA("Model") then
            allCount = allCount + 1
            local targetHRP = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart
            if targetHRP and targetHRP.Parent then
                if not isTargetPurchased(obj) then
                    availableCount = availableCount + 1
                    local dist = (hrp.Position - targetHRP.Position).Magnitude
                    print("✅ Доступна: " .. getTargetId(obj) .. " | Дистанция: " .. math.floor(dist))
                else
                    print("❌ Куплена: " .. getTargetId(obj))
                end
            end
        end
    end
    
    print("Всего: " .. allCount .. ", Доступно: " .. availableCount)
    updateUI(nil, string.format("Debug Info:\nTotal: %d targets\nAvailable: %d targets\nStuck count: %d", allCount, availableCount, stuckCount), nil)
end

-- Глобальные функции для отладки
_G.debugTargets = debugTargets
_G.clearPurchased = function()
    purchasedTargets = {}
    stuckCount = 0
    StatsLabel.Text = "Purchased: 0 | Stuck: 0"
    print("🧹 Список купленных целей очищен")
end

_G.forceChaotic = function()
    if autoBuyEnabled then
        startChaoticMovement()
    else
        print("❌ Включите AutoBuy сначала!")
    end
end

-- Инициализация
updateUI("OFF", "Press RightShift to toggle\nTarget: None\nDistance: -\nStatus: Ready", "Purchased: 0 | Stuck: 0")
print("[AutoFollowAndBuy] Улучшенная версия загружена!")
print("📝 Press RightShift to toggle ON/OFF")
print("🎯 Перемещайте GUI за верхнюю панель")
print("🔘 Сворачивайте GUI кнопкой '-'")
print("🐛 Для отладки: debugTargets()")
print("🧹 Для очистки: clearPurchased()")
print("🔄 При застревании: forceChaotic()")