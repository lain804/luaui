local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Style = require("./style")
local Theme = Style.Theme
local createLabel = Style.createLabel
local Input = require("./input")
local isVisible = Input.isVisible
local revealSelection = Input.revealSelection
local stepFocus = Input.stepFocus

local Focus = {}

function Focus:_FocusStep(direction, focused, controlsOnly)
    local targets = {}
    if not controlsOnly then
        for _, tab in ipairs(self.tabs) do
            if tab.button.Selectable and isVisible(self, tab.button) then
                table.insert(targets, tab.button)
            end
        end
    end
    local controlCanvas
    for _, tab in ipairs(self.tabs) do
        if tab.name == self.currentTab then
            if controlsOnly then controlCanvas = tab.content end
            for _, element in ipairs(tab.elements) do
                if not element.Hidden then
                    local objects = element.Instance:GetDescendants()
                    table.insert(objects, 1, element.Instance)
                    for _, object in ipairs(objects) do
                        if (object:IsA("GuiButton") or object:IsA("TextBox")) and object.Selectable ~= false
                            and isVisible(self, object) then
                            table.insert(targets, object)
                        end
                    end
                end
            end
            break
        end
    end
    return stepFocus(targets, direction, focused, controlCanvas)
end

function Focus:_StepTab(direction)
    for index, tab in ipairs(self.tabs) do
        if tab.name == self.currentTab then
            local nextTab = self.tabs[(index - 1 + direction) % #self.tabs + 1]
            if self:SwitchTab(nextTab.name) then
                revealSelection(self.TabContainer, nextTab.button, "X")
                GuiService.SelectedObject = nextTab.button
                return true
            end
        end
    end
end

function Focus:_HideTooltip()
    self._tooltipGeneration = (self._tooltipGeneration or 0) + 1
    if self.Tooltip then self.Tooltip.Visible = false end
    self._tooltipOwner = nil
end

function Focus:_ReleaseElementFocus(element)
    local selected = GuiService.SelectedObject
    if selected and (selected == element.Instance or selected:IsDescendantOf(element.Instance)) then
        GuiService.SelectedObject = nil
    end
    local focused = UserInputService:GetFocusedTextBox()
    if focused and focused:IsDescendantOf(element.Instance) then focused:ReleaseFocus() end
    self:_HideTooltip()
end

function Focus:_DecorateObject(object)
    local isTextBox = object:IsA("TextBox")
    if not object:GetAttribute("__uiSkipFocus") and (object:IsA("GuiButton") or isTextBox) then
        object.Selectable = true
        local outline = Instance.new("UIStroke")
        outline.Name = "FocusOutline"
        outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        outline.Color = Theme.Accent
        outline.Thickness = 1
        outline.Enabled = false
        outline.Parent = object
        local function renderFocus()
            outline.Enabled = GuiService.SelectedObject == object or isTextBox and object:IsFocused()
        end
        object.SelectionGained:Connect(renderFocus)
        object.SelectionLost:Connect(renderFocus)
        if isTextBox then
            object.Focused:Connect(function()
                if isVisible(self, object) then GuiService.SelectedObject = object end
                renderFocus()
            end)
            object.FocusLost:Connect(function(submitted)
                if submitted and not self._closeDropdown and not GuiService.SelectedObject and isVisible(self, object) then
                    GuiService.SelectedObject = object
                end
                renderFocus()
            end)
        end
    end
    if not (object:IsA("TextLabel") or object:IsA("TextButton")) then return end
    local pending
    local function hide()
        if pending then task.cancel(pending); pending = nil end
        if self._tooltipOwner == object then
            self._tooltipOwner = nil
            if self.Tooltip then self.Tooltip.Visible = false end
        end
    end
    object.MouseEnter:Connect(function()
        hide()
        local generation = self._tooltipGeneration or 0
        pending = task.delay(0.45, function()
            pending = nil
            if generation ~= (self._tooltipGeneration or 0) or not isVisible(self, object) then return end
            if not object.TextFits then
                if not self.Tooltip then
                    self.Tooltip = createLabel(self.MainFrame, "", 12)
                    self.Tooltip.BackgroundTransparency = 0
                    self.Tooltip.BackgroundColor3 = Theme.TabActive
                    self.Tooltip.BorderColor3 = Theme.BorderHover
                    self.Tooltip.BorderSizePixel = 1
                    self.Tooltip.TextWrapped = true
                    self.Tooltip.ZIndex = 80
                    local padding = Instance.new("UIPadding")
                    padding.PaddingLeft = UDim.new(0, 8)
                    padding.PaddingRight = UDim.new(0, 8)
                    padding.Parent = self.Tooltip
                end
                local width = math.max(1, self.MainFrame.AbsoluteSize.X - 24)
                self.Tooltip.Text = object.Text
                self.Tooltip.Size = UDim2.new(0, width, 0, 54)
                local y = object.AbsolutePosition.Y - self.MainFrame.AbsolutePosition.Y + object.AbsoluteSize.Y + 4
                self.Tooltip.Position = UDim2.new(0, 12, 0, math.clamp(y, 4, math.max(4, self.MainFrame.AbsoluteSize.Y - 58)))
                self.Tooltip.Visible = true
                self._tooltipOwner = object
            end
        end)
    end)
    object.MouseLeave:Connect(hide)
    object.Destroying:Connect(hide)
end

function Focus:_CancelInteractions()
    for _, tab in ipairs(self.tabs or {}) do
        if tab.name == self.currentTab then
            for _, element in ipairs(tab.elements) do
                if element._onHide then element._onHide() end
                self:_ReleaseElementFocus(element)
            end
            break
        end
    end
    self:_HideTooltip()
end

return Focus
