local Element = require("../element")
local dispatchCallback = Element.dispatchCallback
local Style = require("../style")
local Theme = Style.Theme
local createRow = Style.createRow
local createLabel = Style.createLabel
local Input = require("../input")
local bindActivation = Input.bindActivation
local bindButtonFeedback = Input.bindButtonFeedback

local Basic = {}

function Basic:Button(args)
    args = args or {}
    local text = args.Text or "Button"
    local callback = args.Callback

    local button = createRow(self, "TextButton", "Button", args.Height, 30)
    button.Font = Enum.Font.Code
    button.Text = text
    button.TextColor3 = Theme.Text
    button.TextSize = args.TextSize or 13
    button.AutoButtonColor = false

    local resetFeedback = bindButtonFeedback(button, Theme.Element)
    bindActivation(self.library, button, function()
        dispatchCallback(self, button, callback)
    end)

    local element = Element.new(self, button, {
        Type = "Button",
        OnHide = resetFeedback,
        GetValue = function()
            return button.Text
        end,
        SetValue = function(newText)
            button.Text = tostring(newText or text)
        end
    })

    return element
end

function Basic:Toggle(args)
    args = args or {}
    local text = args.Text or "Toggle"
    local callback = args.Callback
    local flag = args.Flag or args.Save

    local default = args.Default
    if default == nil then default = false end
    default = not not self:_GetSaved(flag, default)

    local frame = createRow(self, "TextButton", "Toggle", args.Height, 30)
    frame.Text = ""
    frame.AutoButtonColor = false

    local label = createLabel(frame, text, args.TextSize)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(1, -56, 1, 0)

    local toggle = Instance.new("Frame")
    toggle.Parent = frame
    toggle.BackgroundColor3 = Theme.Track
    toggle.BorderColor3 = Theme.Border
    toggle.BorderSizePixel = 1
    toggle.Position = UDim2.new(1, -10, 0.5, 0)
    toggle.Size = UDim2.new(0, 28, 0, 14)
    toggle.AnchorPoint = Vector2.new(1, 0.5)

    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.Parent = toggle
    thumb.BorderSizePixel = 0
    thumb.Size = UDim2.fromOffset(8, 8)

    local state = default
    local function render()
        thumb.Position = UDim2.fromOffset(state and 17 or 3, 3)
        thumb.BackgroundColor3 = state and Theme.Accent or Theme.TextDim
        toggle.BorderColor3 = state and Theme.TextDim or Theme.BorderHover
    end
    render()

    local function setState(newState, noCallback)
        state = not not newState
        render()
        self:_SaveFlag(flag, state)
        if callback and not noCallback then
            dispatchCallback(self, frame, callback, state)
        end
    end

    local resetFeedback = bindButtonFeedback(frame, Theme.Element)

    bindActivation(self.library, frame, function()
        setState(not state)
    end)

    local element = Element.new(self, frame, {
        Type = "Toggle",
        Flag = flag,
        OnHide = resetFeedback,
        GetValue = function() return state end,
        SetValue = setState
    })
    self:_BindFlag(flag, element)

    if flag and self.library.loadedFlags[flag] ~= nil and args.CallOnLoad ~= false and callback then
        dispatchCallback(self, frame, callback, state)
    end

    return element
end

function Basic:Label(args)
    args = args or {}
    assert(not self.Destroyed and not self.library.Destroyed and not self.library._destroying, "Cannot add controls to a destroyed UI")
    local text = args.Text or ""
    local height = args.Height or 20

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Parent = self.content
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, height)
    label.AnchorPoint = Vector2.new(0.5, 0)
    label.Position = UDim2.new(0.5, 0, 0, 0)
    label.Font = Enum.Font.Code
    label.Text = text
    label.TextColor3 = Theme.TextDim
    label.TextSize = args.TextSize or 12
    label.TextXAlignment = args.TextXAlignment or Enum.TextXAlignment.Left

    local element = Element.new(self, label, {
        Type = "Label",
        SetValue = function(newText)
            label.Text = tostring(newText or "")
        end,
        GetValue = function()
            return label.Text
        end
    })

    return element
end

function Basic:Separator(args)
    args = args or {}
    assert(not self.Destroyed and not self.library.Destroyed and not self.library._destroying, "Cannot add controls to a destroyed UI")
    local container = Instance.new("Frame")
    container.Name = "SeparatorContainer"
    container.Parent = self.content
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 0, args.Height or 20)
    container.AnchorPoint = Vector2.new(0.5, 0)
    container.Position = UDim2.new(0.5, 0, 0, 0)

    local separator = Instance.new("Frame")
    separator.Name = "Separator"
    separator.Parent = container
    separator.BackgroundColor3 = Theme.Border
    separator.BorderSizePixel = 0
    separator.Position = UDim2.new(0, 0, 0.5, 0)
    separator.Size = UDim2.new(1, 0, 0, 1)
    separator.AnchorPoint = Vector2.new(0, 0.5)

    local element = Element.new(self, container, {
        Type = "Separator"
    })

    return element
end

return Basic
