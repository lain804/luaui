local Color3 = {fromRGB = function() return {} end}
local Vector2 = {new = function(x, y) return {X = x, Y = y} end}
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
local task = {
    wait = coroutine.yield,
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
local second = newLibrary("shared", loadLibrary())
first:SetFlag("Audio", true)
second:SetFlag("Volume", 2)
local writefile = env.writefile
env.writefile = function(path, bytes)
    if path == "shared" then coroutine.yield("writing") end
    writefile(path, bytes)
end
local a = coroutine.create(function() assert(first:SaveConfig()) end)
local b = coroutine.create(function() assert(second:SaveConfig()) end)
assert(select(2, coroutine.resume(a)) == "writing")
assert(coroutine.resume(b) and coroutine.status(b) == "suspended")
assert(coroutine.resume(a) and coroutine.status(a) == "dead")
assert(select(2, coroutine.resume(b)) == "writing")
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

print("Config regression checks passed")
