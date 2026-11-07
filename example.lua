-- Run on the client with HttpGet/loadstring enabled. In Studio, put main.lua in
-- a ModuleScript and replace the next line with require(path.to.MainModule).
-- Config persistence requires readfile/writefile; the controls also work without them.
-- Callbacks run deferred, after each control finishes updating.
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/lain804/luaui/refs/heads/master/main.lua"))()

local Library = UI.new({
    Title = "UI Library Showcase",
    Size = UDim2.new(0, 600, 0, 400),
    Position = UDim2.new(0, 100, 0, 100),
    GuiName = "UILibraryShowcase",
    -- Defaults to UILibraryShowcase.json; ConfigFile can override it here.
    ConfigFolder = "UILibraryExamples",
    AutoSave = true,
    AutoLoad = true,
    KeyCode = Enum.KeyCode.RightShift,
    MinSize = Vector2.new(420, 300),
    MaxSize = Vector2.new(780, 560)
})

-- Optional runtime override: Library:SetConfigFile("CustomShowcase.json")

local MainTab = Library:CreateTab({ Name = "Main" })
local ConfigTab = Library:CreateTab({ Name = "Config" })
local MiscTab = Library:CreateTab({ Name = "Misc" })

local StatusLabel = MainTab:Label({
    Text = "Status: Ready"
})

MainTab:Label({
    Text = "RightShift: hide/show. Drag the title or resize from the bottom-right."
})

MainTab:Button({
    Text = "Click Me",
    Callback = function()
        print("Button clicked")
        StatusLabel:SetValue("Status: Button clicked")
    end
})

local AutoToggle = MainTab:Toggle({
    Text = "Auto Farm",
    Flag = "AutoFarm",
    Default = false,
    Callback = function(value)
        print("Auto Farm:", value)
        StatusLabel:SetValue("Status: Auto Farm = " .. tostring(value))
    end
})

local SpeedMeter = MainTab:Meter({
    Text = "Speed Meter",
    Min = 16,
    Max = 200,
    Default = 16,
    LowColor = Color3.fromRGB(255, 85, 85),
    HighColor = Color3.fromRGB(85, 255, 130),
    Format = function(value, alpha)
        return string.format("%d (%d%%)", value, math.floor(alpha * 100 + 0.5))
    end
})

local SpeedSlider = MainTab:Slider({
    Text = "WalkSpeed",
    Flag = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Increment = 1,
    Callback = function(value)
        print("WalkSpeed:", value)
        SpeedMeter:SetValue(value)

        local character = game.Players.LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end
})
SpeedMeter:SetValue(SpeedSlider:GetValue())

local FractionSlider = MainTab:Slider({
    Text = "Fractional Value",
    Flag = "FractionalValue",
    Min = -1,
    Max = 1,
    Default = 0.25,
    Increment = 0.05,
    Precision = 2,
    CallOnLoad = false,
    Callback = function(value)
        StatusLabel:SetValue("Status: Fractional value = " .. tostring(value))
    end
})

local NameBox = MainTab:Textbox({
    Text = "Target Name",
    Placeholder = "Type something...",
    Flag = "TargetName",
    Default = "",
    Callback = function(value, enterPressed)
        print("Textbox:", value, enterPressed)
        StatusLabel:SetValue("Status: Text updated")
    end
})

local ModeDropdown = MainTab:Dropdown({
    Text = "Mode",
    Flag = "SelectedMode",
    Options = { "Easy", "Normal", "Hard", "Insane" },
    Default = "Normal",
    Callback = function(value)
        print("Dropdown selected:", value)
        StatusLabel:SetValue("Status: Mode = " .. tostring(value))
    end
})

local FeatureDropdown = MainTab:Dropdown({
    Text = "Features (Multi)",
    Flag = "EnabledFeatures",
    Options = { "Hints", "Logging", "Notifications", "Animations", "Sound" },
    Default = { "Hints", "Animations" },
    Multi = true,
    Callback = function(values)
        print("Selected features:", table.concat(values, ", "))
        StatusLabel:SetValue("Status: " .. #values .. " features selected")
    end
})

MainTab:Label({ Text = "Dropdowns: search, arrows, Enter/Escape; multi-select adds All/Clear." })
MainTab:Label({ Text = "Keys: click to rebind, Escape cancels, Backspace clears; gamepad keys also work." })

local ActionKeybind = MainTab:Keybind({
    Text = "Action Key",
    Flag = "ActionKey",
    Default = Enum.KeyCode.F,
    IgnoreTextBox = true,
    Callback = function(input)
        print("Action key pressed:", input.KeyCode.Name)
        StatusLabel:SetValue("Status: Action key pressed")
    end,
    Changed = function(keyCode)
        print("Action key changed:", keyCode.Name)
    end
})

MainTab:Separator()

MainTab:Button({
    Text = "Hide Textbox",
    Callback = function()
        NameBox:Hide()
        StatusLabel:SetValue("Status: Textbox hidden")
    end
})

MainTab:Button({
    Text = "Show Textbox",
    Callback = function()
        NameBox:Show()
        StatusLabel:SetValue("Status: Textbox shown")
    end
})

MainTab:Button({
    Text = "Set Toggle True",
    Callback = function()
        AutoToggle:SetValue(true)
    end
})

MainTab:Button({
    Text = "Set Slider To 100",
    Callback = function()
        SpeedSlider:SetValue(100)
    end
})

MainTab:Button({
    Text = "Set Dropdown To Hard",
    Callback = function()
        ModeDropdown:SetValue("Hard")
    end
})

MainTab:Button({
    Text = "Update Dropdown Options",
    Callback = function()
        ModeDropdown:SetOptions({ "Casual", "Hard", "Nightmare" })
        StatusLabel:SetValue("Status: Dropdown options updated")
    end
})

MainTab:Button({
    Text = "Toggle Without Callback",
    Callback = function()
        AutoToggle:SetValue(not AutoToggle:GetValue(), true)
        StatusLabel:Set("Status: Toggle changed silently (Set/Get aliases work too)")
    end
})

MainTab:Button({
    Text = "Print Current Values",
    Callback = function()
        print("Toggle:", AutoToggle:GetValue())
        print("Slider:", SpeedSlider:GetValue())
        print("Textbox:", NameBox:GetValue())
        print("Dropdown:", ModeDropdown:GetValue())
        print("Action Key:", ActionKeybind:GetValue())
        print("Fraction:", FractionSlider:Get())
        print("Meter:", SpeedMeter:GetValue())
        print("Features:", table.concat(FeatureDropdown:GetValue(), ", "))
        print("Available modes:", table.concat(ModeDropdown:GetOptions(), ", "))
        print("Toggle alias:", AutoToggle:Get())
    end
})

ConfigTab:Label({
    Text = "Config controls"
})

ConfigTab:Button({
    Text = "Save Config",
    Callback = function()
        local ok = Library:SaveConfig()
        print("SaveConfig:", ok)
        StatusLabel:SetValue(ok and "Status: Config saved" or "Status: Save failed (file API unavailable?)")
    end
})

ConfigTab:Button({
    Text = "Load Config",
    Callback = function()
        local ok = Library:LoadConfig(true)
        print("LoadConfig:", ok)
        StatusLabel:SetValue(ok and "Status: Config loaded" or "Status: Config unavailable or invalid")
    end
})

ConfigTab:Button({
    Text = "Load Config Without Callbacks",
    Callback = function()
        local ok = Library:LoadConfig(false)
        SpeedMeter:SetValue(SpeedSlider:GetValue())
        StatusLabel:SetValue(ok and "Status: Values loaded silently" or "Status: Config unavailable")
    end
})

local ConfigFileBox = ConfigTab:Textbox({
    Text = "Config Filename",
    Default = Library.ConfigFile,
    Placeholder = "Showcase.json"
})

ConfigTab:Button({
    Text = "Change Config File",
    Callback = function()
        local filename = ConfigFileBox:GetValue()
        if not filename:match("%S") then
            StatusLabel:SetValue("Status: Enter a config filename")
            return
        end
        local ok = Library:SetConfigFile(filename)
        StatusLabel:SetValue(ok and "Status: Config destination changed" or "Status: Config change failed or busy")
    end
})

ConfigTab:Button({
    Text = "Set Flags Manually",
    Callback = function()
        Library:SetFlag("AutoFarm", true)
        Library:SetFlag("WalkSpeed", 120)
        Library:SetFlag("TargetName", "ExampleUser")
        Library:SetFlag("SelectedMode", "Hard")
        Library:SetFlag("ActionKey", "G")
    end
})

ConfigTab:Button({
    Text = "Read Saved Flag",
    Callback = function()
        print("Saved AutoFarm flag:", Library:GetFlag("AutoFarm"))
    end
})

MiscTab:Label({
    Text = "Additional API demonstration"
})

MiscTab:Separator()
MiscTab:Label({ Text = "Background" })

local backgroundAssetId = "rbxassetid://13476155084"
local function syncBackground()
    local image = Library:GetFlag("BackgroundId") or backgroundAssetId
    if Library:GetFlag("BackgroundEnabled") then
        Library:SetBackground(image)
    else
        Library:SetBackgroundEnabled(false)
    end
    Library:SetBackgroundTransparency((Library:GetFlag("BackgroundTransparency") or 50) / 100)
    Library:SetElementTransparency((Library:GetFlag("ElementTransparency") or 30) / 100)
end

MiscTab:Textbox({
    Text = "Background ID",
    Placeholder = "rbxassetid://...",
    Flag = "BackgroundId",
    Default = backgroundAssetId,
    Callback = syncBackground
})

MiscTab:Slider({
    Text = "BG Transparency",
    Flag = "BackgroundTransparency",
    Min = 0,
    Max = 100,
    Default = 50,
    Increment = 1,
    Callback = function(value)
        Library:SetBackgroundTransparency(value / 100)
    end
})

local BackgroundToggle = MiscTab:Toggle({
    Text = "Background Image",
    Flag = "BackgroundEnabled",
    Default = false,
    Callback = syncBackground
})

MiscTab:Slider({
    Text = "Element Transparency",
    Flag = "ElementTransparency",
    Min = 0,
    Max = 100,
    Default = 30,
    Callback = function(value)
        Library:SetElementTransparency(value / 100)
    end
})

MiscTab:Button({
    Text = "Clear Background",
    Callback = function()
        BackgroundToggle:Set(false, true)
        Library:SetBackground(nil)
    end
})

local ResizeToggle = MiscTab:Toggle({
    Text = "Allow Resizing",
    Flag = "AllowResizing",
    Default = true,
    Callback = function(value)
        Library:SetResizable(value)
    end
})
Library:SetResizable(ResizeToggle:GetValue())

MiscTab:Button({
    Text = "Set Compact Resize Bounds",
    Callback = function()
        Library:SetResizeBounds(Vector2.new(420, 300), Vector2.new(600, 420))
        local size = Library:GetSize()
        StatusLabel:SetValue(string.format("Status: Window is %d x %d", size.X, size.Y))
    end
})

MiscTab:Button({
    Text = "Restore Resize Bounds",
    Callback = function()
        Library:SetResizeBounds(Vector2.new(420, 300), Vector2.new(780, 560))
    end
})

MiscTab:Button({
    Text = "Set Small Window",
    Callback = function()
        Library:SetSize(Vector2.new(520, 340))
    end
})

MiscTab:Button({
    Text = "Set Large Window",
    Callback = function()
        Library:SetSize(720, 500)
    end
})

MiscTab:Button({
    Text = "Set Relative Window Size",
    Callback = function()
        Library:SetSize(UDim2.new(0.6, 0, 0.6, 0))
    end
})

local TemporaryLabel
MiscTab:Button({
    Text = "Create Temporary Label",
    Callback = function()
        if not TemporaryLabel or TemporaryLabel.Destroyed then
            TemporaryLabel = MiscTab:Label({ Text = "Temporary label: hide, show, remove, or destroy me." })
        else
            TemporaryLabel:SetValue("Status: Temporary label already exists")
        end
    end
})

MiscTab:Button({
    Text = "Hide / Show Temporary Label",
    Callback = function()
        if not TemporaryLabel or TemporaryLabel.Destroyed then return end
        if TemporaryLabel.Hidden then
            MiscTab:Show(TemporaryLabel)
        else
            MiscTab:Hide(TemporaryLabel.Instance)
        end
    end
})

MiscTab:Button({
    Text = "Remove Temporary Label",
    Callback = function()
        if TemporaryLabel then MiscTab:Remove(TemporaryLabel) end
    end
})

MiscTab:Button({
    Text = "Destroy Temporary Label",
    Callback = function()
        if TemporaryLabel then TemporaryLabel:Destroy() end
    end
})

local TemporaryTab
MiscTab:Button({
    Text = "Create / Open Temporary Tab",
    Callback = function()
        if not TemporaryTab or TemporaryTab.Destroyed then
            TemporaryTab = Library:CreateTab({ Name = "Temporary", Width = 140 })
            TemporaryTab:Label({ Text = "Tabs can be added, selected, and removed at runtime." })
            local removable = TemporaryTab:Label({ Text = "This label demonstrates Element:Remove()." })
            TemporaryTab:Button({
                Text = "Remove This Label",
                Callback = function() removable:Remove() end
            })
            TemporaryTab:Button({
                Text = "Remove This Tab",
                Callback = function() TemporaryTab:RemoveTab() end
            })
        end
        Library:SwitchTab("Temporary")
    end
})

MiscTab:Button({
    Text = "Reset Values",
    Callback = function()
        AutoToggle:SetValue(false)
        SpeedSlider:SetValue(16)
        NameBox:SetValue("")
        FractionSlider:SetValue(0.25)
        ActionKeybind:SetValue(Enum.KeyCode.F)
        FeatureDropdown:SetValue({ "Hints", "Animations" })
        ModeDropdown:SetOptions({ "Easy", "Normal", "Hard", "Insane" }, true)
        ModeDropdown:SetValue("Normal")
        task.defer(function()
            StatusLabel:SetValue("Status: Reset complete")
        end)
    end
})

MiscTab:Button({
    Text = "Destroy UI",
    Callback = function()
        Library:Destroy()
    end
})

-- Preserve AutoLoad values. Demonstration setters are available as explicit buttons.
syncBackground()
StatusLabel:SetValue("Status: Showcase loaded")
