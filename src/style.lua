local UserInputService = game:GetService("UserInputService")

local Util = require("./util")
local finiteNumber = Util.finiteNumber

local Theme = {
    Background = Color3.fromRGB(15, 15, 15),
    Tab = Color3.fromRGB(25, 25, 25),
    TabActive = Color3.fromRGB(35, 35, 35),
    Element = Color3.fromRGB(20, 20, 20),
    ElementHover = Color3.fromRGB(32, 32, 32),
    ElementPressed = Color3.fromRGB(46, 46, 46),
    BorderHover = Color3.fromRGB(76, 76, 76),
    Text = Color3.fromRGB(216, 216, 216),
    TextDim = Color3.fromRGB(145, 145, 145),
    Accent = Color3.fromRGB(255, 255, 255),
    Border = Color3.fromRGB(45, 45, 45),
    Track = Color3.fromRGB(10, 10, 10),
    Warning = Color3.fromRGB(245, 194, 121)
}

local ROW_INSET = 12
local TITLE_HEIGHT = 34
local TAB_HEIGHT = UserInputService.TouchEnabled and 48 or 38
local INPUT_ROW_HEIGHT = UserInputService.TouchEnabled and 52 or 30

local function createRow(tab, className, name, height, minimumHeight)
    assert(not tab.Destroyed and not tab.library.Destroyed and not tab.library._destroying, "Cannot add controls to a destroyed UI")
    local row = Instance.new(className)
    row.Name = name
    row.Parent = tab.content
    row.BackgroundColor3 = Theme.Element
    row.BorderColor3 = Theme.Border
    row.BorderSizePixel = 1
    row.Size = UDim2.new(1, 0, 0, math.max(minimumHeight, UserInputService.TouchEnabled and 44 or 0, finiteNumber(height, minimumHeight)))
    row.AnchorPoint = Vector2.new(0.5, 0)
    row.Position = UDim2.new(0.5, 0, 0, 0)
    return row
end

local function createLabel(parent, text, textSize)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = Enum.Font.Code
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = textSize or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function createInputSurface(parent, className)
    local surface = Instance.new(className)
    surface.Parent = parent
    surface.BackgroundColor3 = Theme.Background
    surface.BorderColor3 = Theme.Border
    surface.BorderSizePixel = 1
    surface.AnchorPoint = Vector2.new(1, 0)
    surface.Position = UDim2.new(1, -8, 0, 4)
    surface.Size = UDim2.new(0.58, -8, 1, -8)
    return surface
end

local function createTrack(parent, color)
    local track = Instance.new("Frame")
    track.Parent = parent
    track.BackgroundColor3 = Theme.Track
    track.BorderSizePixel = 0
    track.Position = UDim2.new(0, 10, 1, -17)
    track.Size = UDim2.new(1, -20, 0, 6)

    local fill = Instance.new("Frame")
    fill.Parent = track
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    return track, fill
end

return {
    Theme = Theme,
    ROW_INSET = ROW_INSET,
    TITLE_HEIGHT = TITLE_HEIGHT,
    TAB_HEIGHT = TAB_HEIGHT,
    INPUT_ROW_HEIGHT = INPUT_ROW_HEIGHT,
    createRow = createRow,
    createLabel = createLabel,
    createInputSurface = createInputSurface,
    createTrack = createTrack,
}
