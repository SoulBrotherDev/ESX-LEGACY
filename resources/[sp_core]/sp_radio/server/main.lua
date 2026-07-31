local ESX = exports['es_extended']:getSharedObject()
local registeredChannels = {}

local function getRestrictedRange(channel)
    for i = 1, #Config.RestrictedRanges do
        local range = Config.RestrictedRanges[i]
        if channel >= range.min and channel <= range.max then
            return range
        end
    end
end

local function hasRadio(xPlayer)
    if not Config.ItemRequired then
        return true
    end

    local item = xPlayer.getInventoryItem(Config.ItemName)
    return item and (item.count or 0) > 0
end

local function canAccess(source, channel)
    channel = tonumber(channel)
    if not channel or channel < Config.MinimumChannel or channel > Config.MaximumChannel then
        return false, Config.Messages.invalid
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return false, Config.Messages.denied
    end

    if not hasRadio(xPlayer) then
        return false, Config.Messages.noItem
    end

    local range = getRestrictedRange(channel)
    local jobName = xPlayer.job and xPlayer.job.name or 'unemployed'
    if range and not range.jobs[jobName] then
        return false, Config.Messages.denied
    end

    return true
end

ESX.RegisterServerCallback('sp_radio:server:canAccess', function(source, cb, channel)
    local allowed, reason = canAccess(source, channel)
    cb(allowed, reason)
end)

ESX.RegisterUsableItem(Config.ItemName, function(source)
    TriggerClientEvent('sp_radio:client:open', source)
end)

RegisterNetEvent('sp_radio:server:revalidate', function(channel)
    local source = source
    local allowed, reason = canAccess(source, channel)
    if not allowed then
        TriggerClientEvent('sp_radio:client:forceLeave', source, reason)
    end
end)

local function registerPmaChecks()
    while GetResourceState('pma-voice') ~= 'started' do
        Wait(500)
    end

    for channel = Config.MinimumChannel, Config.MaximumChannel do
        if getRestrictedRange(channel) then
            local currentChannel = channel
            local ok = pcall(function()
                exports['pma-voice']:addChannelCheck(currentChannel, function(source)
                    local allowed = canAccess(source, currentChannel)
                    return allowed == true
                end)
            end)

            if ok then
                registeredChannels[#registeredChannels + 1] = currentChannel
            end
        end
    end
end

CreateThread(registerPmaChecks)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() or GetResourceState('pma-voice') ~= 'started' then
        return
    end

    for i = 1, #registeredChannels do
        pcall(function()
            exports['pma-voice']:removeChannelCheck(registeredChannels[i])
        end)
    end
end)

exports('CanAccessChannel', canAccess)
