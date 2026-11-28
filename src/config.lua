local HttpService = game:GetService("HttpService")

local Util = require("./util")
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
