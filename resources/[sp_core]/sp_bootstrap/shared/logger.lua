SPLogger = SPLogger or {}

local validLevels = {
    debug = true,
    info = true,
    warn = true,
    error = true
}

local function encodeContext(context)
    if context == nil then
        return ''
    end

    local ok, encoded = pcall(json.encode, context)
    if not ok then
        return ' context=<erro_de_serializacao>'
    end

    return (' context=%s'):format(encoded)
end

function SPLogger.Log(level, message, context)
    local normalizedLevel = validLevels[level] and level or 'info'
    local prefix = ('[sp_bootstrap][%s][%s]'):format(Config.Environment, normalizedLevel:upper())
    print(('%s %s%s'):format(prefix, tostring(message), encodeContext(context)))
end
