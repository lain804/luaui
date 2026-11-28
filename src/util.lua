local function finiteNumber(value, fallback)
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
