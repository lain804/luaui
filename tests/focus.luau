local Color3 = {fromRGB = function() return {} end}
local Vector2 = {new = function(x, y) return {X = x, Y = y} end}
local TweenInfo = {new = function() return {} end}
local gui = {}
local game = {GetService = function() return gui end}

local function loadLibrary()
    -- INSERT LIBRARY HERE
end

local function target(className, parent)
    local object = {Parent = parent, Visible = true, Selectable = true}
    function object:IsA(class)
        return class == className or class == "GuiObject" and className ~= "ScreenGui"
    end
    function object:GetDescendants() return self.Descendants or {} end
    return object
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

print("Focus traversal checks passed")
