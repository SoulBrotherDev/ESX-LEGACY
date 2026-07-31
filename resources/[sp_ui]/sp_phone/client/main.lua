local ESX = exports['es_extended']:getSharedObject()
local isOpen = false

local function notify(message)
    ESX.ShowNotification(message)
end

local function closePhone()
    if not isOpen then
        return
    end

    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

local function fetchPhoneData(callback)
    ESX.TriggerServerCallback('sp_phone:server:getData', function(result)
        if not result or not result.ok then
            notify(result and result.error or 'Não foi possível carregar o telemóvel.')
            if callback then callback(nil) end
            return
        end
        if callback then callback(result) end
    end)
end

local function openPhone(extraMessage)
    ESX.TriggerServerCallback('sp_phone:server:canOpen', function(allowed)
        if not allowed then
            notify('Não tens um telemóvel.')
            return
        end

        fetchPhoneData(function(data)
            if not data then return end
            isOpen = true
            SetNuiFocus(true, true)
            SendNUIMessage({ action = 'open', data = data })
            if extraMessage then
                SendNUIMessage(extraMessage)
            end
        end)
    end)
end

local function serverCallback(name, nuiCallback, ...)
    ESX.TriggerServerCallback(name, function(result)
        nuiCallback(result or { ok = false, error = 'Sem resposta do servidor.' })
    end, ...)
end

RegisterCommand(Config.Command, function()
    if isOpen then
        closePhone()
    else
        openPhone()
    end
end, false)

RegisterKeyMapping(Config.Command, 'Abrir telemóvel', 'keyboard', Config.DefaultKey)

RegisterNetEvent('sp_phone:client:open', function()
    openPhone()
end)

RegisterNUICallback('close', function(_, cb)
    closePhone()
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    fetchPhoneData(function(data)
        cb(data or { ok = false })
    end)
end)

RegisterNUICallback('sendMessage', function(data, cb)
    serverCallback('sp_phone:server:sendMessage', cb, data.number, data.body)
end)

RegisterNUICallback('addContact', function(data, cb)
    serverCallback('sp_phone:server:addContact', cb, data.name, data.number)
end)

RegisterNUICallback('deleteContact', function(data, cb)
    serverCallback('sp_phone:server:deleteContact', cb, data.id)
end)

RegisterNUICallback('startCall', function(data, cb)
    serverCallback('sp_phone:server:startCall', cb, data.number)
end)

RegisterNUICallback('answerCall', function(_, cb)
    serverCallback('sp_phone:server:answerCall', cb)
end)

RegisterNUICallback('declineCall', function(_, cb)
    serverCallback('sp_phone:server:declineCall', cb)
end)

RegisterNUICallback('hangupCall', function(_, cb)
    serverCallback('sp_phone:server:hangupCall', cb)
end)

RegisterNUICallback('sendService', function(data, cb)
    serverCallback('sp_phone:server:sendService', cb, data.service, data.body)
end)

RegisterNetEvent('sp_phone:client:message', function(message)
    if isOpen then
        SendNUIMessage({ action = 'message', data = message })
    else
        notify(('Nova mensagem de %s'):format(message.sender_number))
    end
end)

RegisterNetEvent('sp_phone:client:incomingCall', function(number)
    openPhone({ action = 'incomingCall', number = number })
end)

RegisterNetEvent('sp_phone:client:outgoingCall', function(number)
    if isOpen then
        SendNUIMessage({ action = 'outgoingCall', number = number })
    end
end)

RegisterNetEvent('sp_phone:client:callConnected', function(number)
    if isOpen then
        SendNUIMessage({ action = 'callConnected', number = number })
    end
    notify(('Chamada ligada com %s.'):format(number))
end)

RegisterNetEvent('sp_phone:client:callEnded', function(status)
    if isOpen then
        SendNUIMessage({ action = 'callEnded', status = status })
    end
end)

RegisterNetEvent('sp_phone:client:serviceDispatch', function(dispatch)
    notify(('[%s] %s: %s'):format(dispatch.label, dispatch.sender, dispatch.message))
    if isOpen then
        SendNUIMessage({ action = 'serviceDispatch', data = dispatch })
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SetNuiFocus(false, false)
    end
end)
