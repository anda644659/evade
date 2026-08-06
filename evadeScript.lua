local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ===== 全局变量（主UI控制） =====
local speed = 55
local mainUI = nil
local mainUIVisible = true

-- ===== 独立状态表（每个按钮独立） =====
local states = {
    jump = { running = false, bodyVelocity = nil, loopConn = nil },
    noJump = { running = false, bodyVelocity = nil, loopConn = nil }
}

-- ===== 清理函数（按类型） =====
local function stopAll(type)
    local state = states[type]
    if not state then return end
    state.running = false
    if state.loopConn then state.loopConn:Disconnect() state.loopConn = nil end
    if state.bodyVelocity then state.bodyVelocity:Destroy() state.bodyVelocity = nil end
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = 16
    end
end

-- ===== 核心循环（带跳跃参数） =====
local function startLoop(type, enableJump)
    local state = states[type]
    if not state then return end
    if state.loopConn then state.loopConn:Disconnect() end

    state.loopConn = game:GetService("RunService").Stepped:Connect(function()
        if not state.running then
            if state.bodyVelocity then state.bodyVelocity:Destroy() state.bodyVelocity = nil end
            return
        end

        local charNow = player.Character
        if not charNow then return end
        local rootNow = charNow:FindFirstChild("HumanoidRootPart")
        if not rootNow then return end

        if not state.bodyVelocity or state.bodyVelocity.Parent ~= rootNow then
            if state.bodyVelocity then state.bodyVelocity:Destroy() end
            state.bodyVelocity = Instance.new("BodyVelocity")
            state.bodyVelocity.MaxForce = Vector3.new(1e9, 0, 1e9)
            state.bodyVelocity.Parent = rootNow
        end

        local look = camera.CFrame.LookVector
        look = Vector3.new(look.X, 0, look.Z).Unit
        if look.Magnitude > 0 then
            state.bodyVelocity.Velocity = look * speed
        end

        if enableJump then
            local humanoid = charNow:FindFirstChild("Humanoid")
            if humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

-- ===== 创建副UI（通用） =====
local function createSubUI(type, btnText, enableJump)
    -- 如果已存在同类型，先销毁
    local guiName = (type == "jump") and "冲刺按钮_跳跃" or "冲刺按钮_无跳跃"
    local existing = game:GetService("CoreGui"):FindFirstChild(guiName)
    if existing then existing:Destroy() end

    local subUI = Instance.new("ScreenGui")
    subUI.Name = guiName
    subUI.Parent = game:GetService("CoreGui")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 55)
    -- 位置偏移，避免重叠
    local yOffset = (type == "jump") and -27 or 60
    btn.Position = UDim2.new(0.5, -80, 0.5, yOffset)
    btn.Text = btnText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    btn.BackgroundTransparency = 0
    btn.BorderSizePixel = 0
    btn.Active = true
    btn.Draggable = true
    btn.Parent = subUI

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn

    -- 状态同步（如果已经运行）
    local state = states[type]
    if state.running then
        btn.Text = (type == "jump") and "⏹ 停止跳跃冲刺" or "⏹ 停止无跳跃冲刺"
        btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end

    -- 点击切换
    btn.MouseButton1Click:Connect(function()
        state.running = not state.running
        if state.running then
            btn.Text = (type == "jump") and "⏹ 停止跳跃冲刺" or "⏹ 停止无跳跃冲刺"
            btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            startLoop(type, enableJump)
            print("🚀 " .. (type == "jump" and "跳跃冲刺" or "无跳跃冲刺") .. " 启动，速度 " .. speed)
        else
            btn.Text = (type == "jump") and "▶ 跳跃冲刺" or "▶ 无跳跃冲刺"
            btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            stopAll(type)
            print("⏹ " .. (type == "jump" and "跳跃冲刺" or "无跳跃冲刺") .. " 停止")
        end
    end)
end

-- ===== 创建隐藏按钮（右上角） =====
local function createHideButton()
    local hideGui = Instance.new("ScreenGui")
    hideGui.Name = "隐藏按钮"
    hideGui.Parent = game:GetService("CoreGui")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 35)
    btn.Position = UDim2.new(1, -90, 0, 10)
    btn.Text = "🟢 隐藏主UI"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    btn.Parent = hideGui
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        mainUIVisible = not mainUIVisible
        if mainUIVisible then
            btn.Text = "🟢 隐藏主UI"
            btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
            if mainUI then mainUI.Enabled = true end
        else
            btn.Text = "🔴 显示主UI"
            btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            if mainUI then mainUI.Enabled = false end
        end
    end)
end

-- ===== 创建主UI（右上角） =====
local function createMainUI()
    mainUI = Instance.new("ScreenGui")
    mainUI.Name = "添加UI主菜单"
    mainUI.Parent = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 240)  -- 高度增加
    frame.Position = UDim2.new(1, -230, 0, 55)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BackgroundTransparency = 0.2
    frame.Active = true
    frame.Draggable = true
    frame.Parent = mainUI

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.Text = "➕ 冲刺生成器"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    -- 速度输入框
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(0, 150, 0, 35)
    inputBox.Position = UDim2.new(0.5, -75, 0, 45)
    inputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    inputBox.BackgroundTransparency = 0.3
    inputBox.Text = "55"
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.TextScaled = true
    inputBox.Font = Enum.Font.GothamBold
    inputBox.PlaceholderText = "速度数值"
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = frame
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputBox
    inputBox.FocusLost:Connect(function()
        local val = tonumber(inputBox.Text)
        if val and val > 0 then
            speed = val
            print("⚡ 速度已设置为: " .. speed)
        else
            inputBox.Text = tostring(speed)
        end
    end)

    -- 按钮1：带跳跃
    local btn1 = Instance.new("TextButton")
    btn1.Size = UDim2.new(0, 160, 0, 35)
    btn1.Position = UDim2.new(0.5, -80, 0, 95)
    btn1.Text = "📌 生成跳跃冲刺"
    btn1.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn1.TextScaled = true
    btn1.Font = Enum.Font.GothamBold
    btn1.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    btn1.Parent = frame
    local btn1Corner = Instance.new("UICorner")
    btn1Corner.CornerRadius = UDim.new(0, 8)
    btn1Corner.Parent = btn1
    btn1.MouseButton1Click:Connect(function()
        createSubUI("jump", "▶ 跳跃冲刺", true)
    end)

    -- 按钮2：无跳跃
    local btn2 = Instance.new("TextButton")
    btn2.Size = UDim2.new(0, 160, 0, 35)
    btn2.Position = UDim2.new(0.5, -80, 0, 140)
    btn2.Text = "📌 生成无跳跃冲刺"
    btn2.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn2.TextScaled = true
    btn2.Font = Enum.Font.GothamBold
    btn2.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    btn2.Parent = frame
    local btn2Corner = Instance.new("UICorner")
    btn2Corner.CornerRadius = UDim.new(0, 8)
    btn2Corner.Parent = btn2
    btn2.MouseButton1Click:Connect(function()
        createSubUI("noJump", "▶ 无跳跃冲刺", false)
    end)

    -- 提示
    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(1, 0, 0, 20)
    hint.Position = UDim2.new(0, 0, 0, 190)
    hint.Text = "速度同步，独立开关"
    hint.TextColor3 = Color3.fromRGB(150, 150, 150)
    hint.TextScaled = true
    hint.BackgroundTransparency = 1
    hint.Font = Enum.Font.Gotham
    hint.Parent = frame
end

-- ===== 启动 =====
createHideButton()
createMainUI()

print("✅ 加载完成")
print("📌 主UI生成两个冲刺按钮，速度共享")
print("📌 跳跃冲刺：落地自动跳跃；无跳跃：纯地面冲刺")