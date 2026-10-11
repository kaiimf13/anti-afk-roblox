-- Anti-AFK + GUI (satu script) untuk Delta
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Bersihkan instance lama jika script dieksekusi ulang
local env = (getgenv and getgenv()) or _G
if env.AntiAFK_Cleanup then pcall(env.AntiAFK_Cleanup) end

local alive = true
local afkEnabled = false
local connections = {}
local function track(c) table.insert(connections, c) return c end

-- Parent GUI
local parentGui
pcall(function() parentGui = gethui() end)
parentGui = parentGui or game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "AntiAFK_GUI"
gui.ResetOnSpawn = false
gui.Parent = parentGui

env.AntiAFK_Cleanup = function()
    alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    pcall(function() gui:Destroy() end)
end

-- ========== LOGIKA ANTI-AFK ==========
track(player.Idled:Connect(function()
    if afkEnabled then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

task.spawn(function()
    while alive do
        task.wait(60)
        if alive and afkEnabled then
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:Move(Vector3.new(1, 0, 0), true)
                task.wait(0.3)
                hum:Move(Vector3.new(-1, 0, 0), true)
                hum.Jump = true
            end
        end
    end
end)

-- ========== DRAG (HP & PC) ==========
local function makeDraggable(obj, handle)
    handle = handle or obj
    local dragging, dragStart, startPos
    track(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
end

-- ========== GUI ==========
local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function round(o, r) Instance.new("UICorner", o).CornerRadius = UDim.new(0, r) end

local main = make("Frame", {
    Size = UDim2.new(0, 200, 0, 110),
    Position = UDim2.new(0.5, -100, 0.3, 0),
    BackgroundColor3 = Color3.fromRGB(30, 30, 35),
    BorderSizePixel = 0,
}, gui)
round(main, 10)

local title = make("TextLabel", {
    Size = UDim2.new(1, -40, 0, 30), Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1, Text = "Anti-AFK", TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold, TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
}, main)

local minBtn = make("TextButton", {
    Size = UDim2.new(0, 28, 0, 22), Position = UDim2.new(1, -34, 0, 4),
    BackgroundColor3 = Color3.fromRGB(60, 60, 70), Text = "-",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 18,
}, main)
round(minBtn, 6)

local toggleBtn = make("TextButton", {
    Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0, 38),
    BackgroundColor3 = Color3.fromRGB(200, 60, 60), Text = "OFF",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 18,
}, main)
round(toggleBtn, 8)

local status = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 0, 84),
    BackgroundTransparency = 1, Text = "Status: Nonaktif",
    TextColor3 = Color3.fromRGB(180, 180, 180), Font = Enum.Font.Gotham, TextSize = 13,
}, main)

local floatBtn = make("TextButton", {
    Size = UDim2.new(0, 44, 0, 44), Position = UDim2.new(0, 15, 0.5, 0),
    BackgroundColor3 = Color3.fromRGB(200, 60, 60), Text = "AFK",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13,
}, gui)
round(floatBtn, 22)

-- ========== TOMBOL ==========
local function updateVisual()
    local color = afkEnabled and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(200, 60, 60)
    toggleBtn.Text = afkEnabled and "ON" or "OFF"
    status.Text = afkEnabled and "Status: Aktif" or "Status: Nonaktif"
    toggleBtn.BackgroundColor3 = color
    floatBtn.BackgroundColor3 = color
end

track(toggleBtn.MouseButton1Click:Connect(function()
    afkEnabled = not afkEnabled
    updateVisual()
end))
track(minBtn.MouseButton1Click:Connect(function() main.Visible = false end))
track(floatBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end))

makeDraggable(main, title)
makeDraggable(floatBtn)