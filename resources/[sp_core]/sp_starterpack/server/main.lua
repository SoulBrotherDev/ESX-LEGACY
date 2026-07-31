local ESX = exports['es_extended']:getSharedObject()
local processing = {}

local function getIdentifier(xPlayer)
    if xPlayer.getIdentifier then
        return xPlayer.getIdentifier()
    end
    return xPlayer.identifier
end

local function grantStarterPack(source, xPlayer)
    if not Config.Enabled or processing[source] then
        return
    end

    xPlayer = xPlayer or ESX.GetPlayerFromId(source)
    if not xPlayer then
        return
    end

    processing[source] = true
    local identifier = getIdentifier(xPlayer)
    local payload = json.encode(Config.Items)

    local affected = MySQL.update.await(
        'INSERT IGNORE INTO sp_starter_claims (identifier, payload) VALUES (?, ?)',
        { identifier, payload }
    )

    if affected and affected > 0 then
        for i = 1, #Config.Items do
            local entry = Config.Items[i]
            local ok, err = pcall(function()
                xPlayer.addInventoryItem(entry.name, entry.count)
            end)

            if not ok then
                print(('[sp_starterpack] Não foi possível entregar %s: %s'):format(entry.name, err))
            end
        end

        TriggerClientEvent('esx:showNotification', source, Config.Notification)
    end

    processing[source] = nil
end

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    CreateThread(function()
        Wait(1500)
        grantStarterPack(playerId, xPlayer)
    end)
end)

CreateThread(function()
    Wait(2000)
    local players = ESX.GetExtendedPlayers()
    for i = 1, #players do
        grantStarterPack(players[i].source, players[i])
    end
end)

exports('GrantStarterPack', grantStarterPack)
