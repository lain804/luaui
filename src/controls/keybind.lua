local UserInputService = game:GetService("UserInputService")

local Element = require("../element")
local dispatchCallback = Element.dispatchCallback
local Style = require("../style")
local Theme = Style.Theme
local INPUT_ROW_HEIGHT = Style.INPUT_ROW_HEIGHT
local createRow = Style.createRow
local createLabel = Style.createLabel
local createInputSurface = Style.createInputSurface
local Input = require("../input")
local bindButtonFeedback = Input.bindButtonFeedback
local bindActivation = Input.bindActivation

return function(self, args)
    args = args or {}
    local text = args.Text or "Keybind"
    local callback = args.Callback
    local changed = args.Changed or args.OnChanged
    local flag = args.Flag or args.Save
    local ignoreTextBox = args.IgnoreTextBox ~= false

    local function normalizeKeyCode(value)
        if value == "None" then return Enum.KeyCode.Unknown end
        if type(value) == "string" then
            local name = value:match("^Enum%.KeyCode%.(.+)$") or value
            local ok, keyCode = pcall(function()
                return Enum.KeyCode[name]
            end)
            value = ok and keyCode or nil
        end
        if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
            return value
        end

        return nil
    end

    local default = normalizeKeyCode(args.Default or args.KeyCode) or Enum.KeyCode.Unknown
    local saved, hadSaved = self:_GetSaved(flag, nil)
    if hadSaved then
        default = normalizeKeyCode(saved) or default
    end

    local frame = createRow(self, "Frame", "Keybind", args.Height, INPUT_ROW_HEIGHT)

    local label = createLabel(frame, text, args.TextSize)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0.42, -18, 1, 0)

    local button = createInputSurface(frame, "TextButton")
    button.Font = Enum.Font.Code
    button.Text = ""
    button.TextColor3 = Theme.Text
    button.TextSize = args.TextSize or 13
    button.TextXAlignment = Enum.TextXAlignment.Center
    button.AutoButtonColor = false
    local resetFeedback, setActiveFeedback = bindButtonFeedback(button, Theme.Background)

    local keyCode = default
    local listening = false

    local function keyName(value)
        return value and value ~= Enum.KeyCode.Unknown and value.Name or "None"
    end

    local function render()
        button.Text = listening and "Press a key..." or keyName(keyCode)
        button.TextColor3 = listening and Theme.Accent or keyCode == Enum.KeyCode.Unknown and Theme.TextDim or Theme.Text
        setActiveFeedback(listening)
    end

    local function saveKey()
        self:_SaveFlag(flag, keyCode.Name)
    end

    local function cancelListening()
        listening = false
        if self.library._cancelKeybind == cancelListening then
            self.library._cancelKeybind = nil
        end
        render()
    end

    local function setKey(newKeyCode, noCallback)
        keyCode = normalizeKeyCode(newKeyCode) or Enum.KeyCode.Unknown
        cancelListening()
        saveKey()
        if changed and not noCallback then
            dispatchCallback(self, frame, changed, keyCode)
        end
    end

    local function shouldIgnoreForTextBox()
        return ignoreTextBox and UserInputService:GetFocusedTextBox() ~= nil
    end

    bindActivation(self.library, button, function()
        if listening then cancelListening(); return end
        if self.library._closeDropdown then self.library._closeDropdown() end
        if self.library._cancelKeybind then self.library._cancelKeybind() end
        self.library._cancelKeybind = cancelListening
        listening = true
        render()
    end)

    local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if self.Destroyed or self.library.Destroyed or not self.library.ScreenGui.Enabled or not frame.Parent then return end
        if self.library._closeDropdown then return end
        if self.library._capturedInput == input then return end
        if self.library._cancelKeybind and not listening then return end
        if gameProcessed and not listening then return end
        local gamepad = tostring(input.UserInputType):match("^Enum%.UserInputType%.Gamepad") ~= nil
        if input.UserInputType ~= Enum.UserInputType.Keyboard and not gamepad then return end
        if input.KeyCode == Enum.KeyCode.Unknown then return end

        if listening then
            self.library._capturedInput = input
            if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
                cancelListening()
                return
            end
            if input.KeyCode == Enum.KeyCode.Backspace then
                setKey(Enum.KeyCode.Unknown)
                return
            end
            setKey(input.KeyCode)
            return
        end

        if shouldIgnoreForTextBox() then return end
        if keyCode and keyCode ~= Enum.KeyCode.Unknown and input.KeyCode == keyCode and callback then
            dispatchCallback(self, frame, callback, input)
        end
    end)

    render()

    local element = Element.new(self, frame, {
        Type = "Keybind",
        Flag = flag,
        GetValue = function()
            return keyCode
        end,
        SetValue = setKey,
        OnHide = function()
            cancelListening()
            resetFeedback()
        end,
        Cleanup = function()
            inputConnection:Disconnect()
        end
    })
    self:_BindFlag(flag, element)

    if flag and self.library.loadedFlags[flag] ~= nil and args.CallOnLoad ~= false and changed then
        dispatchCallback(self, frame, changed, keyCode)
    end

    return element
end
