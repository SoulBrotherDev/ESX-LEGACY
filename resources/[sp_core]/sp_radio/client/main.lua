local ESX = exports['es_extended']:getSharedObject()
local currentChannel = 0

local function notify(message)
    ESX.ShowNotification(message)
end

local function keyboardInput(title, defaultText, maxLength)
    AddTextEntry('SP_RADIO_INPUT', title)
    DisplayOnscreenKeyboard(1, 'SP_RADIO_INPUT', '', defaultText or '', '', '', '', maxLength or 6)

    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end

    if UpdateOnscreenKeyboard() == 1 then
        return GetOnscreenKeyboardResult()
    end
end

local function leaveRadio(message)
    exports['pma-voice']:setRadioChannel(0)
    currentChannel = 0
    LocalPlayer.state:set('spRadioChannel', 0, true)
    notify(message or Config.Messages.left)
end

local function joinRadio(channel)
    channel = math.floor(tonumber(channel) or 0)
    if channel < Config.MinimumChannel or channel > Config.MaximumChannel then
        notify(Config.Messages.invalid)
        return
    end

    ESX.TriggerServerCallback('sp_radio:server:canAccess', function(allowed, reason)
        if not allowed then
            notify(reason or Config.Messages.denied)
            return
        end

        exports['pma-voice']:setRadioChannel(channel)
        currentChannel = channel
        LocalPlayer.state:set('spRadioChannel', channel, true)
        notify(Config.Messages.joined:format(channel))
    end, channel)
end

local function openRadioInput()
    local value = keyboardInput('Frequência do rádio', currentChannel > 0 and tostring(currentChannel) or '', 6)
    if value and value ~= '' then
        joinRadio(value)
    end
end

RegisterCommand(Config.Command, function(_, args)
    if args[1] then
        joinRadio(args[1])
    else
        openRadioInput()
    end
end, false)

RegisterKeyMapping(Config.Command, 'Abrir rádio', 'keyboard', Config.DefaultKey)

RegisterCommand(Config.LeaveCommand, function()
    leaveRadio()
end, false)

RegisterCommand(Config.VolumeCommand, function(_, args)
    local volume = math.floor(tonumber(args[1]) or -1)
    if volume < 1 or volume > 100 then
        notify('Usa /' .. Config.VolumeCommand .. ' 1-100.')
        return
    end

    exports['pma-voice']:setRadioVolume(volume)
    notify(Config.Messages.volume:format(volume))
end, false)

RegisterNetEvent('sp_radio:client:open', openRadioInput)

RegisterNetEvent('sp_radio:client:forceLeave', function(reason)
    if currentChannel > 0 then
        leaveRadio(reason)
    end
end)

RegisterNetEvent('esx:setJob', function()
    if currentChannel > 0 then
        TriggerServerEvent('sp_radio:server:revalidate', currentChannel)
    end
end)

CreateThread(function()
    while true do
        Wait(Config.RevalidateSeconds * 1000)
        if currentChannel > 0 then
            TriggerServerEvent('sp_radio:server:revalidate', currentChannel)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and currentChannel > 0 then
        exports['pma-voice']:setRadioChannel(0)
    end
end)

exports('JoinChannel', joinRadio)
exports('LeaveChannel', leaveRadio)
exports('GetChannel', function()
    return currentChannel
end)
