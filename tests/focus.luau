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
local input = {InputBegan = signal()}
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
local task = {defer = function() end}
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
    function object:GetDescendants() return self.Descendants or {} end
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
    local object = target(className)
    local attributes, signals = {}, {}
    object.Name = className
    object.AbsolutePosition = Vector2.new(0, 0)
    object.AbsoluteSize = Vector2.new(600, 400)
    object.CanvasPosition = Vector2.new(0, 0)
    function object:SetAttribute(name, value) attributes[name] = value end
    function object:GetAttribute(name) return attributes[name] end
    function object:GetPropertyChangedSignal(name)
        if not signals[name] then signals[name] = signal() end
        return signals[name]
    end
    function object:IsFocused() return input.focused == self end
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

print("Focus traversal and dropdown checks passed")
