local RESOURCE_NAME = GetCurrentResourceName()

local function getIdentifierByType(source, identifierType)
    local prefix = identifierType .. ':'

    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:sub(1, #prefix) == prefix then
            return identifier
        end
    end

    return nil
end

local function collectHealth()
    local health = {
        resource = RESOURCE_NAME,
        environment = Config.Environment,
        steamOnly = Config.SteamOnly,
        ok = true,
        dependencies = {}
    }

    for _, resourceName in ipairs(Config.RequiredResources) do
        local state = GetResourceState(resourceName)
        health.dependencies[resourceName] = state

        if state ~= 'started' then
            health.ok = false
        end
    end

    return health
end

AddEventHandler('playerConnecting', function(_, _, deferrals)
    if not Config.SteamOnly then
        return
    end

    local playerSource = source
    deferrals.defer()
    Wait(0)

    local steamIdentifier = getIdentifierByType(playerSource, 'steam')
    if not steamIdentifier then
        SPLogger.Log('warn', 'Ligação recusada sem identificador Steam', { source = playerSource })
        deferrals.done(Config.SteamRequiredMessage)
        return
    end

    deferrals.done()
end)

RegisterNetEvent('sp_bootstrap:clientReady', function()
    local playerSource = source
    local player = Player(playerSource)

    if player and player.state then
        player.state:set('spReady', true, true)
    end
end)

RegisterCommand(Config.HealthCommand, function(source)
    local health = collectHealth()
    local level = health.ok and 'info' or 'error'
    SPLogger.Log(level, 'Health check executado', health)

    if source > 0 then
        TriggerClientEvent('chat:addMessage', source, {
            args = {
                'Soul Project',
                health.ok and 'Base operacional.' or 'Foram detetadas dependências em falta.'
            }
        })
    end
end, true)

exports('GetHealth', collectHealth)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= RESOURCE_NAME then
        return
    end

    CreateThread(function()
        Wait(5000)
        local health = collectHealth()
        SPLogger.Log(health.ok and 'info' or 'error', 'Bootstrap inicializado', health)
    end)
end)
