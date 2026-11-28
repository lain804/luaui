local __DARKLUA_BUNDLE_MODULES={cache={}::any}do do local function __modImpl()local function finiteNumber(value, fallback)
    local number = tonumber(value)
    if not number or number ~= number or math.abs(number) == math.huge then
        return fallback
    end
    return number
end

local function normalizeRange(minimum, maximum)
    minimum = finiteNumber(minimum, 0)
    maximum = finiteNumber(maximum, 100)
    if maximum < minimum then minimum, maximum = maximum, minimum end
    if maximum == minimum then maximum = minimum + math.max(1, math.abs(minimum) * 1e-6) end
    if not finiteNumber(maximum - minimum, nil) or maximum <= minimum then return 0, 100 end
    return minimum, maximum
end

local function disconnectAll(connections)
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(connections)
end

local function getEnvFunction(name)
    local environment = (getgenv and getgenv()) or getfenv()
    local fn = environment[name] or rawget(_G, name)
    return type(fn) == "function" and fn or nil
end

local function safeCall(fn, ...)
    if typeof(fn) ~= "function" then return false, nil end
    local ok, result = pcall(fn, ...)
    return ok, result
end

return {
    finiteNumber = finiteNumber,
    normalizeRange = normalizeRange,
    disconnectAll = disconnectAll,
    getEnvFunction = getEnvFunction,
    safeCall = safeCall,
}
end function __DARKLUA_BUNDLE_MODULES.a():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.a if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.a=v end return v.c end end do local function __modImpl()
local UserInputService = game:GetService("UserInputService")

local Util = __DARKLUA_BUNDLE_MODULES.a()
local finiteNumber = Util.finiteNumber

local Theme = {
    Background = Color3.fromRGB(15, 15, 15),
    Tab = Color3.fromRGB(25, 25, 25),
    TabActive = Color3.fromRGB(35, 35, 35),
    Element = Color3.fromRGB(20, 20, 20),
    ElementHover = Color3.fromRGB(32, 32, 32),
    ElementPressed = Color3.fromRGB(46, 46, 46),
    BorderHover = Color3.fromRGB(76, 76, 76),
    Text = Color3.fromRGB(216, 216, 216),
    TextDim = Color3.fromRGB(145, 145, 145),
    Accent = Color3.fromRGB(255, 255, 255),
    Border = Color3.fromRGB(45, 45, 45),
    Track = Color3.fromRGB(10, 10, 10),
    Warning = Color3.fromRGB(245, 194, 121)
}

local ROW_INSET = 12
local TITLE_HEIGHT = 34
local TAB_HEIGHT = UserInputService.TouchEnabled and 48 or 38
local INPUT_ROW_HEIGHT = UserInputService.TouchEnabled and 52 or 30

local function createRow(tab, className, name, height, minimumHeight)
    assert(not tab.Destroyed and not tab.library.Destroyed and not tab.library._destroying, "Cannot add controls to a destroyed UI")
    local row = Instance.new(className)
    row.Name = name
    row.Parent = tab.content
    row.BackgroundColor3 = Theme.Element
    row.BorderColor3 = Theme.Border
    row.BorderSizePixel = 1
    row.Size = UDim2.new(1, 0, 0, math.max(minimumHeight, UserInputService.TouchEnabled and 44 or 0, finiteNumber(height, minimumHeight)))
    row.AnchorPoint = Vector2.new(0.5, 0)
    row.Position = UDim2.new(0.5, 0, 0, 0)
    return row
end

local function createLabel(parent, text, textSize)
    local label = Instance.new("TextLabel")
    label.Parent = parent
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Font = Enum.Font.Code
    label.Text = text
    label.TextColor3 = Theme.Text
    label.TextSize = textSize or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function createInputSurface(parent, className)
    local surface = Instance.new(className)
    surface.Parent = parent
    surface.BackgroundColor3 = Theme.Background
    surface.BorderColor3 = Theme.Border
    surface.BorderSizePixel = 1
    surface.AnchorPoint = Vector2.new(1, 0)
    surface.Position = UDim2.new(1, -8, 0, 4)
    surface.Size = UDim2.new(0.58, -8, 1, -8)
    return surface
end

local function createTrack(parent, color)
    local track = Instance.new("Frame")
    track.Parent = parent
    track.BackgroundColor3 = Theme.Track
    track.BorderSizePixel = 0
    track.Position = UDim2.new(0, 10, 1, -17)
    track.Size = UDim2.new(1, -20, 0, 6)

    local fill = Instance.new("Frame")
    fill.Parent = track
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    return track, fill
end

return {
    Theme = Theme,
    ROW_INSET = ROW_INSET,
    TITLE_HEIGHT = TITLE_HEIGHT,
    TAB_HEIGHT = TAB_HEIGHT,
    INPUT_ROW_HEIGHT = INPUT_ROW_HEIGHT,
    createRow = createRow,
    createLabel = createLabel,
    createInputSurface = createInputSurface,
    createTrack = createTrack,
}
end function __DARKLUA_BUNDLE_MODULES.b():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.b if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.b=v end return v.c end end do local function __modImpl()
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Style = __DARKLUA_BUNDLE_MODULES.b()
local Theme = Style.Theme

local FEEDBACK_TWEEN = TweenInfo.new(0.09)

local function isPointerPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function containsPoint(object, point)
    local position, size = object.AbsolutePosition, object.AbsoluteSize
    return point.X >= position.X and point.X < position.X + size.X
        and point.Y >= position.Y and point.Y < position.Y + size.Y
end

local function bindButtonFeedback(button, idleColor)
    local hovering, active = false, false
    local releaseConnection, transition
    local function render(immediate)
        local pressed = releaseConnection ~= nil
        local background = pressed and Theme.ElementPressed
            or active and Theme.TabActive
            or hovering and Theme.ElementHover or idleColor
        local border = (pressed or active) and Theme.Accent
            or hovering and Theme.BorderHover or Theme.Border
        if transition then transition:Cancel(); transition = nil end
        if immediate or GuiService.ReducedMotionEnabled then
            button.BackgroundColor3 = background
            button.BorderColor3 = border
        else
            transition = TweenService:Create(button, FEEDBACK_TWEEN, {
                BackgroundColor3 = background,
                BorderColor3 = border
            })
            transition:Play()
        end
    end
    local function release(immediate)
        if releaseConnection then releaseConnection:Disconnect(); releaseConnection = nil end
        render(immediate)
    end
    local function reset()
        hovering = false
        release(true)
    end
    button.MouseEnter:Connect(function() hovering = true; render() end)
    button.MouseLeave:Connect(function() hovering = false; release() end)
    button.InputBegan:Connect(function(input)
        if releaseConnection or not isPointerPress(input) then return end
        releaseConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End
                or input.UserInputState == Enum.UserInputState.Cancel then release() end
        end)
        render()
    end)
    button.Destroying:Connect(function()
        if releaseConnection then releaseConnection:Disconnect() end
        if transition then transition:Cancel() end
    end)
    return reset, function(enabled)
        if active == enabled then return end
        active = enabled
        render()
    end
end

local function isVisible(library, object)
    if library.Destroyed or library._destroying or not library.ScreenGui.Enabled then return false end
    while object and object ~= library.ScreenGui do
        if object:IsA("GuiObject") and not object.Visible then return false end
        object = object.Parent
    end
    return object == library.ScreenGui
end

local function bindActivation(library, button, callback)
    library._activationHandlers = library._activationHandlers or {}
    local function activate(...)
        if isVisible(library, button) then callback(...) end
    end
    library._activationHandlers[button] = activate
    button.Destroying:Connect(function() library._activationHandlers[button] = nil end)
    return button.Activated:Connect(function(input, ...)
        if input and isPointerPress(input) and isVisible(library, button) then
            library:_SetPointerOrigin(button)
        end
        activate(input, ...)
    end)
end

local function focusDirection()
    return (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift))
        and -1 or 1
end

local function revealSelection(frame, object, axis)
    local start = object.AbsolutePosition[axis] - frame.AbsolutePosition[axis]
    local length = object.AbsoluteSize[axis]
    local viewport = frame.AbsoluteWindowSize[axis]
    local canvas = frame.CanvasPosition
    local offset = canvas[axis]
    if start < 0 or length >= viewport then
        offset = math.max(offset + start, 0)
    elseif start + length > viewport then
        offset = offset + start + length - viewport
    else
        return
    end
    frame.CanvasPosition = axis == "X" and Vector2.new(offset, canvas.Y) or Vector2.new(canvas.X, offset)
end

local function stepFocus(library, targets, direction, focused, controlCanvas)
    if #targets == 0 then return end
    local index = table.find(targets, focused or library._focusedControl or library._pointerOrigin) or (direction > 0 and 0 or 1)
    local target = targets[(index - 1 + direction) % #targets + 1]
    if focused and focused ~= target then focused:ReleaseFocus() end
    if controlCanvas then revealSelection(controlCanvas, target, "Y") end
    library:_SetControlFocus(target)
    if not controlCanvas and target ~= focused and target:IsA("TextBox") then target:CaptureFocus() end
    return target
end

return {
    isPointerPress = isPointerPress,
    containsPoint = containsPoint,
    bindButtonFeedback = bindButtonFeedback,
    isVisible = isVisible,
    bindActivation = bindActivation,
    focusDirection = focusDirection,
    revealSelection = revealSelection,
    stepFocus = stepFocus,
}
end function __DARKLUA_BUNDLE_MODULES.c():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.c if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.c=v end return v.c end end do local function __modImpl()
local HttpService = game:GetService("HttpService")

local Util = __DARKLUA_BUNDLE_MODULES.a()
local getEnvFunction = Util.getEnvFunction
local safeCall = Util.safeCall
local disconnectAll = Util.disconnectAll

local Config = {}

local function copyFlagValue(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, item in pairs(value) do result[key] = copyFlagValue(item, seen) end
    return result
end

local function sameFlagValue(left, right, seen)
    if left == right then return true end
    if type(left) ~= "table" or type(right) ~= "table" then return false end
    seen = seen or {}
    if seen[left] == right then return true end
    seen[left] = right
    for key, value in pairs(left) do
        if not sameFlagValue(value, right[key], seen) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

function Config:_SetSaveStatus(status)
    self.SaveStatus = status
    if self.SaveIndicator and not self.Destroyed then
        self.SaveIndicator.Text = status == "Failed" and "Save failed"
            or status == "LoadFailed" and "Load failed" or status == "Recovered" and "Recovered"
            or status == "FileCheckUnavailable" and "No file check" or ""
        self.SaveIndicator.Visible = self.SaveIndicator.Text ~= ""
        self.TitleBar.Title.Size = UDim2.new(1, self.SaveIndicator.Visible and -106 or -20, 1, 0)
    end
end

function Config:GetFlag(flag)
    return copyFlagValue(self.flags[flag])
end

function Config:SetFlag(flag, value, noCallback)
    if self.Destroyed then return end
    local element = self.elementsByFlag[flag]
    if element then
        element:SetValue(value, noCallback)
    else
        self:_StoreFlag(flag, value)
    end
end

function Config:_StoreFlag(flag, value, fillOnly)
    if self.Destroyed then return end
    local changed = not sameFlagValue(self.flags[flag], value)
    if changed then
        self.flags[flag] = copyFlagValue(value)
    end
    if not self._loading and (changed or not fillOnly) then
        local pending = self._pendingConfigFlags[flag]
        self._pendingConfigFlags[flag] = {fillOnly = fillOnly and (not pending or pending.fillOnly)}
        self._configDirty = true
        self._configVersion = (self._configVersion or 0) + 1
    end
    if self._configDirty then self:_QueueSave() end
end

function Config:_QueueSave()
    if not self.AutoSave or self._autoSaveBlocked or self._loading or self.Destroyed or self._destroying then return end
    if self._configBusy then return end
    if not getEnvFunction("writefile") then return end
    if self._saveTask then return end
    self._saveTask = task.delay(0.25, function()
        self._saveTask = nil
        if not self.Destroyed then self:_SaveConfig(true) end
    end)
end

local function normalizeConfigPath(path)
    path = path:gsub("\\", "/")
    local last = path:match("([^/]+)$")
    if not last or last == "." or last == ".." or last:lower():match("%.bak[. ]*$") then return nil end

    local root = path:match("^//[^/]+/[^/]+/") or path:match("^%a:/")
        or path:match("^/") or path:match("^%a:") or ""
    local absolute = root:sub(-1) == "/"
    -- shortcut: lexical paths only, use host file identity if aliases such as symlinks are supported.
    local parts = {}
    for part in path:sub(#root + 1):gmatch("[^/]+") do
        if part == ".." then
            if #parts > 0 and parts[#parts] ~= ".." then
                table.remove(parts)
            elseif not absolute then
                table.insert(parts, part)
            end
        elseif part ~= "." then
            table.insert(parts, part)
        end
    end
    if #parts == 0 then return nil end
    return root .. table.concat(parts, "/")
end

-- Separately loaded copies of the library can write the same executor file.
local function configFileState(path)
    local environment = getgenv and getgenv() or shared
    local files = environment.__luauiConfigFiles
    if not files then
        files = setmetatable({}, {__mode = "v"})
        environment.__luauiConfigFiles = files
    end
    if not files[path] then files[path] = {} end
    return files[path]
end

local function lockConfigFile(file)
    while file.busy do task.wait() end
    file.busy = true
end

local function runConfigOperation(operation)
    -- If the caller is cancelled while waiting, the worker still releases the file lock.
    local result
    task.spawn(function() result = table.pack(pcall(operation)) end)
    while not result do task.wait() end
    if not result[1] then error(result[2], 0) end
    return result[2]
end

local function readConfig(path)
    local checked, exists = safeCall(getEnvFunction("isfile"), path)
    if checked and exists == false then return nil, nil, "missing" end
    local read, data = safeCall(getEnvFunction("readfile"), path)
    if not read or type(data) ~= "string" then
        return nil, nil, checked and exists == true and "unreadable" or "unchecked"
    end
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, data)
    if ok and type(decoded) == "table" then return decoded, data end
    return nil, nil, "invalid"
end

-- A pending save belongs to the old file. Finish it before changing destinations.
function Config:SetConfigFile(fileName)
    assert(type(fileName) == "string" and fileName:match("%S"), "SetConfigFile expects a non-empty filename")
    if self.Destroyed or self._destroying or self._configBusy then return false end
    local path = normalizeConfigPath(self.ConfigFolder and (self.ConfigFolder .. "/" .. fileName) or fileName)
    if not path then return false end
    local file = configFileState(path)
    local previousFile = self._configFileState
    if not self._autoSaveBlocked then
        if (self._saveTask or self.AutoSave and self._configDirty) and not self:_SaveConfig(true) then return false end
        if self._configDirty and self.AutoSave then return false end
    elseif self._configFileState ~= file then
        self._autoSaveBlocked = nil
        self:_SetSaveStatus("Ready")
    end
    if self.Destroyed or self._destroying or self._configBusy or self._configFileState ~= previousFile then return false end
    self.ConfigFile = fileName
    self.ConfigPath = path
    if self._configFileState ~= file then
        self._configFileState = file
        self._pendingConfigFlags = {}
        for flag in pairs(self.flags) do self._pendingConfigFlags[flag] = {fillOnly = true} end
    end
    return true
end

function Config:SaveConfig()
    return self:_SaveConfig(false)
end

function Config:_SaveConfig(automatic)
    return runConfigOperation(function() return self:_WriteConfig(automatic) end)
end

function Config:_WriteConfig(automatic)
    if self.Destroyed and not self._flushOnDestroy then return false end
    if self._configBusy then
        if self._configBusy == "save" then self._saveAgain = true end
        return false
    end
    self._configDirty = true
    if self._saveTask then
        task.cancel(self._saveTask)
        self._saveTask = nil
    end
    local writefile = getEnvFunction("writefile")
    if not writefile then
        self:_SetSaveStatus("Failed")
        warn("Config: getgenv().writefile was not found")
        return false
    end

    self._configBusy = "save"
    local path = self.ConfigPath
    local file = self._configFileState
    lockConfigFile(file)
    local success, failure
    local failureStatus = "Failed"
    repeat
        success, failure = pcall(function()
            -- Read under the write lock so unopened files and external edits are preserved.
            local flags, bytes, primaryError = readConfig(path)
            local backupError
            if not flags and (primaryError == "missing" or primaryError == "invalid") then
                local recovered, _, reason = readConfig(path .. ".bak")
                flags, backupError = recovered, reason
            end
            local missing = primaryError == "missing" and backupError == "missing"
            local unreadable = primaryError == "unreadable" or backupError == "unreadable"
            local unchecked = primaryError == "unchecked" or backupError == "unchecked"
            if unchecked or unreadable or automatic and not flags and not missing then
                self._autoSaveBlocked = true
                failureStatus = unchecked and "FileCheckUnavailable" or "LoadFailed"
                if unchecked then error("cannot confirm missing config without a working isfile: " .. path) end
                error("cannot safely save config to " .. path)
            end
            local snapshot = copyFlagValue(self.flags)
            local pending = table.clone(self._pendingConfigFlags)
            local merged = flags or snapshot
            local needsWrite = bytes == nil
            if flags then
                for flag, change in pairs(pending) do
                    if (not change.fillOnly or merged[flag] == nil) and not sameFlagValue(merged[flag], snapshot[flag]) then
                        merged[flag] = snapshot[flag]
                        needsWrite = true
                    end
                end
            end
            if needsWrite then
                local encoded = HttpService:JSONEncode(merged)
                if bytes then
                    local backedUp, result = safeCall(writefile, path .. ".bak", bytes)
                    assert(backedUp and result ~= false, "failed to write backup config")
                end
                local wrote, result = safeCall(writefile, path, encoded)
                assert(wrote and result ~= false, "failed to write config to " .. tostring(path))
            end
            -- Setters can replace these entries while the filesystem yields.
            for flag, change in pairs(pending) do
                if self._pendingConfigFlags[flag] == change then self._pendingConfigFlags[flag] = nil end
            end
        end)
        self._configDirty = not success or next(self._pendingConfigFlags) ~= nil
        -- A write already in flight may outlive Destroy. Flush the final edits
        -- without recreating a timer or touching the destroyed GUI.
    until not (success and (self.Destroyed or self._destroying) and self.AutoSave and self._configDirty)
    file.busy = nil
    self._configBusy = nil
    self._flushOnDestroy = nil
    local saveAgain = self._saveAgain
    self._saveAgain = nil
    if not success then
        self:_SetSaveStatus(failureStatus)
        warn("Config: " .. tostring(failure))
        return false
    end
    self._autoSaveBlocked = nil
    self:_SetSaveStatus("Ready")
    if not self.Destroyed and self._configDirty then
        if saveAgain and not self.AutoSave then
            self._saveTask = task.defer(function()
                self._saveTask = nil
                if not self.Destroyed then self:SaveConfig() end
            end)
        else
            self:_QueueSave()
        end
    end
    return true
end

function Config:LoadConfig(applyCallbacks)
    return runConfigOperation(function() return self:_ReadConfig(applyCallbacks) end)
end

function Config:_ReadConfig(applyCallbacks)
    if self.Destroyed or self._destroying or self._configBusy then return false end
    if not getEnvFunction("readfile") and not getEnvFunction("writefile") then
        return false
    end

    self._configBusy = "load"
    local version = self._configVersion or 0
    local file = self._configFileState
    lockConfigFile(file)
    local decoded, _, primaryError = readConfig(self.ConfigPath)
    local recovered = false
    local backupError
    if not decoded then
        decoded, _, backupError = readConfig(self.ConfigPath .. ".bak")
        recovered = decoded ~= nil
    end
    file.busy = nil
    -- Only a confirmed missing file is safe to initialize automatically.
    local unchecked = primaryError == "unchecked" or not decoded and backupError == "unchecked"
    self._autoSaveBlocked = unchecked or primaryError == "unreadable"
        or not decoded and (primaryError ~= "missing" or backupError ~= "missing")
    local failureStatus = unchecked and "FileCheckUnavailable" or "LoadFailed"
    if self._autoSaveBlocked then
        self:_SetSaveStatus(failureStatus)
        if unchecked then warn("Config: cannot confirm missing config without a working isfile: " .. self.ConfigPath) end
        if self._saveTask then task.cancel(self._saveTask); self._saveTask = nil end
    end
    if not decoded or self.Destroyed or self._destroying or (self._configVersion or 0) ~= version then
        self._configBusy = nil
        if self.Destroyed and self._flushOnDestroy and not self._autoSaveBlocked then
            self:_WriteConfig(true)
        elseif self._configDirty then
            self:_QueueSave()
        end
        return false
    end
    self:_SetSaveStatus(self._autoSaveBlocked and failureStatus or recovered and "Recovered" or "Ready")

    if self._saveTask then
        task.cancel(self._saveTask)
        self._saveTask = nil
    end
    self._configDirty = false
    self._pendingConfigFlags = {}
    self.flags = copyFlagValue(decoded)
    self.loadedFlags = copyFlagValue(decoded)
    for _, tab in ipairs(self.tabs or {}) do
        for _, element in ipairs(tab.elements) do
            if element.Flag and decoded[element.Flag] == nil then
                self.flags[element.Flag] = element:_GetPersistedValue()
                self._pendingConfigFlags[element.Flag] = {fillOnly = true}
            end
        end
    end

    -- Apply without disk writes. Setters normalize persisted values for each control.
    self._loading = true
    local okApply, applyError = pcall(function()
        for _, tab in ipairs(self.tabs or {}) do
            for _, element in ipairs(tab.elements) do
                if element.Flag and decoded[element.Flag] ~= nil then
                    element:SetValue(decoded[element.Flag], applyCallbacks ~= true)
                end
            end
        end
    end)
    self._loading = false
    self._configBusy = nil
    if not okApply then
        warn("Config: failed to apply config: " .. tostring(applyError))
        return false
    end

    return true
end

local function finishDestroy(self)
    self.Destroyed = true
    disconnectAll(self._connections)
    for index = #(self.tabs or {}), 1, -1 do self.tabs[index]:RemoveTab() end
    if self.ScreenGui and not self._screenDestroying then self.ScreenGui:Destroy() end
end

function Config:Destroy()
    if self.Destroyed or self._destroying then return end
    self._destroying = true
    self:_CancelInteractions()
    self:_ClearNavigation()
    if self.AutoSave and not self._autoSaveBlocked and (self._saveTask or self._configDirty) then
        if self._configBusy == "load" then
            self._flushOnDestroy = true
        elseif not self._configBusy then
            return runConfigOperation(function()
                self:_WriteConfig(true)
                finishDestroy(self)
            end)
        end
    end
    finishDestroy(self)
end

return Config
end function __DARKLUA_BUNDLE_MODULES.d():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.d if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.d=v end return v.c end end do local function __modImpl()
local UserInputService = game:GetService("UserInputService")

local Style = __DARKLUA_BUNDLE_MODULES.b()
local Theme = Style.Theme
local createLabel = Style.createLabel
local Input = __DARKLUA_BUNDLE_MODULES.c()
local isVisible = Input.isVisible
local revealSelection = Input.revealSelection
local stepFocus = Input.stepFocus

local Focus = {}

local navigationWindow

local function renderControlFocus(library, object)
    local outline = object:FindFirstChild("FocusOutline")
    if outline then
        outline.Enabled = library._focusedControl == object or object:IsA("TextBox") and object:IsFocused()
    end
end

function Focus:_SetControlFocus(object)
    if object then
        self:_ClaimNavigation()
        self._pointerOrigin = nil
    end
    local previous = self._focusedControl
    if previous == object then return end
    self._focusedControl = object
    if previous then renderControlFocus(self, previous) end
    if object then renderControlFocus(self, object) end
end

function Focus:_ClaimNavigation()
    if navigationWindow == self then return end
    if navigationWindow then navigationWindow:_ClearNavigation() end
    navigationWindow = self
end

function Focus:_ClearNavigation()
    if navigationWindow == self then navigationWindow = nil end
    self._pointerOrigin = nil
    self:_SetControlFocus(nil)
end

function Focus:_SetPointerOrigin(object)
    self:_ClaimNavigation()
    self:_SetControlFocus(nil)
    self._pointerOrigin = object
end

function Focus:_FocusStep(direction, focused, controlsOnly)
    local targets = {}
    if not controlsOnly then
        for _, tab in ipairs(self.tabs) do
            if isVisible(self, tab.button) then
                table.insert(targets, tab.button)
            end
        end
    end
    local controlCanvas
    for _, tab in ipairs(self.tabs) do
        if tab.name == self.currentTab then
            if controlsOnly then controlCanvas = tab.content end
            for _, element in ipairs(tab.elements) do
                if not element.Hidden then
                    local objects = element.Instance:GetDescendants()
                    table.insert(objects, 1, element.Instance)
                    for _, object in ipairs(objects) do
                        if (object:IsA("GuiButton") or object:IsA("TextBox")) and not object:GetAttribute("__uiSkipFocus")
                            and isVisible(self, object) then
                            table.insert(targets, object)
                        end
                    end
                end
            end
            break
        end
    end
    local target = stepFocus(self, targets, direction, focused, controlCanvas)
    for _, tab in ipairs(self.tabs) do
        if tab.button == target then tab:_RevealButton(); break end
    end
    return target
end

function Focus:_StepTab(direction)
    for index, tab in ipairs(self.tabs) do
        if tab.name == self.currentTab then
            local nextTab = self.tabs[(index - 1 + direction) % #self.tabs + 1]
            if self:SwitchTab(nextTab.name) then
                revealSelection(self.TabContainer, nextTab.button, "X")
                self:_SetControlFocus(nextTab.button)
                return true
            end
        end
    end
end

function Focus:_HandleInput(input, gameProcessed, visibilityKey)
    if self.Destroyed or not self.ScreenGui.Enabled then return end
    if Input.isPointerPress(input) then
        if navigationWindow == self then
            if self.MainFrame.Visible and Input.containsPoint(self.MainFrame, input.Position) then
                self:_SetControlFocus(nil)
                self._pointerOrigin = nil
            else
                self:_ClearNavigation()
            end
        end
        return
    end
    if self._closeDropdown or self._cancelKeybind then return end

    local focused = UserInputService:GetFocusedTextBox()
    if focused and not focused:IsDescendantOf(self.MainFrame) then return end
    if gameProcessed and not focused then return end

    local key = input.KeyCode
    local ownsNavigation = navigationWindow == self
    if self.MainFrame.Visible then
        if key == Enum.KeyCode.Tab and (focused or ownsNavigation) then
            return self:_FocusStep(Input.focusDirection(), focused)
        end
        if key == Enum.KeyCode.ButtonSelect and not focused and (ownsNavigation or not navigationWindow) then
            if ownsNavigation then
                self:_ClearNavigation()
                return true
            end
            return self:_StepTab(0)
        end
        if (key == Enum.KeyCode.Escape or key == Enum.KeyCode.ButtonB) and (focused or ownsNavigation) then
            self:_ClearNavigation()
            if focused then focused:ReleaseFocus() end
            return true
        end
        if ownsNavigation and not focused then
            if key == Enum.KeyCode.Left or key == Enum.KeyCode.Right
                or key == Enum.KeyCode.DPadLeft or key == Enum.KeyCode.DPadRight then
                local previous = key == Enum.KeyCode.Left or key == Enum.KeyCode.DPadLeft
                return self:_StepTab(previous and -1 or 1)
            elseif key == Enum.KeyCode.Up or key == Enum.KeyCode.Down
                or key == Enum.KeyCode.DPadUp or key == Enum.KeyCode.DPadDown then
                local previous = key == Enum.KeyCode.Up or key == Enum.KeyCode.DPadUp
                return self:_FocusStep(previous and -1 or 1, nil, true)
            end
            local selected = self._focusedControl or self._pointerOrigin
            local enter = key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter or key == Enum.KeyCode.ButtonA
            if selected and isVisible(self, selected) and (enter or key == Enum.KeyCode.Space) then
                local activate = self._activationHandlers and self._activationHandlers[selected]
                if activate then
                    activate()
                    return true
                end
                if enter and selected:IsA("TextBox") then
                    selected:CaptureFocus()
                    return true
                end
            end
        end
    end
    if not focused and key == visibilityKey then self.MainFrame.Visible = not self.MainFrame.Visible end
end

function Focus:_HideTooltip()
    self._tooltipGeneration = (self._tooltipGeneration or 0) + 1
    if self.Tooltip then self.Tooltip.Visible = false end
    self._tooltipOwner = nil
end

function Focus:_ReleaseElementFocus(element)
    local instance = element.Instance
    local selected = self._focusedControl
    if selected and (selected == instance or selected:IsDescendantOf(instance)) then
        self:_SetControlFocus(nil)
    end
    local origin = self._pointerOrigin
    if origin and (origin == instance or origin:IsDescendantOf(instance)) then self._pointerOrigin = nil end
    local focused = UserInputService:GetFocusedTextBox()
    if focused and (focused == instance or focused:IsDescendantOf(instance)) then focused:ReleaseFocus() end
    self:_HideTooltip()
end

function Focus:_DecorateObject(object)
    -- Roblox routes movement keys to native selection. Keep UI focus local.
    if object:IsA("GuiObject") then object.Selectable = false end
    local isTextBox = object:IsA("TextBox")
    if not object:GetAttribute("__uiSkipFocus") and (object:IsA("GuiButton") or isTextBox) then
        local outline = Instance.new("UIStroke")
        outline.Name = "FocusOutline"
        outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        outline.Color = Theme.Accent
        outline.Thickness = 1
        outline.Enabled = false
        outline.Parent = object
        object.Destroying:Connect(function()
            if self._focusedControl == object then self:_SetControlFocus(nil) end
            if self._pointerOrigin == object then self._pointerOrigin = nil end
        end)
        if isTextBox then
            object.Focused:Connect(function()
                if isVisible(self, object) then self:_ClaimNavigation() end
                renderControlFocus(self, object)
            end)
            object.FocusLost:Connect(function(submitted)
                if submitted and not self._closeDropdown and isVisible(self, object) then
                    self:_SetControlFocus(object)
                end
                renderControlFocus(self, object)
            end)
        end
    end
    if not (object:IsA("TextLabel") or object:IsA("TextButton")) then return end
    local pending
    local function hide()
        if pending then task.cancel(pending); pending = nil end
        if self._tooltipOwner == object then
            self._tooltipOwner = nil
            if self.Tooltip then self.Tooltip.Visible = false end
        end
    end
    object.MouseEnter:Connect(function()
        hide()
        local generation = self._tooltipGeneration or 0
        pending = task.delay(0.45, function()
            pending = nil
            if generation ~= (self._tooltipGeneration or 0) or not isVisible(self, object) then return end
            if not object.TextFits then
                if not self.Tooltip then
                    self.Tooltip = createLabel(self.MainFrame, "", 12)
                    self.Tooltip.BackgroundTransparency = 0
                    self.Tooltip.BackgroundColor3 = Theme.TabActive
                    self.Tooltip.BorderColor3 = Theme.BorderHover
                    self.Tooltip.BorderSizePixel = 1
                    self.Tooltip.TextWrapped = true
                    self.Tooltip.ZIndex = 80
                    local padding = Instance.new("UIPadding")
                    padding.PaddingLeft = UDim.new(0, 8)
                    padding.PaddingRight = UDim.new(0, 8)
                    padding.Parent = self.Tooltip
                end
                local width = math.max(1, self.MainFrame.AbsoluteSize.X - 24)
                self.Tooltip.Text = object.Text
                self.Tooltip.Size = UDim2.new(0, width, 0, 54)
                local y = object.AbsolutePosition.Y - self.MainFrame.AbsolutePosition.Y + object.AbsoluteSize.Y + 4
                self.Tooltip.Position = UDim2.new(0, 12, 0, math.clamp(y, 4, math.max(4, self.MainFrame.AbsoluteSize.Y - 58)))
                self.Tooltip.Visible = true
                self._tooltipOwner = object
            end
        end)
    end)
    object.MouseLeave:Connect(hide)
    object.Destroying:Connect(hide)
end

function Focus:_CancelInteractions()
    for _, tab in ipairs(self.tabs or {}) do
        if tab.name == self.currentTab then
            for _, element in ipairs(tab.elements) do
                if element._onHide then element._onHide() end
                self:_ReleaseElementFocus(element)
            end
            break
        end
    end
    self:_HideTooltip()
end

return Focus
end function __DARKLUA_BUNDLE_MODULES.e():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.e if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.e=v end return v.c end end do local function __modImpl()
local Util = __DARKLUA_BUNDLE_MODULES.a()
local finiteNumber = Util.finiteNumber
local getEnvFunction = Util.getEnvFunction
local Style = __DARKLUA_BUNDLE_MODULES.b()
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
end function __DARKLUA_BUNDLE_MODULES.f():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.f if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.f=v end return v.c end end do local function __modImpl()-- User code runs after the control has finished updating. It may remove controls,
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
end function __DARKLUA_BUNDLE_MODULES.g():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.g if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.g=v end return v.c end end do local function __modImpl()
local Element = __DARKLUA_BUNDLE_MODULES.g()
local dispatchCallback = Element.dispatchCallback
local Style = __DARKLUA_BUNDLE_MODULES.b()
local Theme = Style.Theme
local createRow = Style.createRow
local createLabel = Style.createLabel
local Input = __DARKLUA_BUNDLE_MODULES.c()
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
end function __DARKLUA_BUNDLE_MODULES.h():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.h if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.h=v end return v.c end end do local function __modImpl()
local UserInputService = game:GetService("UserInputService")

local Element = __DARKLUA_BUNDLE_MODULES.g()
local dispatchCallback = Element.dispatchCallback
local Style = __DARKLUA_BUNDLE_MODULES.b()
local Theme = Style.Theme
local createRow = Style.createRow
local createLabel = Style.createLabel
local createTrack = Style.createTrack
local Input = __DARKLUA_BUNDLE_MODULES.c()
local isPointerPress = Input.isPointerPress
local isVisible = Input.isVisible
local Util = __DARKLUA_BUNDLE_MODULES.a()
local finiteNumber = Util.finiteNumber
local normalizeRange = Util.normalizeRange
local disconnectAll = Util.disconnectAll

local Range = {}

function Range:Slider(args)
    args = args or {}
    local text = args.Text or "Slider"
    local min, max = normalizeRange(args.Min, args.Max)
    local default = args.Default
    if default == nil then default = min end
    local callback = args.Callback
    local increment = finiteNumber(args.Increment, 1)
    if increment <= 0 then
        increment = 1
    end
    local flag = args.Flag or args.Save

    local function getDecimalPlaces(number)
        local text = string.format("%.12f", math.abs(number)):gsub("0+$", "")
        local decimals = text:match("%.(%d+)$")
        return decimals and #decimals or 0
    end

    local decimalPlaces = args.Precision
    if decimalPlaces == nil then
        decimalPlaces = math.max(getDecimalPlaces(increment), getDecimalPlaces(min), getDecimalPlaces(max))
    end
    decimalPlaces = math.clamp(math.floor(finiteNumber(decimalPlaces, 0)), 0, 12)

    local roundingScale = 10 ^ decimalPlaces

    local function roundToPrecision(number)
        if decimalPlaces == 0 then
            return number >= 0 and math.floor(number + 0.5) or math.ceil(number - 0.5)
        end

        local scaled = number * roundingScale
        if not finiteNumber(scaled, nil) then return number end
        return (scaled >= 0 and math.floor(scaled + 0.5) or math.ceil(scaled - 0.5)) / roundingScale
    end

    local function snapValue(number)
        if number <= min then return min end
        if number >= max then return max end
        local steps = (number - min) / increment
        if finiteNumber(steps, nil) then number = min + math.floor(steps + 0.5) * increment end
        return math.clamp(roundToPrecision(number), min, max)
    end

    default = self:_GetSaved(flag, default)
    default = finiteNumber(default, min)
    default = snapValue(default)

    local frame = createRow(self, "Frame", "Slider", args.Height, 48)

    local label = createLabel(frame, text, args.TextSize)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.Size = UDim2.new(1, -74, 0, 20)

    local valueLabel = Instance.new("TextBox")
    valueLabel.Parent = frame
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -64, 0, 5)
    valueLabel.Size = UDim2.new(0, 56, 0, 20)
    valueLabel.Font = Enum.Font.Code
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = args.TextSize or 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    valueLabel.Name = "SliderValue"
    valueLabel.BorderSizePixel = 0
    valueLabel.ClearTextOnFocus = false
    valueLabel.PlaceholderText = tostring(default)
    local sliderBg, sliderFill = createTrack(frame, Theme.Accent)

    local sliderHandle = Instance.new("Frame")
    sliderHandle.Parent = sliderBg
    sliderHandle.BackgroundColor3 = Theme.Text
    sliderHandle.BorderSizePixel = 0
    sliderHandle.Size = UDim2.fromOffset(6, 14)

    local detector = Instance.new("TextButton")
    detector.Parent = sliderBg
    detector.BackgroundTransparency = 1
    detector.Position = UDim2.fromOffset(-6, -6)
    detector.Size = UDim2.new(1, 12, 0, 23)
    detector.Text = ""
    detector.AutoButtonColor = false
    detector:SetAttribute("__uiSkipFocus", true)
    detector.Selectable = false

    local value = default
    local dragging = false
    local hovering = false
    local pointer = nil
    local connections = {}
    local function renderGesture()
        frame.BackgroundColor3 = (dragging or hovering) and Theme.ElementHover or Theme.Element
        sliderHandle.BackgroundColor3 = (dragging or hovering) and Theme.Accent or Theme.Text
        frame.BorderColor3 = dragging and Theme.BorderHover or Theme.Border
    end
    local function stopDragging()
        dragging = false
        pointer = nil
        disconnectAll(connections)
        renderGesture()
    end
    detector.MouseEnter:Connect(function() hovering = true; renderGesture() end)
    detector.MouseLeave:Connect(function() hovering = false; renderGesture() end)

    local function render()
        local alpha = (value - min) / (max - min)
        valueLabel.Text = tostring(value)
        sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
        sliderHandle.Position = UDim2.new(alpha, -6 * alpha, 0, -4)
    end

    local function setValue(newValue, noCallback)
        local numberValue = finiteNumber(newValue, min)
        local nextValue = snapValue(numberValue)
        value = nextValue
        render()
        self:_SaveFlag(flag, value)
        if callback and not noCallback then
            dispatchCallback(self, frame, callback, value)
        end
    end

    local skipFocusLost = 0
    local function commitValue()
        local number = finiteNumber(valueLabel.Text, nil)
        if number and snapValue(number) ~= value then setValue(number) else render() end
    end
    local function releaseEditing()
        commitValue()
        if not valueLabel:IsFocused() then return end
        skipFocusLost = skipFocusLost + 1
        valueLabel:ReleaseFocus()
        valueLabel.BackgroundTransparency = 1
    end
    valueLabel.FocusLost:Connect(function()
        if skipFocusLost > 0 then
            skipFocusLost = skipFocusLost - 1
        else
            commitValue()
        end
        valueLabel.BackgroundTransparency = 1
    end)
    valueLabel.Focused:Connect(function()
        valueLabel.BackgroundTransparency = 0
        valueLabel.BackgroundColor3 = Theme.ElementHover
    end)

    local function updateSlider(inputPos)
        if sliderBg.AbsoluteSize.X <= 0 then return end
        local mouseX = inputPos.X
        local relativeX = math.clamp((mouseX - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local rawValue = min + (max - min) * relativeX
        if snapValue(rawValue) ~= value then setValue(rawValue) end
    end

    detector.InputBegan:Connect(function(input)
        if dragging or not isVisible(self.library, detector) then return end
        if not isPointerPress(input) then return end
        dragging = true
        pointer = input
        table.insert(connections, UserInputService.InputChanged:Connect(function(changed)
            if pointer ~= input then return end
            if not isVisible(self.library, detector)
                or changed == input and changed.UserInputState == Enum.UserInputState.Cancel then
                stopDragging()
            elseif changed == input or input.UserInputType == Enum.UserInputType.MouseButton1
                and changed.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(changed.Position)
            end
        end))
        table.insert(connections, UserInputService.InputEnded:Connect(function(ended)
            if ended == pointer then stopDragging() end
        end))
        table.insert(connections, UserInputService.WindowFocusReleased:Connect(stopDragging))
        renderGesture()
        updateSlider(input.Position)
    end)

    render()

    local element = Element.new(self, frame, {
        Type = "Slider",
        Flag = flag,
        OnHide = function()
            hovering = false
            stopDragging()
            releaseEditing()
        end,
        GetValue = function() return value end,
        SetValue = setValue
    })
    self:_BindFlag(flag, element)

    if flag and self.library.loadedFlags[flag] ~= nil and args.CallOnLoad ~= false and callback then
        dispatchCallback(self, frame, callback, value)
    end

    return element
end

function Range:Meter(args)
    args = args or {}
    local text = args.Text or "Meter"
    local min, max = normalizeRange(args.Min, args.Max)
    local default = args.Default
    if default == nil then default = min end
    local format = args.Format or args.ValueFormatter
    local lowColor = args.LowColor or Color3.fromRGB(255, 85, 85)
    local highColor = args.Color or args.HighColor or Theme.Accent

    local frame = createRow(self, "Frame", "Meter", args.Height, 48)

    local label = createLabel(frame, text, args.TextSize)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.Size = UDim2.new(1, -116, 0, 20)

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Parent = frame
    valueLabel.BackgroundTransparency = 1
    valueLabel.Position = UDim2.new(1, -104, 0, 5)
    valueLabel.Size = UDim2.new(0, 96, 0, 20)
    valueLabel.Font = Enum.Font.Code
    valueLabel.TextColor3 = Theme.Accent
    valueLabel.TextSize = args.TextSize or 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local _, meterFill = createTrack(frame, highColor)

    local value = math.clamp(finiteNumber(default, min), min, max)

    local function render()
        local alpha = (value - min) / (max - min)
        if format then
            valueLabel.Text = tostring(format(value, alpha))
        else
            valueLabel.Text = tostring(value)
        end
        meterFill.Size = UDim2.new(alpha, 0, 1, 0)
        meterFill.BackgroundColor3 = lowColor:Lerp(highColor, alpha)
    end

    local function setValue(newValue)
        value = math.clamp(finiteNumber(newValue, min), min, max)
        render()
    end

    render()

    local element = Element.new(self, frame, {
        Type = "Meter",
        GetValue = function() return value end,
        SetValue = setValue
    })

    return element
end

return Range
end function __DARKLUA_BUNDLE_MODULES.i():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.i if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.i=v end return v.c end end do local function __modImpl()
local UserInputService = game:GetService("UserInputService")

local Element = __DARKLUA_BUNDLE_MODULES.g()
local dispatchCallback = Element.dispatchCallback
local Style = __DARKLUA_BUNDLE_MODULES.b()
local Theme = Style.Theme
local INPUT_ROW_HEIGHT = Style.INPUT_ROW_HEIGHT
local createRow = Style.createRow
local createLabel = Style.createLabel
local createInputSurface = Style.createInputSurface
local Input = __DARKLUA_BUNDLE_MODULES.c()
local bindButtonFeedback = Input.bindButtonFeedback
local bindActivation = Input.bindActivation
local isVisible = Input.isVisible
local isPointerPress = Input.isPointerPress
local containsPoint = Input.containsPoint
local focusDirection = Input.focusDirection
local stepFocus = Input.stepFocus
local Util = __DARKLUA_BUNDLE_MODULES.a()
local finiteNumber = Util.finiteNumber
local disconnectAll = Util.disconnectAll

-- Options is an array of strings, finite numbers, or booleans.
return function(self, args)
    args = args or {}
    local text = args.Text or "Dropdown"
    local function normalizeOptions(values)
        assert(type(values) == "table", "Dropdown options must be a table")
        local result, seen = {}, {}
        for _, option in ipairs(values) do
            local kind = type(option)
            assert(kind == "string" or kind == "boolean" or kind == "number" and finiteNumber(option, nil),
                "Dropdown options must be strings, finite numbers, or booleans")
            if not seen[option] then
                seen[option] = true
                table.insert(result, option)
            end
        end
        return result, seen
    end
    local options, optionSet = normalizeOptions(if args.Options == nil then {} else args.Options)
    local multiSelect = args.Multi or false
    local callback = args.Callback
    local flag = args.Flag or args.Save
    local selected = {}
    local selectionOrder = {}

    local function replaceSelection(values)
        if type(values) ~= "table" then values = { values } end
        table.clear(selected)
        table.clear(selectionOrder)
        for _, option in ipairs(values) do
            if optionSet[option] and not selected[option] then
                selected[option] = true
                table.insert(selectionOrder, option)
                if not multiSelect then break end
            end
        end
    end

    replaceSelection(self:_GetSaved(flag, args.Default == nil and {} or args.Default))

    local frame = createRow(self, "Frame", "Dropdown", args.Height, INPUT_ROW_HEIGHT)
    frame.ZIndex = 5

    local label = createLabel(frame, text, args.TextSize)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.Size = UDim2.new(0.42, -18, 1, 0)
    label.ZIndex = 6

    local button = createInputSurface(frame, "TextButton")
    button.Text = ""
    button.AutoButtonColor = false
    button.ZIndex = 6
    local resetFeedback, setActiveFeedback = bindButtonFeedback(button, Theme.Background)

    local selectedLabel = createLabel(button, "", args.TextSize)
    selectedLabel.Position = UDim2.new(0, 6, 0, 0)
    selectedLabel.Size = UDim2.new(1, -26, 1, 0)
    selectedLabel.ZIndex = 7

    local arrow = Instance.new("TextLabel")
    arrow.Parent = button
    arrow.BackgroundTransparency = 1
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position = UDim2.new(1, -6, 0.5, 0)
    arrow.Size = UDim2.new(0, 15, 1, 0)
    arrow.Font = Enum.Font.Code
    arrow.Text = "v"
    arrow.TextColor3 = Theme.TextDim
    arrow.TextSize = 10
    arrow.ZIndex = 7

    local touch = UserInputService.TouchEnabled
    local optionHeight = touch and 44 or 28
    local headerHeight = touch and 52 or 34
    local footerHeight = multiSelect and (touch and 52 or 32) or 0
    local dropdownHeight

    local overlay = Instance.new("Frame")
    overlay.Name = "DropdownOverlay"
    overlay.Parent = self.library.MainFrame
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.Position = UDim2.new(0, 0, 0, 0)
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Visible = false
    overlay.ZIndex = 40

    local outsideButton = Instance.new("TextButton")
    outsideButton.Name = "OutsideClose"
    outsideButton.Parent = overlay
    outsideButton.BackgroundTransparency = 1
    outsideButton.BorderSizePixel = 0
    outsideButton.Position = UDim2.new(0, 0, 0, 0)
    outsideButton.Size = UDim2.new(1, 0, 1, 0)
    outsideButton.Text = ""
    outsideButton.AutoButtonColor = false
    outsideButton.Selectable = false
    outsideButton.ZIndex = 40

    local dropdown = Instance.new("Frame")
    dropdown.Name = "DropdownList"
    dropdown.Parent = overlay
    dropdown.BackgroundColor3 = Theme.Element
    dropdown.BorderColor3 = Theme.BorderHover
    dropdown.BorderSizePixel = 1
    dropdown.AnchorPoint = Vector2.new(0, 0)
    dropdown.Position = UDim2.new(0, 0, 0, 0)
    dropdown.Size = UDim2.fromOffset(0, 0)
    dropdown.Visible = false
    dropdown.Active = true
    dropdown.ClipsDescendants = true
    dropdown.ZIndex = 50

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Parent = dropdown
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.Position = UDim2.new(0, 0, 0, headerHeight)
    scrollFrame.Size = UDim2.new(1, 0, 1, -headerHeight - footerHeight)
    scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scrollFrame.Selectable = false
    scrollFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Theme.BorderHover
    scrollFrame.ClipsDescendants = true
    scrollFrame.ZIndex = 51

    local layout = Instance.new("UIListLayout")
    layout.Parent = scrollFrame
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local search = Instance.new("TextBox")
    search.Name = "Search"
    search.Parent = dropdown
    search.Size = UDim2.new(1, -12, 0, headerHeight - 8)
    search.Position = UDim2.fromOffset(6, 4)
    search.BackgroundColor3 = Theme.Track
    search.BorderColor3 = Theme.Border
    search.BorderSizePixel = 1
    search.Font = Enum.Font.Code
    search.Text = ""
    search.TextSize = 12
    search.TextColor3 = Theme.Text
    search.PlaceholderText = "Search options..."
    search.PlaceholderColor3 = Theme.TextDim
    search.ClearTextOnFocus = false
    search.TextXAlignment = Enum.TextXAlignment.Left
    search.ZIndex = 52
    local searchPadding = Instance.new("UIPadding")
    searchPadding.PaddingLeft = UDim.new(0, 8)
    searchPadding.PaddingRight = UDim.new(0, 8)
    searchPadding.Parent = search
    self.library:_DecorateObject(search)

    local bulkButtons = {}
    local resetBulkFeedback = {}
    if multiSelect then
        for index, caption in ipairs({"All", "Clear"}) do
            local bulk = Instance.new("TextButton")
            bulk.Parent = dropdown
            bulk.Text = caption
            bulk.Font = Enum.Font.Code
            bulk.TextSize = 12
            bulk.TextColor3 = Theme.Text
            bulk.BackgroundColor3 = Theme.Tab
            bulk.BorderColor3 = Theme.Border
            bulk.AutoButtonColor = false
            bulk.Position = UDim2.new((index - 1) * 0.5, index == 1 and 6 or 2, 1, 3 - footerHeight)
            bulk.Size = UDim2.new(0.5, -8, 0, footerHeight - 8)
            bulk.ZIndex = 52
            self.library:_DecorateObject(bulk)
            resetBulkFeedback[index] = bindButtonFeedback(bulk, Theme.Tab)
            bulkButtons[index] = bulk
        end
    end

    local emptyMessage = createLabel(dropdown, "No results", 12)
    emptyMessage.Position = UDim2.new(0, 8, 0, headerHeight)
    emptyMessage.Size = UDim2.new(1, -16, 0, optionHeight)
    emptyMessage.TextColor3 = Theme.TextDim
    emptyMessage.Visible = false
    emptyMessage.ZIndex = 52
    local visibleIndices = {}
    local optionButtons = {}
    local activeIndex = nil
    local hoveredIndex = nil

    local function getSelectedTable()
        return table.clone(selectionOrder)
    end

    local function getValue()
        if multiSelect then return getSelectedTable() end
        return selectionOrder[1]
    end

    local function getSelectedText()
        local list = selectionOrder
        if #list == 0 then
            return #options == 0 and "No options" or "None"
        elseif #list == 1 then
            return tostring(list[1])
        else
            return tostring(list[1]) .. " (+" .. (#list - 1) .. ")"
        end
    end

    local function paintOptionBackground(index)
        local item = optionButtons[index]
        if item then
            item.Button.BackgroundColor3 = index == (hoveredIndex or activeIndex) and Theme.ElementPressed
                or selected[item.Option] and Theme.ElementHover or Theme.Background
        end
    end

    local function setOptionHighlight(active, hovered)
        local previous = hoveredIndex or activeIndex
        activeIndex, hoveredIndex = active, hovered
        local current = hoveredIndex or activeIndex
        if previous ~= current then
            paintOptionBackground(previous)
            paintOptionBackground(current)
        end
    end

    local function repaintOptions()
        for index, item in ipairs(optionButtons) do
            local isSelected = selected[item.Option] == true

            item.Marker.Visible = isSelected
            item.Button.TextColor3 = isSelected and Theme.Accent or Theme.Text
            paintOptionBackground(index)
        end
    end

    local function focusOption(index, keepSelection)
        setOptionHighlight(table.find(visibleIndices, index) and index or visibleIndices[1], nil)
        if not keepSelection and not search:IsFocused() then
            self.library:_SetControlFocus(activeIndex and optionButtons[activeIndex].Button or search)
        end
        if not activeIndex then return end
        local top = (table.find(visibleIndices, activeIndex) - 1) * optionHeight
        local height = math.max(0, dropdown.Size.Y.Offset - headerHeight - footerHeight)
        local canvasY = scrollFrame.CanvasPosition.Y
        if top < canvasY then
            scrollFrame.CanvasPosition = Vector2.new(0, top)
        elseif top + optionHeight > canvasY + height then
            scrollFrame.CanvasPosition = Vector2.new(0, math.max(0, top + optionHeight - height))
        end
    end

    local function renderSelection()
        selectedLabel.Text = getSelectedText()
        selectedLabel.TextColor3 = #selectionOrder > 0 and Theme.Text or Theme.TextDim
        repaintOptions()
    end

    local function updateDisplay(noCallback)
        renderSelection()
        local selection = getSelectedTable()
        -- An empty array preserves an explicitly cleared single selection in JSON.
        local persisted = multiSelect and selection or selection[1]
        self:_SaveFlag(flag, persisted == nil and {} or persisted)
        if callback and not noCallback then
            dispatchCallback(self, frame, callback, getValue())
        end
    end

    local function setSelected(value, noCallback)
        replaceSelection(value)
        updateDisplay(noCallback)
    end

    local isOpen = false
    local placeConnections = {}

    local closeDropdown
    local function placeDropdown()
        local main = self.library.MainFrame
        if not main then return end

        local buttonPos = button.AbsolutePosition
        local buttonSize = button.AbsoluteSize
        local mainPos = main.AbsolutePosition
        local mainSize = main.AbsoluteSize
        local gap = 2
        local contentPos, contentSize = self.content.AbsolutePosition, self.content.AbsoluteSize
        if buttonPos.Y + buttonSize.Y <= contentPos.Y
            or buttonPos.Y >= contentPos.Y + contentSize.Y then
            closeDropdown()
            return
        end

        -- The overlay is a child of MainFrame, which clips descendants. Work in
        -- MainFrame-local coordinates so the decision matches the actual clipping
        -- bounds rather than the top of the screen.
        local x = buttonPos.X - mainPos.X
        local buttonY = buttonPos.Y - mainPos.Y
        local spaceAbove = math.max(0, buttonY - gap)
        local spaceBelow = math.max(0, mainSize.Y - (buttonY + buttonSize.Y) - gap)

        local openAbove
        if dropdownHeight <= spaceBelow then
            openAbove = false
        elseif dropdownHeight <= spaceAbove then
            openAbove = true
        else
            openAbove = spaceAbove > spaceBelow
        end

        -- If neither direction can hold the full list, use the roomier side and
        -- let the existing ScrollingFrame expose the remaining options.
        local availableHeight = openAbove and spaceAbove or spaceBelow
        local visibleHeight = math.min(dropdownHeight, availableHeight)
        local y = openAbove
            and (buttonY - gap - visibleHeight)
            or (buttonY + buttonSize.Y + gap)

        -- Keep the list inside the frame horizontally too, for narrow/resized UIs.
        local visibleWidth = math.min(buttonSize.X, mainSize.X)
        x = math.clamp(x, 0, math.max(0, mainSize.X - visibleWidth))

        dropdown.Size = UDim2.new(0, visibleWidth, 0, visibleHeight)
        dropdown.Position = UDim2.new(0, x, 0, y)
    end

    closeDropdown = function()
        if not isOpen then return end
        isOpen = false
        setOptionHighlight(nil, nil)
        if search:IsFocused() then search:ReleaseFocus() end
        local focused = self.library._focusedControl
        if focused and focused:IsDescendantOf(overlay) then
            self.library:_SetControlFocus(isVisible(self.library, button) and button or nil)
        end
        dropdown.Visible = false
        overlay.Visible = false
        arrow.Text = "v"
        arrow.TextColor3 = Theme.TextDim
        setActiveFeedback(false)
        for _, reset in ipairs(resetBulkFeedback) do reset() end
        disconnectAll(placeConnections)
        if self.library._closeDropdown == closeDropdown then
            self.library._closeDropdown = nil
        end
    end

    local function chooseOption(option)
        if multiSelect then
            local wasSelected = not not selected[option]
            if wasSelected then
                selected[option] = nil
                for idx, value in ipairs(selectionOrder) do
                    if value == option then
                        table.remove(selectionOrder, idx)
                        break
                    end
                end
            else
                selected[option] = true
                table.insert(selectionOrder, option)
            end
        else
            table.clear(selected)
            table.clear(selectionOrder)
            selected[option] = true
            table.insert(selectionOrder, option)
            closeDropdown()
        end
        updateDisplay()
    end

    local function createOptionButton(option, index)
        local optionButton = Instance.new("TextButton")
        optionButton.Name = "Option" .. index
        optionButton.Parent = scrollFrame
        optionButton.BackgroundColor3 = selected[option] and Theme.ElementHover or Theme.Background
        optionButton.BorderSizePixel = 0
        optionButton.Size = UDim2.new(1, 0, 0, optionHeight)
        optionButton.LayoutOrder = index
        optionButton.TextTruncate = Enum.TextTruncate.AtEnd
        optionButton.Font = Enum.Font.Code
        optionButton.Text = " " .. tostring(option)
        optionButton.TextColor3 = selected[option] and Theme.Accent or Theme.Text
        optionButton.TextSize = args.TextSize or 13
        optionButton.TextXAlignment = Enum.TextXAlignment.Left
        optionButton.AutoButtonColor = false
        optionButton.ZIndex = 52
        local marker = Instance.new("Frame")
        marker.Name = "SelectedMark"
        marker.Parent = optionButton
        marker.BackgroundColor3 = Theme.Accent
        marker.BorderSizePixel = 0
        marker.Position = UDim2.new(0, 0, 0, 6)
        marker.Size = UDim2.new(0, 2, 1, -12)
        marker.Visible = selected[option] == true
        table.insert(optionButtons, {
            Option = option,
            Button = optionButton,
            Marker = marker
        })

        self.library:_DecorateObject(optionButton)
        optionButton.MouseEnter:Connect(function()
            setOptionHighlight(activeIndex, index)
        end)
        optionButton.MouseLeave:Connect(function()
            if hoveredIndex == index then setOptionHighlight(activeIndex, nil) end
        end)
        bindActivation(self.library, optionButton, function() chooseOption(option) end)
    end

    local function filterOptions()
        table.clear(visibleIndices)
        local query = string.lower(search.Text)
        for index, item in ipairs(optionButtons) do
            item.Button.Visible = string.find(string.lower(tostring(item.Option)), query, 1, true) ~= nil
            if item.Button.Visible then table.insert(visibleIndices, index) end
        end
        emptyMessage.Visible = #visibleIndices == 0
        emptyMessage.Text = #options == 0 and "No options available" or "No results"
        local totalHeight = #visibleIndices * optionHeight
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
        scrollFrame.CanvasPosition = Vector2.new(0, 0)
        focusOption(activeIndex, true)
    end
    search:GetPropertyChangedSignal("Text"):Connect(function()
        if isOpen then filterOptions() end
    end)
    search.FocusLost:Connect(function(enterPressed)
        if isOpen and enterPressed and activeIndex and optionButtons[activeIndex] then
            chooseOption(optionButtons[activeIndex].Option)
            if isOpen then focusOption(activeIndex) end
        end
    end)
    local function bulkSelect(clear)
        if clear then
            if #selectionOrder > 0 then setSelected({}) end
        else
            for _, option in ipairs(options) do
                if not selected[option] then setSelected(options); break end
            end
        end
    end
    if multiSelect then
        bindActivation(self.library, bulkButtons[1], function() bulkSelect(false) end)
        bindActivation(self.library, bulkButtons[2], function() bulkSelect(true) end)
    end

    local function rebuildOptionButtons()
        local selectedObject = self.library._focusedControl
        local hadOptionFocus = selectedObject and selectedObject:IsDescendantOf(scrollFrame)
        for _, item in ipairs(optionButtons) do
            item.Button:Destroy()
        end
        table.clear(optionButtons)
        activeIndex, hoveredIndex = nil, nil

        for index, option in ipairs(options) do
            createOptionButton(option, index)
        end

        -- Keep the search field stationary while the option list is filtered.
        dropdownHeight = math.min(math.max(#options, 1) * optionHeight, 150) + headerHeight + footerHeight
        if isOpen then placeDropdown() end
        filterOptions()
        if isOpen and hadOptionFocus then focusOption(activeIndex) end
    end

    local function setOptions(newOptions, noCallback)
        local previousSelection = getSelectedTable()
        options, optionSet = normalizeOptions(newOptions)

        replaceSelection(previousSelection)

        rebuildOptionButtons()

        -- Filtering preserves order, so only a shorter selection can have changed.
        local selectionChanged = #previousSelection ~= #selectionOrder

        if selectionChanged then updateDisplay(noCallback) else renderSelection() end
    end

    rebuildOptionButtons()

    outsideButton.Activated:Connect(closeDropdown)

    local function openDropdown(keyboard)
        if isOpen then return end
        if self.library._cancelKeybind then self.library._cancelKeybind() end
        if self.library._closeDropdown then self.library._closeDropdown() end
        self.library._closeDropdown = closeDropdown
        isOpen = true
        search.Text = ""
        filterOptions()
        table.insert(placeConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not isOpen or not isVisible(self.library, dropdown) then return end
            local key = input.KeyCode
            if isPointerPress(input) then
                -- The overlay handles clicks inside the window.
                if not containsPoint(self.library.MainFrame, input.Position) then closeDropdown() end
                return
            end
            local focused = UserInputService:GetFocusedTextBox()
            local selectedObject = self.library._focusedControl
            local hasFocus = selectedObject and selectedObject:IsDescendantOf(dropdown)
                and isVisible(self.library, selectedObject)
            local openedByPointer = self.library._pointerOrigin == button
            if focused and focused ~= search then return end
            if gameProcessed and focused ~= search then return end
            if not focused and not hasFocus and not openedByPointer then return end
            self.library._capturedInput = input
            if key == Enum.KeyCode.Escape and focused == search then
                search:ReleaseFocus()
                focusOption(activeIndex)
                return
            end
            if key == Enum.KeyCode.Escape or key == Enum.KeyCode.ButtonB then closeDropdown(); return end
            if key == Enum.KeyCode.Tab then
                local targets = {search}
                if activeIndex then table.insert(targets, optionButtons[activeIndex].Button) end
                for _, bulk in ipairs(bulkButtons) do table.insert(targets, bulk) end
                stepFocus(self.library, targets, focusDirection(), focused)
                return
            end
            if key == Enum.KeyCode.ButtonSelect and not focused then
                focusOption(activeIndex)
                return
            end
            if multiSelect and hasFocus and not focused and key == Enum.KeyCode.A
                and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
                bulkSelect(UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift))
            elseif key == Enum.KeyCode.Down or key == Enum.KeyCode.DPadDown then
                local index = table.find(visibleIndices, activeIndex) or 0
                focusOption(visibleIndices[math.min(#visibleIndices, index + 1)])
            elseif key == Enum.KeyCode.Up or key == Enum.KeyCode.DPadUp then
                local index = table.find(visibleIndices, activeIndex) or (#visibleIndices + 1)
                focusOption(visibleIndices[math.max(1, index - 1)])
            elseif key == Enum.KeyCode.Home then
                focusOption(visibleIndices[1])
            elseif key == Enum.KeyCode.End then
                focusOption(visibleIndices[#visibleIndices])
            elseif (key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter
                or key == Enum.KeyCode.Space or key == Enum.KeyCode.ButtonA) and hasFocus and not focused then
                if selectedObject == search then
                    search:CaptureFocus()
                elseif table.find(bulkButtons, selectedObject) then
                    bulkSelect(selectedObject == bulkButtons[2])
                elseif activeIndex then
                    chooseOption(optionButtons[activeIndex].Option)
                end
            end
        end))
        placeDropdown()
        if not isOpen then return end
        overlay.Visible = true
        dropdown.Visible = true
        focusOption(table.find(options, selectionOrder[1]) or visibleIndices[1], not keyboard)
        arrow.Text = "^"
        arrow.TextColor3 = Theme.Accent
        setActiveFeedback(true)
        -- keep the list pinned to the button as it moves (scrolling the content,
        -- dragging the window, resizing) instead of leaving it where it opened.
        table.insert(placeConnections, button:GetPropertyChangedSignal("AbsolutePosition"):Connect(placeDropdown))
        table.insert(placeConnections, button:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeDropdown))
        table.insert(placeConnections, self.library.MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeDropdown))
    end

    bindActivation(self.library, button, function()
        if isOpen then
            closeDropdown()
        else
            openDropdown(self.library._focusedControl == button)
        end
    end)

    renderSelection()

    local element = Element.new(self, frame, {
        Type = "Dropdown",
        Flag = flag,
        GetValue = getValue,
        SetValue = setSelected,
        GetOptions = function()
            return table.clone(options)
        end,
        SetOptions = setOptions,
        Cleanup = function()
            overlay:Destroy()
        end,
        OnHide = function()
            closeDropdown()
            resetFeedback()
        end
    })
    self:_BindFlag(flag, element)

    if flag and self.library.loadedFlags[flag] ~= nil and args.CallOnLoad ~= false and callback then
        dispatchCallback(self, frame, callback, getValue())
    end

    return element
end
end function __DARKLUA_BUNDLE_MODULES.j():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.j if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.j=v end return v.c end end do local function __modImpl()
local UserInputService = game:GetService("UserInputService")

local Element = __DARKLUA_BUNDLE_MODULES.g()
local dispatchCallback = Element.dispatchCallback
local Style = __DARKLUA_BUNDLE_MODULES.b()
local Theme = Style.Theme
local INPUT_ROW_HEIGHT = Style.INPUT_ROW_HEIGHT
local createRow = Style.createRow
local createLabel = Style.createLabel
local createInputSurface = Style.createInputSurface
local Input = __DARKLUA_BUNDLE_MODULES.c()
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
end function __DARKLUA_BUNDLE_MODULES.k():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.k if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.k=v end return v.c end end do local function __modImpl()
local Element = __DARKLUA_BUNDLE_MODULES.g()
local dispatchCallback = Element.dispatchCallback
local Style = __DARKLUA_BUNDLE_MODULES.b()
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
end function __DARKLUA_BUNDLE_MODULES.l():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.l if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.l=v end return v.c end end do local function __modImpl()
local Style = __DARKLUA_BUNDLE_MODULES.b()
local Theme = Style.Theme
local ROW_INSET = Style.ROW_INSET
local Input = __DARKLUA_BUNDLE_MODULES.c()
local isVisible = Input.isVisible
local bindButtonFeedback = Input.bindButtonFeedback
local bindActivation = Input.bindActivation
local revealSelection = Input.revealSelection

local Basic = __DARKLUA_BUNDLE_MODULES.h()
local Range = __DARKLUA_BUNDLE_MODULES.i()

local Tab = {}
Tab.__index = Tab

function Tab:_NextLayoutOrder()
    assert(not self.Destroyed and not self.library.Destroyed and not self.library._destroying, "Cannot add controls to a destroyed UI")
    self._layoutOrder = (self._layoutOrder or 0) + 1
    return self._layoutOrder
end

function Tab:_RefreshCanvas()
    if self.Destroyed or self._canvasPending or not self.content or not self.layout then return end
    self._canvasPending = true
    task.defer(function()
        self._canvasPending = false
        if not self.Destroyed and self.content.Parent and self.layout.Parent then
            self.content.CanvasSize = UDim2.new(0, 0, 0, self.layout.AbsoluteContentSize.Y + 20)
        end
    end)
end

function Tab:_FindElement(instance)
    for _, element in ipairs(self.elements) do
        if element.Instance == instance then return element end
    end
end

function Tab:Remove(target)
    target = self:_FindElement(target) or target
    if typeof(target) == "Instance" then
        target:Destroy()
        self:_RefreshCanvas()
        return
    end
    if type(target) == "table" and target.Remove then
        target:Remove()
    end
end

function Tab:Hide(target)
    target = self:_FindElement(target) or target
    if typeof(target) == "Instance" then
        target.Parent = nil
        self:_RefreshCanvas()
        return
    end
    if type(target) == "table" and target.Hide then
        target:Hide()
    end
end

function Tab:Show(target)
    target = self:_FindElement(target) or target
    if type(target) == "table" and target.Show then
        target:Show()
    end
end

function Tab:_BindFlag(flag, element)
    if flag then
        assert(not self.library.elementsByFlag[flag], "Duplicate flag: " .. tostring(flag))
        self.library.elementsByFlag[flag] = element
        self.library:_StoreFlag(flag, element:_GetPersistedValue(), true)
    end
end

function Tab:_GetSaved(flag, default)
    assert(not self.Destroyed and not self.library.Destroyed and not self.library._destroying, "Cannot add controls to a destroyed UI")
    assert(not flag or not self.library.elementsByFlag[flag], "Duplicate flag: " .. tostring(flag))
    if flag and self.library.flags[flag] ~= nil then
        return self.library.flags[flag], true
    end
    return default, false
end

function Tab:_SaveFlag(flag, value)
    if not flag then return end
    self.library:_StoreFlag(flag, value)
end

for _, controls in ipairs({Basic, Range}) do
    for name, constructor in pairs(controls) do Tab[name] = constructor end
end
Tab.Dropdown = __DARKLUA_BUNDLE_MODULES.j()
Tab.Keybind = __DARKLUA_BUNDLE_MODULES.k()
Tab.Textbox = __DARKLUA_BUNDLE_MODULES.l()

function Tab:RemoveTab()
    if self.Destroyed then return end
    self.Destroyed = true
    for index = #self.elements, 1, -1 do self.elements[index]:Remove() end
    if not self._buttonDestroying then self.button:Destroy() end
    if not self._contentDestroying then self.content:Destroy() end
    for i, item in ipairs(self.library.tabs) do
        if item == self then
            table.remove(self.library.tabs, i)
            break
        end
    end
    if self.library.currentTab == self.name then
        local first = self.library.tabs[1]
        if first then
            self.library:SwitchTab(first.name)
        else
            self.library.currentTab = nil
        end
    end
end

function Tab:_RevealButton()
    task.defer(function()
        local button = self.button
        if self.Destroyed or not isVisible(self.library, button) then return end
        revealSelection(self.library.TabContainer, button, "X")
    end)
end

local Tabs = {}

function Tabs:CreateTab(args)
    args = args or {}
    assert(not self.Destroyed and not self._destroying, "Cannot create a tab on a destroyed library")
    local name = args.Name or "Tab"
    for _, existing in ipairs(self.tabs) do
        assert(existing.name ~= name, "Duplicate tab: " .. tostring(name))
    end

    local tab = setmetatable({
        library = self,
        name = name,
        elements = {},
        _layoutOrder = 0
    }, Tab)

    tab.button = Instance.new("TextButton")
    tab.button.Name = name
    tab.button:SetAttribute("__uiChrome", true)
    tab.button.Parent = self.TabContainer
    tab.button.BackgroundColor3 = Theme.Tab
    tab.button.BorderColor3 = Theme.Border
    tab.button.BorderSizePixel = 0
    tab.button.Size = UDim2.new(0, args.Width or 120, 1, -self.TabScrollBarThickness)
    tab.button.Font = Enum.Font.Code
    tab.button.Text = name
    tab.button.TextColor3 = Theme.TextDim
    tab.button.TextSize = args.TextSize or 13
    tab.button.AutoButtonColor = false
    tab.button.TextTruncate = Enum.TextTruncate.AtEnd
    self:_DecorateObject(tab.button)
    tab._resetFeedback, tab._setActiveFeedback = bindButtonFeedback(tab.button, Theme.Tab)
    self._tabOrder = (self._tabOrder or 0) + 1
    tab.button.LayoutOrder = self._tabOrder
    tab.button.ZIndex = 3
    tab.indicator = Instance.new("Frame")
    tab.indicator.Name = "ActiveIndicator"
    tab.indicator.Parent = tab.button
    tab.indicator.BackgroundColor3 = Theme.Accent
    tab.indicator.BorderSizePixel = 0
    tab.indicator.Position = UDim2.new(0, ROW_INSET, 1, -2)
    tab.indicator.Size = UDim2.new(1, -2 * ROW_INSET, 0, 2)
    tab.indicator.Visible = false

    tab.content = Instance.new("ScrollingFrame")
    tab.content.Name = name .. "Content"
    tab.content.Parent = self.ContentArea
    tab.content.BackgroundTransparency = 1
    tab.content.BorderSizePixel = 0
    tab.content.Size = UDim2.new(1, 0, 1, 0)
    tab.content.ScrollingDirection = Enum.ScrollingDirection.Y
    tab.content.Selectable = false
    tab.content.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    tab.content.ScrollBarThickness = 4
    tab.content.ScrollBarImageColor3 = Theme.BorderHover
    tab.content.CanvasSize = UDim2.new(0, 0, 0, 0)
    tab.content.Visible = false
    tab.content.ClipsDescendants = true
    tab.content.ZIndex = 1
    tab.button.Destroying:Connect(function()
        tab._buttonDestroying = true
        tab:RemoveTab()
    end)
    tab.content.Destroying:Connect(function()
        tab._contentDestroying = true
        tab:RemoveTab()
    end)

    local layout = Instance.new("UIListLayout")
    layout.Parent = tab.content
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tab.layout = layout

    local padding = Instance.new("UIPadding")
    padding.Parent = tab.content
    padding.PaddingLeft = UDim.new(0, ROW_INSET)
    padding.PaddingRight = UDim.new(0, ROW_INSET)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tab:_RefreshCanvas()
    end)

    bindActivation(self, tab.button, function()
        self:SwitchTab(name)
    end)

    table.insert(self.tabs, tab)
    if self.BackgroundEnabled then self:_applyChromeTransparency(true, tab.button) end

    if #self.tabs == 1 then
        self:SwitchTab(name)
    end

    return tab
end

function Tabs:SwitchTab(name)
    if self.Destroyed or self._destroying then return false end
    local nextTab
    for _, tab in ipairs(self.tabs) do
        if tab.name == name then nextTab = tab; break end
    end
    if not nextTab then return false end
    if self.currentTab == name then return true end
    self:_CancelInteractions()
    local focused = self._focusedControl
    if focused and focused.Parent == self.TabContainer and focused ~= nextTab.button then
        self:_SetControlFocus(nil)
    end
    local origin = self._pointerOrigin
    if origin and origin.Parent == self.TabContainer and origin ~= nextTab.button then self._pointerOrigin = nil end
    self.currentTab = name
    for _, tab in ipairs(self.tabs) do
        local active = tab == nextTab
        tab.indicator.Visible = active
        tab.content.Visible = active
        tab.button.TextColor3 = active and Theme.Accent or Theme.TextDim
        tab._setActiveFeedback(active)
    end
    nextTab:_RevealButton()
    return true
end

return Tabs
end function __DARKLUA_BUNDLE_MODULES.m():typeof(__modImpl())local v=__DARKLUA_BUNDLE_MODULES.cache.m if not v then v={c=__modImpl()}__DARKLUA_BUNDLE_MODULES.cache.m=v end return v.c end end end-- Edit the source modules here, then rebuild the root main.lua with Darklua.


local UserInputService = game:GetService("UserInputService")

local Style = __DARKLUA_BUNDLE_MODULES.b()
local Theme = Style.Theme
local ROW_INSET = Style.ROW_INSET
local TITLE_HEIGHT = Style.TITLE_HEIGHT
local TAB_HEIGHT = Style.TAB_HEIGHT
local createLabel = Style.createLabel
local Input = __DARKLUA_BUNDLE_MODULES.c()
local bindButtonFeedback = Input.bindButtonFeedback
local isPointerPress = Input.isPointerPress
local isVisible = Input.isVisible
local Util = __DARKLUA_BUNDLE_MODULES.a()
local finiteNumber = Util.finiteNumber
local getEnvFunction = Util.getEnvFunction
local safeCall = Util.safeCall

local UILibrary = {}
UILibrary.__index = UILibrary

for _, methods in ipairs({__DARKLUA_BUNDLE_MODULES.d(), __DARKLUA_BUNDLE_MODULES.e(), __DARKLUA_BUNDLE_MODULES.f(), __DARKLUA_BUNDLE_MODULES.m()}) do
    for name, method in pairs(methods) do UILibrary[name] = method end
end

local DEFAULT_MAX_SIZE = Vector2.new(10000, 10000)

local function normalizeVectorSize(value, fallback)
    fallback = fallback or Vector2.new(0, 0)

    if typeof(value) == "Vector2" then
        return Vector2.new(finiteNumber(value.X, fallback.X), finiteNumber(value.Y, fallback.Y))
    end

    if typeof(value) == "UDim2" then
        return Vector2.new(value.X.Offset, value.Y.Offset)
    end

    if type(value) == "table" then
        local x = value.X or value.x or value.Width or value.width or value[1]
        local y = value.Y or value.y or value.Height or value.height or value[2]
        return Vector2.new(finiteNumber(x, fallback.X), finiteNumber(y, fallback.Y))
    end

    return fallback
end

local function clampVectorSize(size, minSize, maxSize)
    minSize = minSize or Vector2.new(0, 0)
    maxSize = maxSize or DEFAULT_MAX_SIZE

    return Vector2.new(
        math.clamp(size.X, math.max(1, minSize.X), math.max(1, minSize.X, maxSize.X)),
        math.clamp(size.Y, math.max(1, minSize.Y), math.max(1, minSize.Y, maxSize.Y))
    )
end

function UILibrary:_ViewportBounds()
    local viewport = self.ScreenGui.AbsoluteSize
    local width, height = math.max(1, viewport.X), math.max(1, viewport.Y)
    if UserInputService.OnScreenKeyboardVisible then
        local keyboardY = UserInputService.OnScreenKeyboardPosition.Y - self.ScreenGui.AbsolutePosition.Y
        if keyboardY > 0 then height = math.min(height, keyboardY) end
    end
    local margin = math.min(self.ViewportMargin, width * 0.05, height * 0.05)
    local mobile = UserInputService.TouchEnabled and (width < 900 or height < 600)
    local maximum = Vector2.new(
        math.max(1, math.min(width - 2 * margin, width * (mobile and 0.9 or 0.96))),
        math.max(1, math.min(height - 2 * margin, height * (mobile and 0.72 or 0.9)))
    )
    return Vector2.new(width, height), margin, maximum
end

function UILibrary:_FitViewport()
    if self.Destroyed or not self.MainFrame or self.ScreenGui.AbsoluteSize.X <= 0 then return end
    local viewport, margin, cap = self:_ViewportBounds()
    local maximum = Vector2.new(math.min(cap.X, math.max(1, self.MinSize.X, self.MaxSize.X)),
        math.min(cap.Y, math.max(1, self.MinSize.Y, self.MaxSize.Y)))
    local minimum = Vector2.new(math.min(maximum.X, math.max(1, self.MinSize.X)),
        math.min(maximum.Y, math.max(1, self.MinSize.Y)))
    self.SizeConstraint.MinSize = Vector2.new(0, 0)
    self.SizeConstraint.MaxSize = maximum
    self.SizeConstraint.MinSize = minimum
    local requested = self._requestedSize or Vector2.new(600, 400)
    if self._requestedScale then
        local size = self._requestedScale
        requested = Vector2.new(finiteNumber(viewport.X * size.X.Scale + size.X.Offset, requested.X),
            finiteNumber(viewport.Y * size.Y.Scale + size.Y.Offset, requested.Y))
    end
    local size = clampVectorSize(requested, minimum, maximum)
    self.MainFrame.Size = UDim2.new(0, math.floor(size.X), 0, math.floor(size.Y))
    local position = self.MainFrame.Position
    local x = finiteNumber(position.X.Scale * viewport.X + position.X.Offset, margin)
    local y = finiteNumber(position.Y.Scale * viewport.Y + position.Y.Offset, margin)
    self.MainFrame.Position = UDim2.new(0, math.clamp(x, margin, math.max(margin, viewport.X - size.X - margin)),
        0, math.clamp(y, margin, math.max(margin, viewport.Y - size.Y - margin)))
    self:_HideTooltip()
end

function UILibrary:SetSize(width, height)
    if not self.MainFrame or self.Destroyed then return end
    self._requestedScale = typeof(width) == "UDim2" and width or nil
    if not self._requestedScale then
        self._requestedSize = (typeof(width) == "Vector2" or type(width) == "table")
            and normalizeVectorSize(width, self.MainFrame.AbsoluteSize)
            or Vector2.new(finiteNumber(width, self.MainFrame.AbsoluteSize.X), finiteNumber(height, self.MainFrame.AbsoluteSize.Y))
    end
    self:_FitViewport()
end

function UILibrary:GetSize()
    if not self.MainFrame then
        return Vector2.new(0, 0)
    end

    return self.MainFrame.AbsoluteSize
end

function UILibrary:SetResizeBounds(minSize, maxSize)
    self.MinSize = normalizeVectorSize(minSize, self.MinSize)
    self.MaxSize = normalizeVectorSize(maxSize, self.MaxSize)
    self:_FitViewport()
end

function UILibrary:SetResizable(enabled)
    if self.Destroyed then return end
    self.ResizeEnabled = enabled ~= false
    if not self.ResizeEnabled and self._stopGestures then self._stopGestures() end
    if self.ResizeHandle then
        self.ResizeHandle.Visible = self.ResizeEnabled
    end
end

function UILibrary.new(args)
    args = args or {}
    local self = setmetatable({}, UILibrary)

    self.Destroyed = false
    self._connections = {}
    self.flags = {}
    self.loadedFlags = {}
    self.elementsByFlag = {}
    self.ConfigFolder = args.ConfigFolder
    self.AutoSave = args.AutoSave ~= false
    self.TabScrollBarThickness = args.TabScrollBarThickness or 4
    self.TabPadding = args.TabPadding or 0
    self.ResizeEnabled = args.ResizeEnabled ~= false
    self.MinSize = normalizeVectorSize(args.MinSize, Vector2.new(420, 300))
    self.MaxSize = normalizeVectorSize(args.MaxSize, DEFAULT_MAX_SIZE)
    self.ResizeHandleSize = args.ResizeHandleSize or (UserInputService.TouchEnabled and 28 or 16)
    self.ViewportMargin = math.max(8, finiteNumber(args.ViewportMargin, 16))

    if self.ConfigFolder then
        local makefolder = getEnvFunction("makefolder")
        local isfolder = getEnvFunction("isfolder")
        if makefolder then
            local okFolder = true
            if isfolder then
                local ok, exists = safeCall(isfolder, self.ConfigFolder)
                okFolder = ok and exists
            else
                okFolder = false
            end
            if not okFolder then
                safeCall(makefolder, self.ConfigFolder)
            end
        end
    end
    assert(self:SetConfigFile(args.ConfigFile or args.ConfigName or (args.GuiName or "UILibrary") .. ".json"),
        "Invalid config file path; the .bak suffix is reserved")

    if args.AutoLoad ~= false then
        self:LoadConfig(false)
    end

    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = args.GuiName or "UILibrary"
    self.ScreenGui.Parent = args.Parent or (gethui and gethui()) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainFrame"
    self.MainFrame.Parent = self.ScreenGui
    self.MainFrame.BackgroundColor3 = Theme.Background
    self.MainFrame.BorderColor3 = Theme.Border
    self.MainFrame.BorderSizePixel = 1
    self.MainFrame.Position = args.Position or UDim2.new(0, 100, 0, 100)
    self.MainFrame.Size = args.Size or UDim2.new(0, 600, 0, 400)
    self.MainFrame.Visible = true
    self.MainFrame.ClipsDescendants = true
    self.SizeConstraint = Instance.new("UISizeConstraint")
    self.SizeConstraint.Parent = self.MainFrame
    self:SetSize(args.Size or UDim2.new(0, 600, 0, 400))

    -- Sibling ordering keeps each control's children above its own surface.
    -- Explicit window layers keep content above the image and below popups.
    self.BackgroundTransparency = math.clamp(finiteNumber(args.BackgroundTransparency, 0.5), 0, 1)
    self.ElementTransparency = math.clamp(finiteNumber(args.ElementTransparency, 0.3), 0, 1)
    self.BackgroundEnabled = false
    self.BackgroundImage = Instance.new("ImageLabel")
    self.BackgroundImage.Name = "Background"
    self.BackgroundImage.Parent = self.MainFrame
    self.BackgroundImage.BackgroundTransparency = 1
    self.BackgroundImage.BorderSizePixel = 0
    self.BackgroundImage.Position = UDim2.new(0, 0, 0, 0)
    self.BackgroundImage.Size = UDim2.new(1, 0, 1, 0)
    self.BackgroundImage.Image = ""
    self.BackgroundImage.ScaleType = Enum.ScaleType.Stretch
    self.BackgroundImage.ImageTransparency = self.BackgroundTransparency
    self.BackgroundImage.Visible = false
    self.BackgroundImage.ZIndex = 1

    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar:SetAttribute("__uiChrome", true)
    self.TitleBar.Parent = self.MainFrame
    self.TitleBar.BackgroundColor3 = Theme.Tab
    self.TitleBar.BorderColor3 = Theme.Border
    self.TitleBar.BorderSizePixel = 1
    self.TitleBar.Size = UDim2.new(1, 0, 0, TITLE_HEIGHT)
    self.TitleBar.ZIndex = 3

    local titleLabel = createLabel(self.TitleBar, args.Title or "GUI", 15)
    titleLabel.Name = "Title"
    titleLabel.Position = UDim2.fromOffset(ROW_INSET, 0)
    titleLabel.TextColor3 = Theme.Accent
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.ZIndex = 3
    self:_DecorateObject(titleLabel)
    self.SaveIndicator = createLabel(self.TitleBar, "", 11)
    self.SaveIndicator.Position = UDim2.new(1, -96, 0, 0)
    self.SaveIndicator.Size = UDim2.new(0, 86, 1, 0)
    self.SaveIndicator.TextColor3 = Theme.Warning
    self.SaveIndicator.TextXAlignment = Enum.TextXAlignment.Right
    self:_SetSaveStatus(self.SaveStatus or "Ready")

    self.TabContainer = Instance.new("ScrollingFrame")
    self.TabContainer.Name = "TabContainer"
    self.TabContainer:SetAttribute("__uiChrome", true)
    self.TabContainer.Parent = self.MainFrame
    self.TabContainer.BackgroundColor3 = Theme.Tab
    self.TabContainer.BorderColor3 = Theme.Border
    self.TabContainer.BorderSizePixel = 1
    self.TabContainer.Position = UDim2.fromOffset(0, TITLE_HEIGHT)
    self.TabContainer.Size = UDim2.new(1, 0, 0, TAB_HEIGHT)
    self.TabContainer.ClipsDescendants = true
    self.TabContainer.Active = true
    self.TabContainer.Selectable = false
    self.TabContainer.ScrollingDirection = Enum.ScrollingDirection.X
    self.TabContainer.ScrollBarThickness = self.TabScrollBarThickness
    self.TabContainer.ScrollBarImageColor3 = Theme.BorderHover
    self.TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.None
    self.TabContainer.ZIndex = 3

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Parent = self.TabContainer
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, self.TabPadding)

    local function refreshTabCanvas()
        task.defer(function()
            if not self.Destroyed and self.TabContainer.Parent and tabLayout.Parent then
                self.TabContainer.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + self.TabPadding, 0, 0)
            end
        end)
    end

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshTabCanvas)

    self.ContentArea = Instance.new("Frame")
    self.ContentArea.Name = "ContentArea"
    self.ContentArea.Parent = self.MainFrame
    self.ContentArea.BackgroundColor3 = Theme.Background
    self.ContentArea.BorderSizePixel = 0
    self.ContentArea.Position = UDim2.fromOffset(0, TITLE_HEIGHT + TAB_HEIGHT)
    self.ContentArea.Size = UDim2.new(1, 0, 1, -TITLE_HEIGHT - TAB_HEIGHT)
    self.ContentArea.ClipsDescendants = true
    self.ContentArea.ZIndex = 2

    self.ResizeHandle = Instance.new("TextButton")
    self.ResizeHandle.Name = "ResizeHandle"
    self.ResizeHandle.Parent = self.MainFrame
    self.ResizeHandle.BackgroundColor3 = Theme.Element
    self.ResizeHandle.BackgroundTransparency = 0.25
    self.ResizeHandle.BorderSizePixel = 0
    self.ResizeHandle.AnchorPoint = Vector2.new(1, 1)
    self.ResizeHandle.Position = UDim2.new(1, 0, 1, 0)
    self.ResizeHandle.Size = UDim2.new(0, self.ResizeHandleSize, 0, self.ResizeHandleSize)
    self.ResizeHandle.Text = ""
    self.ResizeHandle.AutoButtonColor = false
    self.ResizeHandle.Selectable = false
    self.ResizeHandle.Visible = self.ResizeEnabled
    self.ResizeHandle.ZIndex = 10
    local resetResizeFeedback = bindButtonFeedback(self.ResizeHandle, Theme.Element)
    self.ResizeHandle:GetPropertyChangedSignal("Visible"):Connect(function()
        if not self.ResizeHandle.Visible then resetResizeFeedback() end
    end)

    for _, size in ipairs({UDim2.fromOffset(8, 1), UDim2.fromOffset(1, 8)}) do
        local cornerLine = Instance.new("Frame")
        cornerLine.Name = "CornerMark"
        cornerLine.BackgroundColor3 = Theme.Text
        cornerLine.BorderSizePixel = 0
        cornerLine.AnchorPoint = Vector2.new(1, 1)
        cornerLine.Position = UDim2.new(1, -3, 1, -3)
        cornerLine.Size = size
        cornerLine.ZIndex = 11
        cornerLine.Parent = self.ResizeHandle
    end

    self.tabs = {}
    self.currentTab = nil

    local dragging, resizing = false, false
    local pointer, dragStart, startPos, resizeStart, startSize
    local function stopGestures()
        dragging, resizing = false, false
        pointer = nil
        self.TitleBar.BorderColor3 = Theme.Border
    end
    self._stopGestures = stopGestures
    local function cancelWindowInteractions()
        stopGestures()
        self:_CancelInteractions()
        self._capturedInput = nil
        self:_ClearNavigation()
        for _, tab in ipairs(self.tabs) do tab._resetFeedback() end
        resetResizeFeedback()
    end
    self.MainFrame.InputBegan:Connect(function(input)
        if isPointerPress(input) and isVisible(self, self.MainFrame) then self:_ClaimNavigation() end
    end)
    self.TitleBar.Active = true
    self.TitleBar.InputBegan:Connect(function(input)
        if dragging or resizing or not isPointerPress(input) or not isVisible(self, self.TitleBar) then return end
        for _, tab in ipairs(self.tabs) do
            if tab.name == self.currentTab then self:_SetPointerOrigin(tab.button); break end
        end
        dragging = true
        pointer, dragStart, startPos = input, input.Position, self.MainFrame.Position
        self.TitleBar.BorderColor3 = Theme.BorderHover
    end)
    self.ResizeHandle.InputBegan:Connect(function(input)
        if dragging or resizing or not self.ResizeEnabled or not isPointerPress(input)
            or not isVisible(self, self.ResizeHandle) then return end
        resizing = true
        pointer, resizeStart, startSize = input, input.Position, self.MainFrame.AbsoluteSize
    end)
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if not pointer then return end
        if not isVisible(self, self.MainFrame)
            or input == pointer and input.UserInputState == Enum.UserInputState.Cancel then stopGestures(); return end
        if input ~= pointer and not (pointer.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement) then return end
        if resizing and self.ResizeEnabled then
            local delta = input.Position - resizeStart
            self:SetSize(startSize.X + delta.X, startSize.Y + delta.Y)
        elseif dragging then
            local delta = input.Position - dragStart
            local viewport = self.MainFrame.Parent.AbsoluteSize
            local x = startPos.X.Scale * viewport.X + startPos.X.Offset + delta.X
            local y = startPos.Y.Scale * viewport.Y + startPos.Y.Offset + delta.Y
            self.MainFrame.Position = UDim2.new(0, x, 0, y)
            self:_FitViewport()
        end
    end))
    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if self._capturedInput == input then self._capturedInput = nil end
        if input == pointer then stopGestures() end
    end))
    table.insert(self._connections, UserInputService.WindowFocusReleased:Connect(cancelWindowInteractions))
    local visibilityKey = args.KeyCode or Enum.KeyCode.KeypadZero
    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if self:_HandleInput(input, gameProcessed, visibilityKey) then self._capturedInput = input end
    end))
    self.MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
        if not self.MainFrame.Visible then cancelWindowInteractions() end
    end)
    self.ScreenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
        if not self.ScreenGui.Enabled then cancelWindowInteractions() end
    end)
    self.ScreenGui.Destroying:Connect(function()
        self._screenDestroying = true
        self:Destroy()
    end)
    table.insert(self._connections, self.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        stopGestures()
        self:_FitViewport()
    end))
    for _, property in ipairs({"OnScreenKeyboardVisible", "OnScreenKeyboardPosition"}) do
        table.insert(self._connections, UserInputService:GetPropertyChangedSignal(property):Connect(function() self:_FitViewport() end))
    end
    task.defer(function() if not self.Destroyed then self:_FitViewport() end end)

    local background = args.Background or args.BackgroundImage
    if background then
        self:SetBackground(background, args.BackgroundTransparency)
    end

    return self
end

return UILibrary
