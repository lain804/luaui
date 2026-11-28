local Util = require("./util")
local finiteNumber = Util.finiteNumber
local getEnvFunction = Util.getEnvFunction
local Style = require("./style")
local Theme = Style.Theme

local Background = {}

-- accepts a number id, an "rbxasset[id]://..." string, an http url, a plain
-- numeric string, or a local file name. file names (anything that doesn't already
-- contain "rbxasset") are resolved through the executor's getcustomasset, e.g.
-- "penar.png" -> getcustomasset("penar.png").
local function normalizeImage(image)
    if type(image) == "number" then
        if not finiteNumber(image, nil) or image <= 0 or image % 1 ~= 0 then return "" end
        return "rbxassetid://" .. string.format("%.0f", image)
    end

    if type(image) ~= "string" then
        return ""
    end
    image = image:match("^%s*(.-)%s*$")
    if image == "" then return "" end

    -- already a roblox content string ("rbxasset://" / "rbxassetid://") -> use directly
    if image:match("^rbxasset://") or image:match("^rbxassetid://")
        or image:match("^rbxthumb://") or image:match("^rbxgameasset://") then
        return image
    end

    -- bare asset id -> rbxassetid://
    local digits = image:match("^%s*(%d+)%s*$")
    if digits then
        return "rbxassetid://" .. digits
    end

    -- remote url -> use directly
    if string.find(image, "^https?://") then
        return image
    end

    -- otherwise treat it as a local file name and resolve it with getcustomasset
    local getCustomAsset = getEnvFunction("getcustomasset") or getEnvFunction("getsynasset")
    if getCustomAsset then
        local ok, asset = pcall(getCustomAsset, image)
        if ok and type(asset) == "string" and asset ~= "" then
            return asset
        end
    end

    return image
end

-- make a single instance's background translucent (remembering its original value
-- in an attribute) when `on`, or restore the saved original when off. only touches
-- objects that started out with a visible (non-transparent) background.
local BG_ATTR = "__uiOrigBgTransparency"
local function tagBackgroundTransparency(obj, on, transparency)
    if on then
        if obj:GetAttribute(BG_ATTR) == nil then
            if obj.BackgroundTransparency >= 1 then
                return -- already see-through (labels, scrolling frames), leave alone
            end
            obj:SetAttribute(BG_ATTR, obj.BackgroundTransparency)
        end
        obj.BackgroundTransparency = transparency
    else
        local original = obj:GetAttribute(BG_ATTR)
        if original ~= nil then
            obj.BackgroundTransparency = original
            obj:SetAttribute(BG_ATTR, nil)
        end
    end
end

-- walk the chrome (title bar, tabs, controls, ...) and make every opaque
-- background translucent so the image shows through them too. the background
-- image and the content area are skipped (the content area is handled on its own
-- so the body stays fully clear). pass `root` to only process a subtree.
function Background:_applyChromeTransparency(on, root)
    root = root or self.MainFrame
    if not root then return end

    local transparency = self.ElementTransparency or 0.3

    local objects = root:GetDescendants()
    table.insert(objects, root)
    if root == self.MainFrame then
        for _, tab in ipairs(self.tabs or {}) do
            for _, element in ipairs(tab.elements) do
                if element.Hidden then table.insert(objects, element.Instance) end
            end
        end
    end

    for _, obj in ipairs(objects) do
        if obj ~= self.BackgroundImage
            and obj ~= self.MainFrame
            and obj ~= self.ContentArea
            and obj:IsA("GuiObject")
            and obj:GetAttribute("__uiChrome") == true
        then
            tagBackgroundTransparency(obj, on, transparency)
        end
    end
end

function Background:SetElementTransparency(transparency)
    if self.Destroyed then return end
    self.ElementTransparency = math.clamp(finiteNumber(transparency, 0.3), 0, 1)
    if self.BackgroundEnabled then
        self:_applyChromeTransparency(true)
    end
end

-- show/hide the background while keeping the last image and transparency.
function Background:SetBackgroundEnabled(enabled)
    if self.Destroyed or not self.BackgroundImage then return end
    self._backgroundVersion = (self._backgroundVersion or 0) + 1

    local on = not not enabled and self.BackgroundImage.Image ~= ""
    self.BackgroundEnabled = on
    self.BackgroundImage.Visible = on

    -- the content area is normally opaque, which would hide the image. make it
    -- transparent while the background is on so the image shows through behind
    -- the controls, then restore it when off.
    if self.ContentArea then
        self.ContentArea.BackgroundTransparency = on and 1 or 0
        self.ContentArea.BackgroundColor3 = Theme.Background
    end

    -- the title bar, tab bar and every control are opaque too; make them
    -- translucent so the image is visible through them as well.
    self:_applyChromeTransparency(on)
end

-- pass nil/false as the image to clear the background.
function Background:SetBackground(image, transparency)
    if self.Destroyed or not self.BackgroundImage then return end
    self._backgroundVersion = (self._backgroundVersion or 0) + 1
    local version = self._backgroundVersion

    if image == nil or image == false then
        self.BackgroundImage.Image = ""
        self:SetBackgroundEnabled(false)
        return
    end

    -- getcustomasset may yield. A newer image or enable/disable request wins.
    local transparencyVersion = self._transparencyVersion
    local normalized = normalizeImage(image)
    if self.Destroyed or version ~= self._backgroundVersion then return end
    if transparency ~= nil and transparencyVersion == self._transparencyVersion then
        self.BackgroundTransparency = math.clamp(finiteNumber(transparency, 0.5), 0, 1)
    end

    self.BackgroundImage.Image = normalized
    self.BackgroundImage.ImageTransparency = self.BackgroundTransparency
    self:SetBackgroundEnabled(true)
end

function Background:SetBackgroundTransparency(transparency)
    if self.Destroyed then return end
    self._transparencyVersion = (self._transparencyVersion or 0) + 1
    self.BackgroundTransparency = math.clamp(finiteNumber(transparency, 0.5), 0, 1)
    if self.BackgroundImage then
        self.BackgroundImage.ImageTransparency = self.BackgroundTransparency
    end
end

return Background
