-- Edit the source modules here, then rebuild the root main.lua with Darklua.

local UserInputService = game:GetService("UserInputService")

local Style = require("./style")
local Theme = Style.Theme
local ROW_INSET = Style.ROW_INSET
local TITLE_HEIGHT = Style.TITLE_HEIGHT
local TAB_HEIGHT = Style.TAB_HEIGHT
local createLabel = Style.createLabel
local Input = require("./input")
local bindButtonFeedback = Input.bindButtonFeedback
local isPointerPress = Input.isPointerPress
local isVisible = Input.isVisible
local Util = require("./util")
local finiteNumber = Util.finiteNumber
local getEnvFunction = Util.getEnvFunction
local safeCall = Util.safeCall

local UILibrary = {}
UILibrary.__index = UILibrary

for _, methods in ipairs({require("./config"), require("./focus"), require("./background"), require("./tabs")}) do
    for name, method in pairs(methods) do UILibrary[name] = method end
end

local DEFAULT_MAX_SIZE = Vector2.new(10000, 10000)

local function normalizeVectorSize(value, fallback)
    fallback = fallback or Vector2.new(0, 0)

    if typeof(value) == "Vector2" then
        return Vector2.new(finiteNumber(value.X, fallback.X), finiteNumber(value.Y, fallback.Y))
    end

    if typeof(value) == "UDim2" then
        return Vector2.new(value.X.Offset, value.Y.Offset)
    end

    if type(value) == "table" then
        local x = value.X or value.x or value.Width or value.width or value[1]
        local y = value.Y or value.y or value.Height or value.height or value[2]
        return Vector2.new(finiteNumber(x, fallback.X), finiteNumber(y, fallback.Y))
    end

    return fallback
end

local function clampVectorSize(size, minSize, maxSize)
    minSize = minSize or Vector2.new(0, 0)
    maxSize = maxSize or DEFAULT_MAX_SIZE

    return Vector2.new(
        math.clamp(size.X, math.max(1, minSize.X), math.max(1, minSize.X, maxSize.X)),
        math.clamp(size.Y, math.max(1, minSize.Y), math.max(1, minSize.Y, maxSize.Y))
    )
end

function UILibrary:_ViewportBounds()
    local viewport = self.ScreenGui.AbsoluteSize
    local width, height = math.max(1, viewport.X), math.max(1, viewport.Y)
    if UserInputService.OnScreenKeyboardVisible then
        local keyboardY = UserInputService.OnScreenKeyboardPosition.Y - self.ScreenGui.AbsolutePosition.Y
        if keyboardY > 0 then height = math.min(height, keyboardY) end
    end
    local margin = math.min(self.ViewportMargin, width * 0.05, height * 0.05)
    local mobile = UserInputService.TouchEnabled and (width < 900 or height < 600)
    local maximum = Vector2.new(
        math.max(1, math.min(width - 2 * margin, width * (mobile and 0.9 or 0.96))),
        math.max(1, math.min(height - 2 * margin, height * (mobile and 0.72 or 0.9)))
    )
    return Vector2.new(width, height), margin, maximum
end

function UILibrary:_FitViewport()
    if self.Destroyed or not self.MainFrame or self.ScreenGui.AbsoluteSize.X <= 0 then return end
    local viewport, margin, cap = self:_ViewportBounds()
    local maximum = Vector2.new(math.min(cap.X, math.max(1, self.MinSize.X, self.MaxSize.X)),
        math.min(cap.Y, math.max(1, self.MinSize.Y, self.MaxSize.Y)))
    local minimum = Vector2.new(math.min(maximum.X, math.max(1, self.MinSize.X)),
        math.min(maximum.Y, math.max(1, self.MinSize.Y)))
    self.SizeConstraint.MinSize = Vector2.new(0, 0)
    self.SizeConstraint.MaxSize = maximum
    self.SizeConstraint.MinSize = minimum
    local requested = self._requestedSize or Vector2.new(600, 400)
    if self._requestedScale then
        local size = self._requestedScale
        requested = Vector2.new(finiteNumber(viewport.X * size.X.Scale + size.X.Offset, requested.X),
            finiteNumber(viewport.Y * size.Y.Scale + size.Y.Offset, requested.Y))
    end
    local size = clampVectorSize(requested, minimum, maximum)
    self.MainFrame.Size = UDim2.new(0, math.floor(size.X), 0, math.floor(size.Y))
    local position = self.MainFrame.Position
    local x = finiteNumber(position.X.Scale * viewport.X + position.X.Offset, margin)
    local y = finiteNumber(position.Y.Scale * viewport.Y + position.Y.Offset, margin)
    self.MainFrame.Position = UDim2.new(0, math.clamp(x, margin, math.max(margin, viewport.X - size.X - margin)),
        0, math.clamp(y, margin, math.max(margin, viewport.Y - size.Y - margin)))
    self:_HideTooltip()
end

function UILibrary:SetSize(width, height)
    if not self.MainFrame or self.Destroyed then return end
    self._requestedScale = typeof(width) == "UDim2" and width or nil
    if not self._requestedScale then
        self._requestedSize = (typeof(width) == "Vector2" or type(width) == "table")
            and normalizeVectorSize(width, self.MainFrame.AbsoluteSize)
            or Vector2.new(finiteNumber(width, self.MainFrame.AbsoluteSize.X), finiteNumber(height, self.MainFrame.AbsoluteSize.Y))
    end
    self:_FitViewport()
end

function UILibrary:GetSize()
    if not self.MainFrame then
        return Vector2.new(0, 0)
    end

    return self.MainFrame.AbsoluteSize
end

function UILibrary:SetResizeBounds(minSize, maxSize)
    self.MinSize = normalizeVectorSize(minSize, self.MinSize)
    self.MaxSize = normalizeVectorSize(maxSize, self.MaxSize)
    self:_FitViewport()
end

function UILibrary:SetResizable(enabled)
    if self.Destroyed then return end
    self.ResizeEnabled = enabled ~= false
    if not self.ResizeEnabled and self._stopGestures then self._stopGestures() end
    if self.ResizeHandle then
        self.ResizeHandle.Visible = self.ResizeEnabled
    end
end

function UILibrary.new(args)
    args = args or {}
    local self = setmetatable({}, UILibrary)

    self.Destroyed = false
    self._connections = {}
    self.flags = {}
    self.loadedFlags = {}
    self.elementsByFlag = {}
    self.ConfigFolder = args.ConfigFolder
    self.AutoSave = args.AutoSave ~= false
    self.TabScrollBarThickness = args.TabScrollBarThickness or 4
    self.TabPadding = args.TabPadding or 0
    self.ResizeEnabled = args.ResizeEnabled ~= false
    self.MinSize = normalizeVectorSize(args.MinSize, Vector2.new(420, 300))
    self.MaxSize = normalizeVectorSize(args.MaxSize, DEFAULT_MAX_SIZE)
    self.ResizeHandleSize = args.ResizeHandleSize or (UserInputService.TouchEnabled and 28 or 16)
    self.ViewportMargin = math.max(8, finiteNumber(args.ViewportMargin, 16))

    if self.ConfigFolder then
        local makefolder = getEnvFunction("makefolder")
        local isfolder = getEnvFunction("isfolder")
        if makefolder then
            local okFolder = true
            if isfolder then
                local ok, exists = safeCall(isfolder, self.ConfigFolder)
                okFolder = ok and exists
            else
                okFolder = false
            end
            if not okFolder then
                safeCall(makefolder, self.ConfigFolder)
            end
        end
    end
    assert(self:SetConfigFile(args.ConfigFile or args.ConfigName or (args.GuiName or "UILibrary") .. ".json"),
        "Invalid config file path; the .bak suffix is reserved")

    if args.AutoLoad ~= false then
        self:LoadConfig(false)
    end

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = args.GuiName or "UILibrary"
    self.ScreenGui.Parent = args.Parent or (gethui and gethui()) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainFrame"
    self.MainFrame.Parent = self.ScreenGui
    self.MainFrame.BackgroundColor3 = Theme.Background
    self.MainFrame.BorderColor3 = Theme.Border
    self.MainFrame.BorderSizePixel = 1
    self.MainFrame.Position = args.Position or UDim2.new(0, 100, 0, 100)
    self.MainFrame.Size = args.Size or UDim2.new(0, 600, 0, 400)
    self.MainFrame.Visible = true
    self.MainFrame.ClipsDescendants = true
    self.SizeConstraint = Instance.new("UISizeConstraint")
    self.SizeConstraint.Parent = self.MainFrame
    self:SetSize(args.Size or UDim2.new(0, 600, 0, 400))

    -- Sibling ordering keeps each control's children above its own surface.
    -- Explicit window layers keep content above the image and below popups.
    self.BackgroundTransparency = math.clamp(finiteNumber(args.BackgroundTransparency, 0.5), 0, 1)
    self.ElementTransparency = math.clamp(finiteNumber(args.ElementTransparency, 0.3), 0, 1)
    self.BackgroundEnabled = false
    self.BackgroundImage = Instance.new("ImageLabel")
    self.BackgroundImage.Name = "Background"
    self.BackgroundImage.Parent = self.MainFrame
    self.BackgroundImage.BackgroundTransparency = 1
    self.BackgroundImage.BorderSizePixel = 0
    self.BackgroundImage.Position = UDim2.new(0, 0, 0, 0)
    self.BackgroundImage.Size = UDim2.new(1, 0, 1, 0)
    self.BackgroundImage.Image = ""
    self.BackgroundImage.ScaleType = Enum.ScaleType.Stretch
    self.BackgroundImage.ImageTransparency = self.BackgroundTransparency
    self.BackgroundImage.Visible = false
    self.BackgroundImage.ZIndex = 1

    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar:SetAttribute("__uiChrome", true)
    self.TitleBar.Parent = self.MainFrame
    self.TitleBar.BackgroundColor3 = Theme.Tab
    self.TitleBar.BorderColor3 = Theme.Border
    self.TitleBar.BorderSizePixel = 1
    self.TitleBar.Size = UDim2.new(1, 0, 0, TITLE_HEIGHT)
    self.TitleBar.ZIndex = 3

    local titleLabel = createLabel(self.TitleBar, args.Title or "GUI", 15)
    titleLabel.Name = "Title"
    titleLabel.Position = UDim2.fromOffset(ROW_INSET, 0)
    titleLabel.TextColor3 = Theme.Accent
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.ZIndex = 3
    self:_DecorateObject(titleLabel)
    self.SaveIndicator = createLabel(self.TitleBar, "", 11)
    self.SaveIndicator.Position = UDim2.new(1, -96, 0, 0)
    self.SaveIndicator.Size = UDim2.new(0, 86, 1, 0)
    self.SaveIndicator.TextColor3 = Theme.Warning
    self.SaveIndicator.TextXAlignment = Enum.TextXAlignment.Right
    self:_SetSaveStatus(self.SaveStatus or "Ready")

    self.TabContainer = Instance.new("ScrollingFrame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer:SetAttribute("__uiChrome", true)
    self.TabContainer.Parent = self.MainFrame
    self.TabContainer.BackgroundColor3 = Theme.Tab
    self.TabContainer.BorderColor3 = Theme.Border
    self.TabContainer.BorderSizePixel = 1
    self.TabContainer.Position = UDim2.fromOffset(0, TITLE_HEIGHT)
    self.TabContainer.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
    self.TabContainer.ClipsDescendants = true
    self.TabContainer.Active = true
    self.TabContainer.Selectable = false
    self.TabContainer.ScrollingDirection = Enum.ScrollingDirection.X
    self.TabContainer.ScrollBarThickness = self.TabScrollBarThickness
    self.TabContainer.ScrollBarImageColor3 = Theme.BorderHover
    self.TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.None
    self.TabContainer.ZIndex = 3

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Parent = self.TabContainer
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, self.TabPadding)

    local function refreshTabCanvas()
        task.defer(function()
            if not self.Destroyed and self.TabContainer.Parent and tabLayout.Parent then
                self.TabContainer.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + self.TabPadding, 0, 0)
            end
        end)
    end

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshTabCanvas)

    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Name = "ContentArea"
    self.ContentArea.Parent = self.MainFrame
    self.ContentArea.BackgroundColor3 = Theme.Background
    self.ContentArea.BorderSizePixel = 0
    self.ContentArea.Position = UDim2.fromOffset(0, TITLE_HEIGHT + TAB_HEIGHT)
    self.ContentArea.Size = UDim2.new(1, 0, 1, -TITLE_HEIGHT - TAB_HEIGHT)
    self.ContentArea.ClipsDescendants = true
    self.ContentArea.ZIndex = 2

    self.ResizeHandle = Instance.new("TextButton")
    self.ResizeHandle.Name = "ResizeHandle"
    self.ResizeHandle.Parent = self.MainFrame
    self.ResizeHandle.BackgroundColor3 = Theme.Element
    self.ResizeHandle.BackgroundTransparency = 0.25
    self.ResizeHandle.BorderSizePixel = 0
    self.ResizeHandle.AnchorPoint = Vector2.new(1, 1)
    self.ResizeHandle.Position = UDim2.new(1, 0, 1, 0)
    self.ResizeHandle.Size = UDim2.new(0, self.ResizeHandleSize, 0, self.ResizeHandleSize)
    self.ResizeHandle.Text = ""
    self.ResizeHandle.AutoButtonColor = false
    self.ResizeHandle.Selectable = false
    self.ResizeHandle.Visible = self.ResizeEnabled
    self.ResizeHandle.ZIndex = 10
    local resetResizeFeedback = bindButtonFeedback(self.ResizeHandle, Theme.Element)
    self.ResizeHandle:GetPropertyChangedSignal("Visible"):Connect(function()
        if not self.ResizeHandle.Visible then resetResizeFeedback() end
    end)

    for _, size in ipairs({UDim2.fromOffset(8, 1), UDim2.fromOffset(1, 8)}) do
        local cornerLine = Instance.new("Frame")
        cornerLine.Name = "CornerMark"
        cornerLine.BackgroundColor3 = Theme.Text
        cornerLine.BorderSizePixel = 0
        cornerLine.AnchorPoint = Vector2.new(1, 1)
        cornerLine.Position = UDim2.new(1, -3, 1, -3)
        cornerLine.Size = size
        cornerLine.ZIndex = 11
        cornerLine.Parent = self.ResizeHandle
    end

    self.tabs = {}
    self.currentTab = nil
    local function resetTabFeedback()
        for _, tab in ipairs(self.tabs) do tab._resetFeedback() end
    end
    self.TabContainer.MouseLeave:Connect(resetTabFeedback)
    self.TabContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(resetTabFeedback)

    local dragging, resizing = false, false
    local pointer, dragStart, startPos, resizeStart, startSize
    local function stopGestures()
        dragging, resizing = false, false
        pointer = nil
        self.TitleBar.BorderColor3 = Theme.Border
    end
    self._stopGestures = stopGestures
    local function cancelWindowInteractions()
        stopGestures()
        self:_CancelInteractions()
        self._capturedInput = nil
        self:_ClearNavigation()
        resetTabFeedback()
        resetResizeFeedback()
    end
    self.MainFrame.InputBegan:Connect(function(input)
        if isPointerPress(input) and isVisible(self, self.MainFrame) then self:_ClaimNavigation() end
    end)
    self.TitleBar.Active = true
    self.TitleBar.InputBegan:Connect(function(input)
        if dragging or resizing or not isPointerPress(input) or not isVisible(self, self.TitleBar) then return end
        for _, tab in ipairs(self.tabs) do
            if tab.name == self.currentTab then self:_SetPointerOrigin(tab.button); break end
        end
        dragging = true
        pointer, dragStart, startPos = input, input.Position, self.MainFrame.Position
        self.TitleBar.BorderColor3 = Theme.BorderHover
    end)
    self.ResizeHandle.InputBegan:Connect(function(input)
        if dragging or resizing or not self.ResizeEnabled or not isPointerPress(input)
            or not isVisible(self, self.ResizeHandle) then return end
        resizing = true
        pointer, resizeStart, startSize = input, input.Position, self.MainFrame.AbsoluteSize
    end)
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if not pointer then return end
        if not isVisible(self, self.MainFrame)
            or input == pointer and input.UserInputState == Enum.UserInputState.Cancel then stopGestures(); return end
        if input ~= pointer and not (pointer.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement) then return end
        if resizing and self.ResizeEnabled then
            local delta = input.Position - resizeStart
            self:SetSize(startSize.X + delta.X, startSize.Y + delta.Y)
        elseif dragging then
            local delta = input.Position - dragStart
            local viewport = self.MainFrame.Parent.AbsoluteSize
            local x = startPos.X.Scale * viewport.X + startPos.X.Offset + delta.X
            local y = startPos.Y.Scale * viewport.Y + startPos.Y.Offset + delta.Y
            self.MainFrame.Position = UDim2.new(0, x, 0, y)
            self:_FitViewport()
        end
    end))
    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if self._capturedInput == input then self._capturedInput = nil end
        if input == pointer then stopGestures() end
    end))
    table.insert(self._connections, UserInputService.WindowFocusReleased:Connect(cancelWindowInteractions))
    local visibilityKey = args.KeyCode or Enum.KeyCode.KeypadZero
    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if self:_HandleInput(input, gameProcessed, visibilityKey) then self._capturedInput = input end
    end))
    self.MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if not self.MainFrame.Visible then cancelWindowInteractions() end
    end)
    self.ScreenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
        if not self.ScreenGui.Enabled then cancelWindowInteractions() end
    end)
    self.ScreenGui.Destroying:Connect(function()
        self._screenDestroying = true
        self:Destroy()
    end)
    table.insert(self._connections, self.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        stopGestures()
        self:_FitViewport()
    end))
    for _, property in ipairs({"OnScreenKeyboardVisible", "OnScreenKeyboardPosition"}) do
        table.insert(self._connections, UserInputService:GetPropertyChangedSignal(property):Connect(function() self:_FitViewport() end))
    end
    task.defer(function() if not self.Destroyed then self:_FitViewport() end end)

    local background = args.Background or args.BackgroundImage
    if background then
        self:SetBackground(background, args.BackgroundTransparency)
    end

    return self
end

return UILibrary
