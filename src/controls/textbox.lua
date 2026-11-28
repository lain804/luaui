local Element = require("../element")
local dispatchCallback = Element.dispatchCallback
local Style = require("../style")
local Theme = Style.Theme
local INPUT_ROW_HEIGHT = Style.INPUT_ROW_HEIGHT
local createRow = Style.createRow
local createLabel = Style.createLabel
local createInputSurface = Style.createInputSurface

return function(self, args)
    args = args or {}
    local labelText = args.Text or "TextBox"
    local callback = args.Callback
    local flag = args.Flag or args.Save

    local default = args.Default or ""
    default = self:_GetSaved(flag, default)
    default = tostring(default)

    local frame = createRow(self, "Frame", "Textbox", args.Height, INPUT_ROW_HEIGHT)

    local label = createLabel(frame, labelText, args.TextSize)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0.42, -18, 1, 0)

    local boxFrame = createInputSurface(frame, "Frame")
    boxFrame.Name = "TextboxInput"

    local box = Instance.new("TextBox")
    box.Parent = boxFrame
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Position = UDim2.new(0, 6, 0, 0)
    box.Size = UDim2.new(1, -12, 1, 0)
    box.PlaceholderColor3 = Theme.TextDim
    box.Font = Enum.Font.Code
    box.Text = default
    box.PlaceholderText = tostring(args.Placeholder or "")
    box.TextColor3 = Theme.Text
    box.TextSize = args.TextSize or 13
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false

    local hovering = false
    local function renderFocus()
        frame.BackgroundColor3 = (hovering or box:IsFocused()) and Theme.ElementHover or Theme.Element
        boxFrame.BorderColor3 = box:IsFocused() and Theme.Accent or hovering and Theme.BorderHover or Theme.Border
    end
    box.Focused:Connect(renderFocus)

    local skipFocusLost = 0
    local committedText = box.Text
    local function commitText(enterPressed)
        local newText = box.Text or ""
        committedText = newText
        self:_SaveFlag(flag, newText)
        dispatchCallback(self, frame, callback, newText, enterPressed)
    end
    local function releaseEditing()
        hovering = false
        if box.Text ~= committedText then commitText(false) end
        if box:IsFocused() then
            skipFocusLost = skipFocusLost + 1
            box:ReleaseFocus()
        end
        renderFocus()
    end
    box.FocusLost:Connect(function(enterPressed)
        renderFocus()
        if skipFocusLost > 0 then
            skipFocusLost = skipFocusLost - 1
        elseif box.Text ~= committedText or enterPressed then
            commitText(enterPressed)
        end
    end)

    frame.MouseEnter:Connect(function()
        hovering = true
        renderFocus()
    end)

    frame.MouseLeave:Connect(function()
        hovering = false
        renderFocus()
    end)

    local element = Element.new(self, frame, {
        Type = "Textbox",
        Flag = flag,
        OnHide = releaseEditing,
        GetValue = function() return box.Text end,
        SetValue = function(val, noCallback)
            box.Text = val == nil and "" or tostring(val)
            committedText = box.Text
            self:_SaveFlag(flag, box.Text)
            if callback and not noCallback then
                dispatchCallback(self, frame, callback, box.Text, false)
            end
        end
    })
    self:_BindFlag(flag, element)

    if flag and self.library.loadedFlags[flag] ~= nil and args.CallOnLoad ~= false and callback then
        dispatchCallback(self, frame, callback, box.Text, false)
    end

    return element
end
