local Color3 = {fromRGB = function() return {} end}
local Vector2 = {new = function(x, y) return {X = x, Y = y} end}
local TweenInfo = {new = function() return {} end}
local files, encoded, timers = {}, {}, {}
local env = {
    isfile = function(path) return files[path] ~= nil end,
    readfile = function(path) return assert(files[path]) end,
    writefile = function(path, bytes) files[path] = bytes end,
}
local function getgenv() return env end
local http = {}
function http:JSONEncode(flags)
    table.insert(encoded, table.clone(flags))
    return tostring(#encoded)
end
function http:JSONDecode(bytes) return table.clone(assert(encoded[tonumber(bytes)])) end
local game = {GetService = function(_, name) return name == "HttpService" and http or {} end}
local lastWarning, lastWorker
local function warn(message) lastWarning = message end
local task = {
    wait = coroutine.yield,
    spawn = function(fn)
        lastWorker = coroutine.create(fn)
        assert(coroutine.resume(lastWorker))
        return lastWorker
    end,
    delay = function(_, fn) timers[fn] = true; return fn end,
    cancel = function(fn) timers[fn] = nil end,
}
local function loadLibrary()
    -- INSERT LIBRARY HERE
end
local UI = loadLibrary()
local function newLibrary(path, module)
    local lib = setmetatable({AutoSave = true, flags = {}, elementsByFlag = {}, _connections = {}}, module or UI)
    assert(lib:SetConfigFile(path))
    return lib
end
local function runTimers()
    for fn in pairs(table.clone(timers)) do
        timers[fn] = nil
        fn()
    end
end

local original = http:JSONEncode({Speed = 87})
files.existing = original
local readfile = env.readfile
env.readfile = function() error("temporary read failure") end
local lib = newLibrary("existing")
assert(not lib:LoadConfig())
lib:SetFlag("Speed", 16)
runTimers()
assert(files.existing == original and lib.SaveStatus == "LoadFailed")
lib:Destroy()
assert(files.existing == original and files["existing.bak"] == nil)

env.readfile = readfile
lib = newLibrary("fresh")
assert(not lib:LoadConfig())
lib:SetFlag("Speed", 16)
runTimers()
assert(http:JSONDecode(files.fresh).Speed == 16)

local unopened = http:JSONEncode({Audio = true, Volume = 2})
files.unopened = unopened
lib = newLibrary("unopened")
lib:SetFlag("Volume", 8)
runTimers()
local updated = http:JSONDecode(files.unopened)
assert(updated.Audio and updated.Volume == 8)
assert(files["unopened.bak"] == unopened)

local external = http:JSONEncode({Audio = false, Volume = 8, Theme = "dark"})
files.unopened = external
lib:SetFlag("Volume", 10)
runTimers()
updated = http:JSONDecode(files.unopened)
assert(updated.Audio == false and updated.Volume == 10 and updated.Theme == "dark")
assert(files["unopened.bak"] == external)

local recovered = http:JSONEncode({Audio = true})
files.unopenedBackup = "invalid"
files["unopenedBackup.bak"] = recovered
lib = newLibrary("unopenedBackup")
lib:SetFlag("Volume", 3)
runTimers()
updated = http:JSONDecode(files.unopenedBackup)
assert(updated.Audio and updated.Volume == 3)
assert(files["unopenedBackup.bak"] == recovered)

files.unopenedBackup = "invalid"
local repairWrite = env.writefile
env.writefile = function(path, bytes)
    if path == "unopenedBackup.bak" then
        files[path] = ""
        error("backup write failed after truncation")
    end
    if path == "unopenedBackup" then error("primary write failed") end
    repairWrite(path, bytes)
end
lib:SetFlag("Volume", 4)
assert(not lib:SaveConfig())
assert(files["unopenedBackup.bak"] == recovered)
env.writefile = repairWrite
assert(lib:SaveConfig())
assert(http:JSONDecode(files.unopenedBackup).Volume == 4)

files.unopenedInvalid = "invalid"
lib = newLibrary("unopenedInvalid")
lib:SetFlag("Speed", 32)
runTimers()
assert(files.unopenedInvalid == "invalid" and lib.SaveStatus == "LoadFailed")

files.invalid = "invalid"
lib = newLibrary("invalid")
assert(not lib:LoadConfig())
lib:SetFlag("Speed", 32)
runTimers()
assert(files.invalid == "invalid")
assert(lib:SaveConfig()) -- An explicit save can replace the invalid file.
lib:SetFlag("Speed", 48)
runTimers()
assert(http:JSONDecode(files.invalid).Speed == 48)

local first = newLibrary("shared")
local second = newLibrary("profiles//.././shared", loadLibrary())
assert(first.ConfigPath == second.ConfigPath)
assert(not second:SetConfigFile("./shared.BAK"))
assert(second.ConfigPath == "shared")
first:SetFlag("Audio", true)
second:SetFlag("Volume", 2)
local writefile = env.writefile
env.writefile = function(path, bytes)
    if path == "shared" then coroutine.yield("writing") end
    writefile(path, bytes)
end
local a = coroutine.create(function() assert(first:SaveConfig()) end)
local b = coroutine.create(function() assert(second:SaveConfig()) end)
assert(coroutine.resume(a) and coroutine.status(a) == "suspended")
local writer = lastWorker
assert(coroutine.resume(b) and coroutine.status(b) == "suspended")
local waiter = lastWorker
assert(coroutine.resume(writer) and coroutine.status(writer) == "dead")
assert(coroutine.resume(a) and coroutine.status(a) == "dead")
assert(select(2, coroutine.resume(waiter)) == "writing")
assert(coroutine.resume(waiter) and coroutine.status(waiter) == "dead")
assert(coroutine.resume(b) and coroutine.status(b) == "dead")
env.writefile = writefile
local merged = http:JSONDecode(files.shared)
assert(merged.Audio and merged.Volume == 2)
assert(http:JSONDecode(files["shared.bak"]).Audio)

assert(second:LoadConfig())
first:SetFlag("Audio", false)
assert(first:SaveConfig())
second:SetFlag("Volume", nil)
assert(second:SaveConfig())
merged = http:JSONDecode(files.shared)
assert(merged.Audio == false and merged.Volume == nil)

first = newLibrary("defaults")
second = newLibrary("defaults", loadLibrary())
assert(not first:LoadConfig() and not second:LoadConfig())
first:_StoreFlag("Audio", false, true)
second:_StoreFlag("Audio", false, true)
second:_StoreFlag("Hints", true, true)
first:SetFlag("Audio", true)
assert(first:SaveConfig())
second:SetFlag("Volume", 5)
assert(second:SaveConfig())
merged = http:JSONDecode(files.defaults)
assert(merged.Audio == true and merged.Hints == true and merged.Volume == 5)
second:SetFlag("Audio", false)
assert(second:SaveConfig() and http:JSONDecode(files.defaults).Audio == false)

files.destination = http:JSONEncode({Audio = true, Volume = false, Other = 7})
assert(second:SetConfigFile("destination"))
second:SetFlag("Volume", 6)
assert(second:SaveConfig())
merged = http:JSONDecode(files.destination)
assert(merged.Audio == true and merged.Hints == true and merged.Volume == 6 and merged.Other == 7)
assert(http:JSONDecode(files.defaults).Volume == 5)

second:SetFlag("Volume", 8)
env.writefile = function(path, bytes)
    if path == "destination" then coroutine.yield("writing") end
    writefile(path, bytes)
end
a = coroutine.create(function() assert(second:SaveConfig()) end)
assert(coroutine.resume(a) and coroutine.status(a) == "suspended")
writer = lastWorker
second:SetFlag("Volume", 9)
second:SetFlag("Other", nil)
assert(coroutine.resume(writer) and coroutine.status(writer) == "dead")
assert(coroutine.resume(a) and coroutine.status(a) == "dead")
assert(http:JSONDecode(files.destination).Volume == 8)
env.writefile = writefile
runTimers()
merged = http:JSONDecode(files.destination)
assert(merged.Volume == 9 and merged.Other == nil)

first = newLibrary("cancelled")
second = newLibrary("cancelled", loadLibrary())
first:SetFlag("Original", true)
env.writefile = function(path, bytes)
    if path == "cancelled" then coroutine.yield("writing") end
    writefile(path, bytes)
end
a = coroutine.create(function() first:SaveConfig() end)
assert(coroutine.resume(a) and coroutine.status(a) == "suspended")
writer = lastWorker
assert(coroutine.close(a))
env.writefile = writefile
second:SetFlag("Next", true)
b = coroutine.create(function() assert(second:SaveConfig()) end)
assert(coroutine.resume(b) and coroutine.status(b) == "suspended")
waiter = lastWorker
assert(coroutine.resume(writer) and coroutine.status(writer) == "dead")
assert(coroutine.resume(waiter) and coroutine.status(waiter) == "dead")
assert(coroutine.resume(b) and coroutine.status(b) == "dead")
merged = http:JSONDecode(files.cancelled)
assert(merged.Original and merged.Next and first._configBusy == nil)

env.readfile = function(path)
    if path == "cancelled" then coroutine.yield("reading") end
    return readfile(path)
end
a = coroutine.create(function() first:LoadConfig() end)
assert(coroutine.resume(a) and coroutine.status(a) == "suspended")
local reader = lastWorker
assert(coroutine.close(a))
assert(coroutine.resume(reader) and coroutine.status(reader) == "dead")
env.readfile = readfile
assert(first._configBusy == nil and second:LoadConfig())

lib = newLibrary("destroy-flush")
lib:SetFlag("Final", 1)
env.writefile = function(path, bytes)
    if path == "destroy-flush" then coroutine.yield("writing") end
    writefile(path, bytes)
end
a = coroutine.create(function() lib:Destroy() end)
assert(coroutine.resume(a) and coroutine.status(a) == "suspended")
writer = lastWorker
assert(coroutine.close(a))
assert(coroutine.resume(writer) and coroutine.status(writer) == "dead")
assert(lib.Destroyed and http:JSONDecode(files["destroy-flush"]).Final == 1)
env.writefile = writefile

local isfile = env.isfile
env.isfile = nil
lib = newLibrary("unknown")
assert(not lib:LoadConfig() and lib.SaveStatus == "FileCheckUnavailable")
lib:SetFlag("Volume", 1)
assert(not lib:SaveConfig() and files.unknown == nil)
assert(lastWarning:find("isfile", 1, true))
assert(lib:SetConfigFile("destination") and lib:LoadConfig())
lib:SetFlag("Volume", 7)
assert(lib:SaveConfig() and http:JSONDecode(files.destination).Volume == 7)
env.isfile = isfile

print("Config regression checks passed")
