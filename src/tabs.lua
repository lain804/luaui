local Style = require("./style")
local Theme = Style.Theme
local ROW_INSET = Style.ROW_INSET
local Input = require("./input")
local isVisible = Input.isVisible
local bindButtonFeedback = Input.bindButtonFeedback
local bindActivation = Input.bindActivation
local revealSelection = Input.revealSelection

local Basic = require("./controls/basic")
local Range = require("./controls/range")

local Tab = {}
Tab.__index = Tab

function Tab:_NextLayoutOrder()
    assert(not self.Destroyed and not self.library.Destroyed and not self.library._destroying, "Cannot add controls to a destroyed UI")
    self._layoutOrder = (self._layoutOrder or 0) + 1
    return self._layoutOrder
end

function Tab:_RefreshCanvas()
    if self.Destroyed or self._canvasPending or not self.content or not self.layout then return end
    self._canvasPending = true
    task.defer(function()
        self._canvasPending = false
        if not self.Destroyed and self.content.Parent and self.layout.Parent then
            self.content.CanvasSize = UDim2.new(0, 0, 0, self.layout.AbsoluteContentSize.Y + 20)
        end
    end)
end

function Tab:_FindElement(instance)
    for _, element in ipairs(self.elements) do
        if element.Instance == instance then return element end
    end
end

function Tab:Remove(target)
    target = self:_FindElement(target) or target
    if typeof(target) == "Instance" then
        target:Destroy()
        self:_RefreshCanvas()
        return
    end
    if type(target) == "table" and target.Remove then
        target:Remove()
    end
end

function Tab:Hide(target)
    target = self:_FindElement(target) or target
    if typeof(target) == "Instance" then
        target.Parent = nil
        self:_RefreshCanvas()
        return
    end
    if type(target) == "table" and target.Hide then
        target:Hide()
    end
end

function Tab:Show(target)
    target = self:_FindElement(target) or target
    if type(target) == "table" and target.Show then
        target:Show()
    end
end

function Tab:_BindFlag(flag, element)
    if flag then
        assert(not self.library.elementsByFlag[flag], "Duplicate flag: " .. tostring(flag))
        self.library.elementsByFlag[flag] = element
        self.library:_StoreFlag(flag, element:_GetPersistedValue(), true)
    end
end

function Tab:_GetSaved(flag, default)
    assert(not self.Destroyed and not self.library.Destroyed and not self.library._destroying, "Cannot add controls to a destroyed UI")
    assert(not flag or not self.library.elementsByFlag[flag], "Duplicate flag: " .. tostring(flag))
    if flag and self.library.flags[flag] ~= nil then
        return self.library.flags[flag], true
    end
    return default, false
end

function Tab:_SaveFlag(flag, value)
    if not flag then return end
    self.library:_StoreFlag(flag, value)
end

for _, controls in ipairs({Basic, Range}) do
    for name, constructor in pairs(controls) do Tab[name] = constructor end
end
Tab.Dropdown = require("./controls/dropdown")
Tab.Keybind = require("./controls/keybind")
Tab.Textbox = require("./controls/textbox")

function Tab:RemoveTab()
    if self.Destroyed then return end
    self.Destroyed = true
    for index = #self.elements, 1, -1 do self.elements[index]:Remove() end
    if not self._buttonDestroying then self.button:Destroy() end
    if not self._contentDestroying then self.content:Destroy() end
    for i, item in ipairs(self.library.tabs) do
        if item == self then
            table.remove(self.library.tabs, i)
            break
        end
    end
    if self.library.currentTab == self.name then
        local first = self.library.tabs[1]
        if first then
            self.library:SwitchTab(first.name)
        else
            self.library.currentTab = nil
        end
    end
end

function Tab:_RevealButton()
    task.defer(function()
        local button = self.button
        if self.Destroyed or not isVisible(self.library, button) then return end
        revealSelection(self.library.TabContainer, button, "X")
    end)
end

local Tabs = {}

function Tabs:CreateTab(args)
    args = args or {}
    assert(not self.Destroyed and not self._destroying, "Cannot create a tab on a destroyed library")
    local name = args.Name or "Tab"
    for _, existing in ipairs(self.tabs) do
        assert(existing.name ~= name, "Duplicate tab: " .. tostring(name))
    end

    local tab = setmetatable({
        library = self,
        name = name,
        elements = {},
        _layoutOrder = 0
    }, Tab)

    tab.button = Instance.new("TextButton")
    tab.button.Name = name
    tab.button:SetAttribute("__uiChrome", true)
    tab.button.Parent = self.TabContainer
    tab.button.BackgroundColor3 = Theme.Tab
    tab.button.BorderColor3 = Theme.Border
    tab.button.BorderSizePixel = 0
    tab.button.Size = UDim2.new(0, args.Width or 120, 1, -self.TabScrollBarThickness)
    tab.button.Font = Enum.Font.Code
    tab.button.Text = name
    tab.button.TextColor3 = Theme.TextDim
    tab.button.TextSize = args.TextSize or 13
    tab.button.AutoButtonColor = false
    tab.button.TextTruncate = Enum.TextTruncate.AtEnd
    self:_DecorateObject(tab.button)
    tab._resetFeedback, tab._setActiveFeedback = bindButtonFeedback(tab.button, Theme.Tab)
    self._tabOrder = (self._tabOrder or 0) + 1
    tab.button.LayoutOrder = self._tabOrder
    tab.button.ZIndex = 3
    tab.indicator = Instance.new("Frame")
    tab.indicator.Name = "ActiveIndicator"
    tab.indicator.Parent = tab.button
    tab.indicator.BackgroundColor3 = Theme.Accent
    tab.indicator.BorderSizePixel = 0
    tab.indicator.Position = UDim2.new(0, ROW_INSET, 1, -2)
    tab.indicator.Size = UDim2.new(1, -2 * ROW_INSET, 0, 2)
    tab.indicator.Visible = false

    tab.content = Instance.new("ScrollingFrame")
    tab.content.Name = name .. "Content"
    tab.content.Parent = self.ContentArea
    tab.content.BackgroundTransparency = 1
    tab.content.BorderSizePixel = 0
    tab.content.Size = UDim2.new(1, 0, 1, 0)
    tab.content.ScrollingDirection = Enum.ScrollingDirection.Y
    tab.content.Selectable = false
    tab.content.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    tab.content.ScrollBarThickness = 4
    tab.content.ScrollBarImageColor3 = Theme.BorderHover
    tab.content.CanvasSize = UDim2.new(0, 0, 0, 0)
    tab.content.Visible = false
    tab.content.ClipsDescendants = true
    tab.content.ZIndex = 1
    tab.button.Destroying:Connect(function()
        tab._buttonDestroying = true
        tab:RemoveTab()
    end)
    tab.content.Destroying:Connect(function()
        tab._contentDestroying = true
        tab:RemoveTab()
    end)

    local layout = Instance.new("UIListLayout")
    layout.Parent = tab.content
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tab.layout = layout

    local padding = Instance.new("UIPadding")
    padding.Parent = tab.content
    padding.PaddingLeft = UDim.new(0, ROW_INSET)
    padding.PaddingRight = UDim.new(0, ROW_INSET)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tab:_RefreshCanvas()
    end)

    bindActivation(self, tab.button, function()
        if self.currentTab == name then tab._resetFeedback() end
        self:SwitchTab(name)
    end)

    table.insert(self.tabs, tab)
    if self.BackgroundEnabled then self:_applyChromeTransparency(true, tab.button) end

    if #self.tabs == 1 then
        self:SwitchTab(name)
    end

    return tab
end

function Tabs:SwitchTab(name)
    if self.Destroyed or self._destroying then return false end
    local nextTab
    for _, tab in ipairs(self.tabs) do
        if tab.name == name then nextTab = tab; break end
    end
    if not nextTab then return false end
    if self.currentTab == name then return true end
    self:_CancelInteractions()
    local focused = self._focusedControl
    if focused and focused.Parent == self.TabContainer and focused ~= nextTab.button then
        self:_SetControlFocus(nil)
    end
    local origin = self._pointerOrigin
    if origin and origin.Parent == self.TabContainer and origin ~= nextTab.button then self._pointerOrigin = nil end
    self.currentTab = name
    for _, tab in ipairs(self.tabs) do
        local active = tab == nextTab
        tab._resetFeedback()
        tab.indicator.Visible = active
        tab.content.Visible = active
        tab.button.TextColor3 = active and Theme.Accent or Theme.TextDim
        tab._setActiveFeedback(active)
    end
    nextTab:_RevealButton()
    return true
end

return Tabs
