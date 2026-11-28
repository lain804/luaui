local UserInputService = game:GetService("UserInputService")

local Style = require("./style")
local Theme = Style.Theme
local createLabel = Style.createLabel
local Input = require("./input")
local isVisible = Input.isVisible
local revealSelection = Input.revealSelection
local stepFocus = Input.stepFocus

local Focus = {}

local navigationWindow

local function renderControlFocus(library, object)
    local outline = object:FindFirstChild("FocusOutline")
    if outline then
        outline.Enabled = library._focusedControl == object or object:IsA("TextBox") and object:IsFocused()
    end
end

function Focus:_SetControlFocus(object)
    if object then
        self:_ClaimNavigation()
        self._pointerOrigin = nil
    end
    local previous = self._focusedControl
    if previous == object then return end
    self._focusedControl = object
    if previous then renderControlFocus(self, previous) end
    if object then renderControlFocus(self, object) end
end

function Focus:_ClaimNavigation()
    if navigationWindow == self then return end
    if navigationWindow then navigationWindow:_ClearNavigation() end
    navigationWindow = self
end

function Focus:_ClearNavigation()
    if navigationWindow == self then navigationWindow = nil end
    self._pointerOrigin = nil
    self:_SetControlFocus(nil)
end

function Focus:_SetPointerOrigin(object)
    self:_ClaimNavigation()
    self:_SetControlFocus(nil)
    self._pointerOrigin = object
end

function Focus:_FocusStep(direction, focused, controlsOnly)
    local targets = {}
    if not controlsOnly then
        for _, tab in ipairs(self.tabs) do
            if isVisible(self, tab.button) then
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
                        if (object:IsA("GuiButton") or object:IsA("TextBox")) and not object:GetAttribute("__uiSkipFocus")
                            and isVisible(self, object) then
                            table.insert(targets, object)
                        end
                    end
                end
            end
            break
        end
    end
    local target = stepFocus(self, targets, direction, focused, controlCanvas)
    for _, tab in ipairs(self.tabs) do
        if tab.button == target then tab:_RevealButton(); break end
    end
    return target
end

function Focus:_StepTab(direction)
    for index, tab in ipairs(self.tabs) do
        if tab.name == self.currentTab then
            local nextTab = self.tabs[(index - 1 + direction) % #self.tabs + 1]
            if self:SwitchTab(nextTab.name) then
                revealSelection(self.TabContainer, nextTab.button, "X")
                self:_SetControlFocus(nextTab.button)
                return true
            end
        end
    end
end

function Focus:_HandleInput(input, gameProcessed, visibilityKey)
    if self.Destroyed or not self.ScreenGui.Enabled then return end
    local pointer = Input.isPointerPress(input)
    if pointer then
        if navigationWindow == self then
            if self.MainFrame.Visible and Input.containsPoint(self.MainFrame, input.Position) then
                self:_SetControlFocus(nil)
                self._pointerOrigin = nil
            else
                self:_ClearNavigation()
            end
        end
    end
    if self._dropdownInput then
        self._dropdownInput(input, gameProcessed)
        return true
    end
    if pointer or self._cancelKeybind then return end

    local focused = UserInputService:GetFocusedTextBox()
    if focused and not focused:IsDescendantOf(self.MainFrame) then return end
    if gameProcessed and not focused then return end

    local key = input.KeyCode
    local ownsNavigation = navigationWindow == self
    if self.MainFrame.Visible then
        if key == Enum.KeyCode.Tab and (focused or ownsNavigation) then
            return self:_FocusStep(Input.focusDirection(), focused)
        end
        if key == Enum.KeyCode.ButtonSelect and not focused and (ownsNavigation or not navigationWindow) then
            if ownsNavigation then
                self:_ClearNavigation()
                return true
            end
            return self:_StepTab(0)
        end
        if (key == Enum.KeyCode.Escape or key == Enum.KeyCode.ButtonB) and (focused or ownsNavigation) then
            self:_ClearNavigation()
            if focused then focused:ReleaseFocus() end
            return true
        end
        if ownsNavigation and not focused then
            if key == Enum.KeyCode.Left or key == Enum.KeyCode.Right
                or key == Enum.KeyCode.DPadLeft or key == Enum.KeyCode.DPadRight then
                local previous = key == Enum.KeyCode.Left or key == Enum.KeyCode.DPadLeft
                return self:_StepTab(previous and -1 or 1)
            elseif key == Enum.KeyCode.Up or key == Enum.KeyCode.Down
                or key == Enum.KeyCode.DPadUp or key == Enum.KeyCode.DPadDown then
                local previous = key == Enum.KeyCode.Up or key == Enum.KeyCode.DPadUp
                return self:_FocusStep(previous and -1 or 1, nil, true)
            end
            local selected = self._focusedControl or self._pointerOrigin
            local enter = key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter or key == Enum.KeyCode.ButtonA
            if selected and isVisible(self, selected) and (enter or key == Enum.KeyCode.Space) then
                local activate = self._activationHandlers and self._activationHandlers[selected]
                if activate then
                    activate()
                    return true
                end
                if enter and selected:IsA("TextBox") then
                    selected:CaptureFocus()
                    return true
                end
            end
        end
    end
    if not focused and key == visibilityKey then self.MainFrame.Visible = not self.MainFrame.Visible end
end

function Focus:_HideTooltip()
    self._tooltipGeneration = (self._tooltipGeneration or 0) + 1
    if self.Tooltip then self.Tooltip.Visible = false end
    self._tooltipOwner = nil
end

function Focus:_ReleaseElementFocus(element)
    local instance = element.Instance
    local selected = self._focusedControl
    if selected and (selected == instance or selected:IsDescendantOf(instance)) then
        self:_SetControlFocus(nil)
    end
    local origin = self._pointerOrigin
    if origin and (origin == instance or origin:IsDescendantOf(instance)) then self._pointerOrigin = nil end
    local focused = UserInputService:GetFocusedTextBox()
    if focused and (focused == instance or focused:IsDescendantOf(instance)) then focused:ReleaseFocus() end
    self:_HideTooltip()
end

function Focus:_DecorateObject(object)
    -- Roblox routes movement keys to native selection. Keep UI focus local.
    if object:IsA("GuiObject") then object.Selectable = false end
    local isTextBox = object:IsA("TextBox")
    if not object:GetAttribute("__uiSkipFocus") and (object:IsA("GuiButton") or isTextBox) then
        local outline = Instance.new("UIStroke")
        outline.Name = "FocusOutline"
        outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        outline.Color = Theme.Accent
        outline.Thickness = 1
        outline.Enabled = false
        outline.Parent = object
        object.Destroying:Connect(function()
            if self._focusedControl == object then self:_SetControlFocus(nil) end
            if self._pointerOrigin == object then self._pointerOrigin = nil end
        end)
        if isTextBox then
            object.Focused:Connect(function()
                if isVisible(self, object) then self:_ClaimNavigation() end
                renderControlFocus(self, object)
            end)
            object.FocusLost:Connect(function(submitted)
                if submitted and not self._closeDropdown and isVisible(self, object) then
                    self:_SetControlFocus(object)
                end
                renderControlFocus(self, object)
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
