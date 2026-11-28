-- User code runs after the control has finished updating. It may remove controls,
-- switch tabs, or load another config without mutating an in-progress traversal.
local function dispatchCallback(tab, instance, callback, ...)
    if type(callback) ~= "function" then return end
    local arguments = table.pack(...)
    task.defer(function()
        if tab.Destroyed or tab.library.Destroyed or tab.library._destroying
            or instance:GetAttribute("__uiRemoved") then return end
        callback(table.unpack(arguments, 1, arguments.n))
    end)
end

local Element = {}
Element.__index = Element

function Element.new(tab, instance, data)
    data = data or {}

    local self = setmetatable({}, Element)
    self.Tab = tab
    self.Library = tab.library
    self.Instance = instance
    self.Parent = instance.Parent
    self.Type = data.Type or instance.Name
    self.Flag = data.Flag
    self._getValue = data.GetValue or data.Get
    self._setValue = data.SetValue or data.Set
    self._getOptions = data.GetOptions
    self._setOptions = data.SetOptions
    self._cleanup = data.Cleanup
    self._onHide = data.OnHide
    self._onShow = data.OnShow
    self.LayoutOrder = data.LayoutOrder or tab:_NextLayoutOrder()
    instance.LayoutOrder = self.LayoutOrder
    self.Destroyed = false
    self.Hidden = false
    instance:SetAttribute("__uiChrome", true)
    local objects = instance:GetDescendants()
    table.insert(objects, instance)
    for _, object in ipairs(objects) do
        if object:IsA("TextLabel") or object:IsA("TextButton") then
            object.TextTruncate = Enum.TextTruncate.AtEnd
        end
        self.Library:_DecorateObject(object)
    end

    -- if the background is already enabled, a freshly-created control needs the
    -- same translucency applied so the image shows through it as well.
    if self.Library.BackgroundEnabled then
        self.Library:_applyChromeTransparency(true, instance)
    end

    table.insert(tab.elements, self)
    instance.Destroying:Connect(function()
        self._instanceDestroying = true
        self:Remove()
    end)
    tab:_RefreshCanvas()
    return self
end

function Element:Remove()
    if self.Destroyed then return end
    self.Destroyed = true
    self.Instance:SetAttribute("__uiRemoved", true)
    if self._onHide then pcall(self._onHide) end
    self.Library:_ReleaseElementFocus(self)

    if self.Flag and self.Library.elementsByFlag[self.Flag] == self then
        self.Library.elementsByFlag[self.Flag] = nil
    end

    if self._cleanup then
        pcall(self._cleanup)
    end

    if self.Instance and not self._instanceDestroying then
        self.Instance:Destroy()
    end

    for i, item in ipairs(self.Tab.elements) do
        if item == self then
            table.remove(self.Tab.elements, i)
            break
        end
    end

    self.Tab:_RefreshCanvas()
end

function Element:Destroy()
    self:Remove()
end

function Element:Hide()
    if self.Destroyed or self.Hidden then return end
    self.Hidden = true
    if self._onHide then
        pcall(self._onHide)
    end
    self.Library:_ReleaseElementFocus(self)
    self.Parent = self.Instance.Parent
    self.Instance.Parent = nil
    self.Tab:_RefreshCanvas()
end

function Element:Show()
    if self.Destroyed or not self.Hidden then return end
    self.Hidden = false
    self.Instance.Parent = self.Parent or self.Tab.content
    if self._onShow then
        pcall(self._onShow)
    end
    self.Tab:_RefreshCanvas()
end

function Element:SetValue(value, noCallback)
    if not self.Destroyed and self._setValue then
        self._setValue(value, noCallback)
    end
end

function Element:_GetPersistedValue()
    local value = self:GetValue()
    if typeof(value) == "EnumItem" then return value.Name end
    if value == nil and self.Type == "Dropdown" then return {} end
    return value
end

function Element:GetValue()
    if self._getValue then
        return self._getValue()
    end
    return nil
end

function Element:Set(value, noCallback)
    self:SetValue(value, noCallback)
end

function Element:Get()
    return self:GetValue()
end

function Element:SetOptions(options, noCallback)
    if not self.Destroyed and self._setOptions then
        self._setOptions(options, noCallback)
    end
end

function Element:GetOptions()
    if self._getOptions then
        return self._getOptions()
    end
    return nil
end

Element.dispatchCallback = dispatchCallback

return Element
