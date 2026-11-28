local UserInputService = game:GetService("UserInputService")

local Element = require("../element")
local dispatchCallback = Element.dispatchCallback
local Style = require("../style")
local Theme = Style.Theme
local createRow = Style.createRow
local createLabel = Style.createLabel
local createTrack = Style.createTrack
local Input = require("../input")
local isPointerPress = Input.isPointerPress
local isVisible = Input.isVisible
local Util = require("../util")
local finiteNumber = Util.finiteNumber
local normalizeRange = Util.normalizeRange
local disconnectAll = Util.disconnectAll

local Range = {}

function Range:Slider(args)
    args = args or {}
    local text = args.Text or "Slider"
    local min, max = normalizeRange(args.Min, args.Max)
    local default = args.Default
    if default == nil then default = min end
    local callback = args.Callback
    local increment = finiteNumber(args.Increment, 1)
    if increment <= 0 then
        increment = 1
    end
    local flag = args.Flag or args.Save

    local function getDecimalPlaces(number)
        local text = string.format("%.12f", math.abs(number)):gsub("0+$", "")
        local decimals = text:match("%.(%d+)$")
        return decimals and #decimals or 0
    end

    local decimalPlaces = args.Precision
    if decimalPlaces == nil then
        decimalPlaces = math.max(getDecimalPlaces(increment), getDecimalPlaces(min), getDecimalPlaces(max))
    end
    decimalPlaces = math.clamp(math.floor(finiteNumber(decimalPlaces, 0)), 0, 12)

    local roundingScale = 10 ^ decimalPlaces

    local function roundToPrecision(number)
        if decimalPlaces == 0 then
            return number >= 0 and math.floor(number + 0.5) or math.ceil(number - 0.5)
        end

        local scaled = number * roundingScale
        if not finiteNumber(scaled, nil) then return number end
        return (scaled >= 0 and math.floor(scaled + 0.5) or math.ceil(scaled - 0.5)) / roundingScale
    end

    local function snapValue(number)
        if number <= min then return min end
        if number >= max then return max end
        local steps = (number - min) / increment
        if finiteNumber(steps, nil) then number = min + math.floor(steps + 0.5) * increment end
        return math.clamp(roundToPrecision(number), min, max)
    end

    default = self:_GetSaved(flag, default)
    default = finiteNumber(default, min)
    default = snapValue(default)

    local frame = createRow(self, "Frame", "Slider", args.Height, 48)

    local label = createLabel(frame, text, args.TextSize)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.Size = UDim2.new(1, -74, 0, 20)

    local valueLabel = Instance.new("TextBox")
    valueLabel.Parent = frame
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -64, 0, 5)
    valueLabel.Size = UDim2.new(0, 56, 0, 20)
    valueLabel.Font = Enum.Font.Code
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = args.TextSize or 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    valueLabel.Name = "SliderValue"
    valueLabel.BorderSizePixel = 0
    valueLabel.ClearTextOnFocus = false
    valueLabel.PlaceholderText = tostring(default)
    local sliderBg, sliderFill = createTrack(frame, Theme.Accent)

    local sliderHandle = Instance.new("Frame")
    sliderHandle.Parent = sliderBg
    sliderHandle.BackgroundColor3 = Theme.Text
    sliderHandle.BorderSizePixel = 0
    sliderHandle.Size = UDim2.fromOffset(6, 14)

    local detector = Instance.new("TextButton")
    detector.Parent = sliderBg
    detector.BackgroundTransparency = 1
    detector.Position = UDim2.fromOffset(-6, -6)
    detector.Size = UDim2.new(1, 12, 0, 23)
    detector.Text = ""
    detector.AutoButtonColor = false
    detector:SetAttribute("__uiSkipFocus", true)
    detector.Selectable = false

    local value = default
    local dragging = false
    local hovering = false
    local pointer = nil
    local connections = {}
    local function renderGesture()
        frame.BackgroundColor3 = (dragging or hovering) and Theme.ElementHover or Theme.Element
        sliderHandle.BackgroundColor3 = (dragging or hovering) and Theme.Accent or Theme.Text
        frame.BorderColor3 = dragging and Theme.BorderHover or Theme.Border
    end
    local function stopDragging()
        dragging = false
        pointer = nil
        disconnectAll(connections)
        renderGesture()
    end
    detector.MouseEnter:Connect(function() hovering = true; renderGesture() end)
    detector.MouseLeave:Connect(function() hovering = false; renderGesture() end)

    local function render()
        local alpha = (value - min) / (max - min)
        valueLabel.Text = tostring(value)
        sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
        sliderHandle.Position = UDim2.new(alpha, -6 * alpha, 0, -4)
    end

    local function setValue(newValue, noCallback)
        local numberValue = finiteNumber(newValue, min)
        local nextValue = snapValue(numberValue)
        value = nextValue
        render()
        self:_SaveFlag(flag, value)
        if callback and not noCallback then
            dispatchCallback(self, frame, callback, value)
        end
    end

    local skipFocusLost = 0
    local function commitValue()
        local number = finiteNumber(valueLabel.Text, nil)
        if number and snapValue(number) ~= value then setValue(number) else render() end
    end
    local function releaseEditing()
        commitValue()
        if not valueLabel:IsFocused() then return end
        skipFocusLost = skipFocusLost + 1
        valueLabel:ReleaseFocus()
        valueLabel.BackgroundTransparency = 1
    end
    valueLabel.FocusLost:Connect(function()
        if skipFocusLost > 0 then
            skipFocusLost = skipFocusLost - 1
        else
            commitValue()
        end
        valueLabel.BackgroundTransparency = 1
    end)
    valueLabel.Focused:Connect(function()
        valueLabel.BackgroundTransparency = 0
        valueLabel.BackgroundColor3 = Theme.ElementHover
    end)

    local function updateSlider(inputPos)
        if sliderBg.AbsoluteSize.X <= 0 then return end
        local mouseX = inputPos.X
        local relativeX = math.clamp((mouseX - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local rawValue = min + (max - min) * relativeX
        if snapValue(rawValue) ~= value then setValue(rawValue) end
    end

    detector.InputBegan:Connect(function(input)
        if dragging or not isVisible(self.library, detector) then return end
        if not isPointerPress(input) then return end
        dragging = true
        pointer = input
        table.insert(connections, UserInputService.InputChanged:Connect(function(changed)
            if pointer ~= input then return end
            if not isVisible(self.library, detector)
                or changed == input and changed.UserInputState == Enum.UserInputState.Cancel then
                stopDragging()
            elseif changed == input or input.UserInputType == Enum.UserInputType.MouseButton1
                and changed.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(changed.Position)
            end
        end))
        table.insert(connections, UserInputService.InputEnded:Connect(function(ended)
            if ended == pointer then stopDragging() end
        end))
        table.insert(connections, UserInputService.WindowFocusReleased:Connect(stopDragging))
        renderGesture()
        updateSlider(input.Position)
    end)

    render()

    local element = Element.new(self, frame, {
        Type = "Slider",
        Flag = flag,
        OnHide = function()
            hovering = false
            stopDragging()
            releaseEditing()
        end,
        GetValue = function() return value end,
        SetValue = setValue
    })
    self:_BindFlag(flag, element)

    if flag and self.library.loadedFlags[flag] ~= nil and args.CallOnLoad ~= false and callback then
        dispatchCallback(self, frame, callback, value)
    end

    return element
end

function Range:Meter(args)
    args = args or {}
    local text = args.Text or "Meter"
    local min, max = normalizeRange(args.Min, args.Max)
    local default = args.Default
    if default == nil then default = min end
    local format = args.Format or args.ValueFormatter
    local lowColor = args.LowColor or Color3.fromRGB(255, 85, 85)
    local highColor = args.Color or args.HighColor or Theme.Accent

    local frame = createRow(self, "Frame", "Meter", args.Height, 48)

    local label = createLabel(frame, text, args.TextSize)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.Size = UDim2.new(1, -116, 0, 20)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -104, 0, 5)
    valueLabel.Size = UDim2.new(0, 96, 0, 20)
    valueLabel.Font = Enum.Font.Code
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = args.TextSize or 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local _, meterFill = createTrack(frame, highColor)

    local value = math.clamp(finiteNumber(default, min), min, max)

    local function render()
        local alpha = (value - min) / (max - min)
        if format then
            valueLabel.Text = tostring(format(value, alpha))
        else
            valueLabel.Text = tostring(value)
        end
        meterFill.Size = UDim2.new(alpha, 0, 1, 0)
        meterFill.BackgroundColor3 = lowColor:Lerp(highColor, alpha)
    end

    local function setValue(newValue)
        value = math.clamp(finiteNumber(newValue, min), min, max)
        render()
    end

    render()

    local element = Element.new(self, frame, {
        Type = "Meter",
        GetValue = function() return value end,
        SetValue = setValue
    })

    return element
end

return Range
