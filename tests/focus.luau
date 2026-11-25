local Color3 = {fromRGB = function() return {} end}
local Vector2 = {new = function(x, y) return {X = x, Y = y} end}
local TweenInfo = {new = function() return {} end}
local gui = {ReducedMotionEnabled = true}
local function signal()
    local listeners = {}
    return {
        Connect = function(_, listener)
            listeners[listener] = true
            return {Disconnect = function() listeners[listener] = nil end}
        end,
        Fire = function(_, ...)
            for listener in pairs(table.clone(listeners)) do listener(...) end
        end,
    }
end
local input = {
    InputBegan = signal(), InputChanged = signal(), InputEnded = signal(), WindowFocusReleased = signal(),
    GetPropertyChangedSignal = signal,
}
function input:GetFocusedTextBox() return self.focused end
function input:IsKeyDown(key) return key == "LeftControl" or key == self.modifier end
local game = {GetService = function(_, service) return service == "UserInputService" and input or gui end}
local Enum = setmetatable({}, {
    __index = function()
        return setmetatable({}, {__index = function(_, member) return member end})
    end,
})
local UDim = {new = function(scale, offset) return {Scale = scale, Offset = offset} end}
local UDim2 = {
    new = function(xs, xo, ys, yo) return {X = UDim.new(xs, xo), Y = UDim.new(ys, yo)} end,
    fromOffset = function(x, y) return {X = UDim.new(0, x), Y = UDim.new(0, y)} end,
}
local deferred = {}
local task = {defer = function(callback) table.insert(deferred, callback) end}
local shared = {}
local instances = {}
local Instance = {}

local function loadLibrary()
    -- INSERT LIBRARY HERE
end

local function target(className, parent)
    local object = {Parent = parent, Visible = true, Selectable = true}
    function object:IsA(class)
        return class == className or class == "GuiObject" and className ~= "ScreenGui"
            or class == "GuiButton" and className == "TextButton"
    end
    function object:GetDescendants()
        if self.Descendants then return self.Descendants end
        local descendants = {}
        for _, instance in ipairs(instances) do
            if instance:IsDescendantOf(self) then table.insert(descendants, instance) end
        end
        return descendants
    end
    function object:IsDescendantOf(ancestor)
        local current = self.Parent
        while current do
            if current == ancestor then return true end
            current = current.Parent
        end
        return false
    end
    return object
end

function Instance.new(className)
    local object = setmetatable(target(className), {
        __index = function(self, key)
            for _, child in ipairs(instances) do
                if rawget(child, "Parent") == self and child.Name == key then return child end
            end
        end,
    })
    local attributes, signals = {}, {}
    object.Name = className
    if className == "ScreenGui" then object.Enabled = true end
    object.AbsolutePosition = Vector2.new(0, 0)
    object.AbsoluteSize = Vector2.new(600, 400)
    object.AbsoluteWindowSize = object.AbsoluteSize
    object.AbsoluteContentSize = Vector2.new(0, 0)
    object.CanvasPosition = Vector2.new(0, 0)
    function object:SetAttribute(name, value) attributes[name] = value end
    function object:GetAttribute(name) return attributes[name] end
    function object:GetPropertyChangedSignal(name)
        if not signals[name] then signals[name] = signal() end
        return signals[name]
    end
    function object:IsFocused() return input.focused == self end
    function object:CaptureFocus()
        input.focused = self
        self.Focused:Fire()
    end
    function object:ReleaseFocus(submitted)
        input.focused = nil
        gui.SelectedObject = nil
        self.FocusLost:Fire(submitted == true)
    end
    for _, name in ipairs({"Activated", "MouseEnter", "MouseLeave", "InputBegan", "SelectionGained",
        "SelectionLost", "Focused", "FocusLost", "Destroying"}) do
        object[name] = signal()
    end
    table.insert(instances, object)
    return object
end

local function child(parent, name)
    for _, object in ipairs(instances) do
        if object.Parent == parent and object.Name == name then return object end
    end
    error("Missing " .. name)
end

local UI = loadLibrary()
local screen = target("ScreenGui")
screen.Enabled = true
local mainTab = target("GuiButton", screen)
local otherTab = target("GuiButton", screen)
local textbox = target("TextBox", screen)
local button = target("GuiButton", screen)
local hidden = target("GuiButton", screen)
hidden.Visible = false
function textbox:CaptureFocus() self.Focused = true end
function textbox:ReleaseFocus()
    self.Focused = false
    gui.SelectedObject = nil
end

local lib = setmetatable({
    ScreenGui = screen,
    currentTab = "Main",
    tabs = {
        {name = "Main", button = mainTab, elements = {{Instance = textbox}, {Instance = hidden}, {Instance = button}}},
        {name = "Other", button = otherTab, elements = {}},
    },
}, UI)

lib:_FocusStep(1)
assert(gui.SelectedObject == mainTab)
lib:_FocusStep(1)
assert(gui.SelectedObject == otherTab)
lib:_FocusStep(1)
assert(gui.SelectedObject == textbox and textbox.Focused)

-- Roblox can clear selection on blur. Keep the textbox as the traversal origin.
gui.SelectedObject = nil
lib:_FocusStep(1, textbox)
assert(gui.SelectedObject == button and not textbox.Focused)
lib:_FocusStep(-1)
assert(gui.SelectedObject == textbox and textbox.Focused)
lib:_FocusStep(-1, textbox)
assert(gui.SelectedObject == otherTab and not textbox.Focused)

lib.MainFrame = Instance.new("Frame")
lib.MainFrame.Parent = screen
lib.TabContainer = Instance.new("ScrollingFrame")
lib.TabContainer.Parent = lib.MainFrame
lib.ContentArea = Instance.new("Frame")
lib.ContentArea.Parent = lib.MainFrame
lib.TabScrollBarThickness = 4
lib.tabs, lib.currentTab = {}, nil
lib._DecorateObject = function() end
local tab = lib:CreateTab({Name = "Search"})
local element = tab:Dropdown({Options = {"Alpha", "Beta", "Alphabet"}, Multi = true})
local trigger = child(element.Instance, "TextButton")
trigger.AbsolutePosition = Vector2.new(310, 330)
trigger.AbsoluteSize = Vector2.new(240, 30)
local overlay = child(lib.MainFrame, "DropdownOverlay")
local popup = child(overlay, "DropdownList")
local search = child(popup, "Search")
local options = child(popup, "ScrollingFrame")
local alpha = child(options, "Option1")
local beta = child(options, "Option2")
local alphabet = child(options, "Option3")

input.InputBegan:Fire({KeyCode = "A"})
assert(#element:GetValue() == 0)
trigger.Activated:Fire()
assert(popup.Visible and search.Position.Y.Offset < options.Position.Y.Offset)

gui.SelectedObject = mainTab
input.InputBegan:Fire({KeyCode = "A"})
assert(#element:GetValue() == 0, "Ctrl+A selected options while keyboard focus was outside the dropdown")
input.InputBegan:Fire({KeyCode = "Tab"})
assert(gui.SelectedObject == mainTab, "An unfocused dropdown took keyboard focus")

local popupY, popupHeight = popup.Position.Y.Offset, popup.Size.Y.Offset
assert(popupY < trigger.AbsolutePosition.Y)
input.focused = search
search.Focused:Fire()
search.Text = "aLPHa"
search:GetPropertyChangedSignal("Text"):Fire()
assert(alpha.Visible and alphabet.Visible and not beta.Visible)
assert(popup.Position.Y.Offset == popupY and popup.Size.Y.Offset == popupHeight)
input.InputBegan:Fire({KeyCode = "A"})
assert(#element:GetValue() == 0, "Ctrl+A selected options while editing a search")

input.InputBegan:Fire({KeyCode = "Escape"}, true)
assert(popup.Visible and not search:IsFocused() and gui.SelectedObject == alpha)
assert(search.Text == "aLPHa" and #element:GetValue() == 0)
input.InputBegan:Fire({KeyCode = "A"})
assert(#element:GetValue() == 3, "Ctrl+A should work after Escape leaves Search")
element:SetValue({}, true)

input.focused = search
search.Focused:Fire()
search.Text = "no match"
search:GetPropertyChangedSignal("Text"):Fire()
assert(not alpha.Visible and not alphabet.Visible and not beta.Visible)
assert(popup.Position.Y.Offset == popupY and popup.Size.Y.Offset == popupHeight)
input.InputBegan:Fire({KeyCode = "Escape"}, true)
assert(popup.Visible and not search:IsFocused() and gui.SelectedObject == search)
search.Text = ""
search:GetPropertyChangedSignal("Text"):Fire()
assert(alpha.Visible and alphabet.Visible and beta.Visible)

gui.SelectedObject = alpha
input.focused = textbox
input.InputBegan:Fire({KeyCode = "A"})
assert(#element:GetValue() == 0, "Ctrl+A selected options while editing another textbox")
input.focused = nil
input.InputBegan:Fire({KeyCode = "A"}, true)
assert(#element:GetValue() == 0, "Ctrl+A selected options after Roblox consumed the input")
screen.Enabled = false
input.InputBegan:Fire({KeyCode = "A"})
assert(#element:GetValue() == 0, "Ctrl+A selected options while the GUI was disabled")
screen.Enabled = true
input.InputBegan:Fire({KeyCode = "A"})
assert(#element:GetValue() == 3)
input.modifier = "LeftShift"
input.InputBegan:Fire({KeyCode = "A"})
assert(#element:GetValue() == 0)
input.modifier = nil
input.InputBegan:Fire({KeyCode = "Escape"})
input.InputBegan:Fire({KeyCode = "A"})
assert(not popup.Visible and #element:GetValue() == 0)

local scalar = tab:Dropdown({Options = {false, 0, "zero", false}, Default = false})
assert(scalar:GetValue() == false and #scalar:GetOptions() == 3)
scalar:SetValue(0)
assert(scalar:GetValue() == 0)
assert(not pcall(scalar.SetOptions, scalar, {"new", {}}))
assert(scalar:GetValue() == 0 and table.concat({scalar:GetOptions()[2], scalar:GetOptions()[3]}, ",") == "0,zero")
assert(not pcall(tab.Dropdown, tab, {Options = {math.huge}}))
assert(not pcall(tab.Dropdown, tab, {Options = false}))

local parent = Instance.new("Frame")
local first = UI.new({Parent = parent, AutoLoad = false, AutoSave = false})
local second = UI.new({Parent = parent, AutoLoad = false, AutoSave = false})
local firstTab = first:CreateTab({Name = "First"})
local secondTab = second:CreateTab({Name = "Second"})
local firstButton = firstTab:Button().Instance
local secondButton = secondTab:Button().Instance
gui.SelectedObject = firstTab.button
input.InputBegan:Fire({KeyCode = "Tab"})
assert(gui.SelectedObject == firstButton)
gui.SelectedObject = secondTab.button
input.InputBegan:Fire({KeyCode = "Tab"})
assert(gui.SelectedObject == secondButton)
gui.SelectedObject = mainTab
input.InputBegan:Fire({KeyCode = "Tab"})
assert(gui.SelectedObject == mainTab)
gui.SelectedObject = nil
input.InputBegan:Fire({KeyCode = "Tab"})
assert(gui.SelectedObject == firstTab.button or gui.SelectedObject == secondTab.button)

local function press(key, processed)
    local event = {KeyCode = key, UserInputType = "Keyboard"}
    input.InputBegan:Fire(event, processed)
    input.InputEnded:Fire(event)
end
local controls = first:CreateTab({Name = "Controls"})
local submitCount, buttonClicks = 0, 0
local buttonControl = controls:Button({Callback = function() buttonClicks += 1 end}).Instance
local hiddenControl = controls:Toggle()
hiddenControl:Hide()
local toggle = controls:Toggle()
local field = controls:Textbox({Callback = function(_, submitted)
    if submitted then submitCount += 1 end
end}).Instance
local entry = child(child(field, "TextboxInput"), "TextBox")
entry.AbsolutePosition = Vector2.new(12, 420)
entry.AbsoluteSize = Vector2.new(100, 28)
local choice = controls:Dropdown({Options = {"One", "Two"}, Default = "One"})
local choiceTrigger = child(choice.Instance, "TextButton")
choiceTrigger.AbsolutePosition = Vector2.new(310, 330)
choiceTrigger.AbsoluteSize = Vector2.new(240, 30)
local choicePopup = child(child(first.MainFrame, "DropdownOverlay"), "DropdownList")

gui.SelectedObject = nil
press("Right")
assert(first.currentTab == "First" and gui.SelectedObject == nil)
local click = {UserInputType = "MouseButton1", Position = Vector2.new(10, 10)}
firstTab.button.Activated:Fire(click)
assert(gui.SelectedObject == firstTab.button)
press("Right", true)
assert(first.currentTab == "First")
press("Right")
assert(first.currentTab == "Controls" and gui.SelectedObject == controls.button)
assert(second.currentTab == "Second")
press("Down")
assert(gui.SelectedObject == buttonControl)
press("Return")
press("Down")
assert(gui.SelectedObject == toggle.Instance)
press("KeypadEnter")
assert(toggle:GetValue() == true)
press("Down")
assert(gui.SelectedObject == entry and not entry:IsFocused())
assert(controls.content.CanvasPosition.Y == 48)
press("Return")
assert(entry:IsFocused())
press("Left")
press("Up")
assert(first.currentTab == "Controls" and entry:IsFocused())
entry.Text = "Typed"
entry:ReleaseFocus(true)
assert(gui.SelectedObject == entry)
press("Down")
assert(gui.SelectedObject == choiceTrigger)
press("Return")
assert(choicePopup.Visible)
press("Left")
assert(first.currentTab == "Controls" and choicePopup.Visible)
press("Down")
press("Return")
assert(choice:GetValue() == "Two" and not choicePopup.Visible)
press("Left")
assert(first.currentTab == "First" and gui.SelectedObject == firstTab.button)
press("Left")
assert(first.currentTab == "Controls" and gui.SelectedObject == controls.button)
press("Up")
assert(gui.SelectedObject == choiceTrigger)
click.Position = Vector2.new(700, 700)
input.InputBegan:Fire(click)
press("Right")
assert(first.currentTab == "Controls" and gui.SelectedObject == nil)
gui.SelectedObject = mainTab
press("Down")
press("Return")
assert(gui.SelectedObject == mainTab)

for _, callback in ipairs(deferred) do callback() end
assert(buttonClicks == 1 and submitCount == 1)

print("Focus traversal and dropdown checks passed")
