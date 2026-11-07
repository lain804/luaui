-- Executor: run with HttpGet/loadstring enabled. In Studio, use require(path.to.MainModule).
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
    Text = "This example uses only real methods from the library."
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

local SpeedSlider = MainTab:Slider({
    Text = "WalkSpeed",
    Flag = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Increment = 1,
    Callback = function(value)
        print("WalkSpeed:", value)

        local character = game.Players.LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = value
        end
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

local ActionKeybind = MainTab:Keybind({
    Text = "Action Key",
    Flag = "ActionKey",
    Default = Enum.KeyCode.F,
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
    Text = "Print Current Values",
    Callback = function()
        print("Toggle:", AutoToggle:GetValue())
        print("Slider:", SpeedSlider:GetValue())
        print("Textbox:", NameBox:GetValue())
        print("Dropdown:", ModeDropdown:GetValue())
        print("Action Key:", ActionKeybind:GetValue())
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

MiscTab:Toggle({
    Text = "Background Image",
    Flag = "BackgroundEnabled",
    Default = false,
    Callback = syncBackground
})

MiscTab:Button({
    Text = "Set Small Window",
    Callback = function()
        Library:SetSize(520, 340)
    end
})

MiscTab:Button({
    Text = "Set Large Window",
    Callback = function()
        Library:SetSize(720, 500)
    end
})

MiscTab:Button({
    Text = "Reset Values",
    Callback = function()
        AutoToggle:SetValue(false)
        SpeedSlider:SetValue(16)
        NameBox:SetValue("")
        ModeDropdown:SetOptions({ "Easy", "Normal", "Hard", "Insane" }, true)
        ModeDropdown:SetValue("Normal")
        StatusLabel:SetValue("Status: Reset complete")
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
