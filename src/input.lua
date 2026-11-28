local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Style = require("./style")
local Theme = Style.Theme

local FEEDBACK_TWEEN = TweenInfo.new(0.09)

local function isPointerPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function bindButtonFeedback(button, idleColor)
    local hovering, focused, active = false, false, false
    local releaseConnection, transition
    local function render(immediate)
        local pressed = releaseConnection ~= nil
        local background = pressed and Theme.ElementPressed
            or active and Theme.TabActive
            or (hovering or focused) and Theme.ElementHover or idleColor
        local border = (pressed or focused or active) and Theme.Accent
            or hovering and Theme.BorderHover or Theme.Border
        if transition then transition:Cancel(); transition = nil end
        if immediate or GuiService.ReducedMotionEnabled then
            button.BackgroundColor3 = background
            button.BorderColor3 = border
        else
            transition = TweenService:Create(button, FEEDBACK_TWEEN, {
                BackgroundColor3 = background,
                BorderColor3 = border
            })
            transition:Play()
        end
    end
    local function release(immediate)
        if releaseConnection then releaseConnection:Disconnect(); releaseConnection = nil end
        render(immediate)
    end
    local function reset()
        hovering, focused = false, false
        release(true)
    end
    button.MouseEnter:Connect(function() hovering = true; render() end)
    button.MouseLeave:Connect(function() hovering = false; release() end)
    button.SelectionGained:Connect(function() focused = true; render() end)
    button.SelectionLost:Connect(function() focused = false; release() end)
    button.InputBegan:Connect(function(input)
        if releaseConnection or not isPointerPress(input) and input.KeyCode ~= Enum.KeyCode.ButtonA then return end
        releaseConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End
                or input.UserInputState == Enum.UserInputState.Cancel then release() end
        end)
        render()
    end)
    button.Destroying:Connect(function()
        if releaseConnection then releaseConnection:Disconnect() end
        if transition then transition:Cancel() end
    end)
    return reset, function(enabled)
        if active == enabled then return end
        active = enabled
        render()
    end
end

local function isVisible(library, object)
    if library.Destroyed or library._destroying or not library.ScreenGui.Enabled then return false end
    while object and object ~= library.ScreenGui do
        if object:IsA("GuiObject") and not object.Visible then return false end
        object = object.Parent
    end
    return object == library.ScreenGui
end

local function bindActivation(library, button, callback)
    library._activationHandlers = library._activationHandlers or {}
    local function activate(...)
        if isVisible(library, button) then callback(...) end
    end
    library._activationHandlers[button] = activate
    button.Destroying:Connect(function() library._activationHandlers[button] = nil end)
    return button.Activated:Connect(function(input, ...)
        if input and isPointerPress(input) and isVisible(library, button) and button.Selectable then
            GuiService.SelectedObject = button
        end
        activate(input, ...)
    end)
end

local function focusDirection()
    return (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift))
        and -1 or 1
end

local function revealSelection(frame, object, axis)
    local start = object.AbsolutePosition[axis] - frame.AbsolutePosition[axis]
    local length = object.AbsoluteSize[axis]
    local viewport = frame.AbsoluteWindowSize[axis]
    local canvas = frame.CanvasPosition
    local offset = canvas[axis]
    if start < 0 or length >= viewport then
        offset = math.max(offset + start, 0)
    elseif start + length > viewport then
        offset = offset + start + length - viewport
    else
        return
    end
    frame.CanvasPosition = axis == "X" and Vector2.new(offset, canvas.Y) or Vector2.new(canvas.X, offset)
end

local function stepFocus(targets, direction, focused, controlCanvas)
    if #targets == 0 then return end
    local index = table.find(targets, focused or GuiService.SelectedObject) or (direction > 0 and 0 or 1)
    local target = targets[(index - 1 + direction) % #targets + 1]
    if focused and focused ~= target then focused:ReleaseFocus() end
    if controlCanvas then revealSelection(controlCanvas, target, "Y") end
    GuiService.SelectedObject = target
    if not controlCanvas and target ~= focused and target:IsA("TextBox") then target:CaptureFocus() end
    return target
end

return {
    isPointerPress = isPointerPress,
    bindButtonFeedback = bindButtonFeedback,
    isVisible = isVisible,
    bindActivation = bindActivation,
    focusDirection = focusDirection,
    revealSelection = revealSelection,
    stepFocus = stepFocus,
}
