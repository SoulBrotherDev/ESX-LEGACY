local ESX = exports['es_extended']:getSharedObject()
local sourceByNumber = {}
local numberBySource = {}
local callsBySource = {}
local messageRate = {}
local nextCallChannel = Config.CallChannelBase

math.randomseed(os.time())

local function getIdentifier(xPlayer)
    if xPlayer.getIdentifier then
        return xPlayer.getIdentifier()
    end
    return xPlayer.identifier
end

local function hasPhone(xPlayer)
    if not Config.ItemRequired then
        return true
    end
    local item = xPlayer.getInventoryItem(Config.ItemName)
    return item and (item.count or 0) > 0
end

local function cleanNumber(value)
    return tostring(value or ''):gsub('[^%d%-]', ''):sub(1, 20)
end

local function cleanText(value)
    local text = tostring(value or ''):gsub('%c', ' ')
    text = text:match('^%s*(.-)%s*$') or ''
    return text:sub(1, Config.MaximumMessageLength)
end

local function generatePhoneNumber()
    local maximum = (10 ^ Config.NumberDigits) - 1
    local suffix = math.random(0, maximum)
    return ('%s%0' .. Config.NumberDigits .. 'd'):format(Config.NumberPrefix, suffix)
end

local function ensurePhoneNumber(source, xPlayer)
    xPlayer = xPlayer or ESX.GetPlayerFromId(source)
    if not xPlayer then
        return nil
    end

    local identifier = getIdentifier(xPlayer)
    local number = MySQL.scalar.await('SELECT phone_number FROM sp_phone_numbers WHERE identifier = ?', { identifier })

    if not number then
        for _ = 1, 40 do
            local candidate = generatePhoneNumber()
            local exists = MySQL.scalar.await('SELECT 1 FROM sp_phone_numbers WHERE phone_number = ?', { candidate })
            if not exists then
                local inserted = MySQL.update.await(
                    'INSERT IGNORE INTO sp_phone_numbers (identifier, phone_number) VALUES (?, ?)',
                    { identifier, candidate }
                )
                if inserted and inserted > 0 then
                    number = candidate
                    break
                end
            end
        end
    end

    if number then
        numberBySource[source] = number
        sourceByNumber[number] = source
    end

    return number
end

local function serviceSnapshot()
    local counts = {}
    for key in pairs(Config.Services) do
        counts[key] = 0
    end

    local players = ESX.GetExtendedPlayers()
    for i = 1, #players do
        local jobName = players[i].job and players[i].job.name
        for key, service in pairs(Config.Services) do
            if jobName == service.job then
                counts[key] = counts[key] + 1
            end
        end
    end

    local services = {}
    for key, service in pairs(Config.Services) do
        services[#services + 1] = {
            key = key,
            label = service.label,
            number = service.number,
            online = counts[key]
        }
    end
    table.sort(services, function(a, b) return a.label < b.label end)
    return services
end

local function setPlayerCall(source, channel)
    if GetResourceState('pma-voice') ~= 'started' then
        return false
    end

    return pcall(function()
        exports['pma-voice']:setPlayerCall(source, channel)
    end)
end

local function finishCall(call, status)
    if not call or call.finished then
        return
    end

    call.finished = true
    local duration = 0
    if call.connectedAt then
        duration = math.max(0, os.time() - call.connectedAt)
    end

    setPlayerCall(call.caller, 0)
    setPlayerCall(call.receiver, 0)

    TriggerClientEvent('sp_phone:client:callEnded', call.caller, status)
    TriggerClientEvent('sp_phone:client:callEnded', call.receiver, status)

    callsBySource[call.caller] = nil
    callsBySource[call.receiver] = nil

    MySQL.insert.await([[
        INSERT INTO sp_phone_calls (caller_number, receiver_number, status, duration_seconds)
        VALUES (?, ?, ?, ?)
    ]], { call.callerNumber, call.receiverNumber, status, duration })
end

local function callbackError(cb, message)
    cb({ ok = false, error = message })
end

ESX.RegisterServerCallback('sp_phone:server:canOpen', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(xPlayer ~= nil and hasPhone(xPlayer))
end)

ESX.RegisterServerCallback('sp_phone:server:getData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not hasPhone(xPlayer) then
        return callbackError(cb, 'Não tens um telemóvel.')
    end

    local identifier = getIdentifier(xPlayer)
    local number = ensurePhoneNumber(source, xPlayer)
    if not number then
        return callbackError(cb, 'Não foi possível atribuir um número.')
    end

    local contacts = MySQL.query.await([[
        SELECT id, display_name, phone_number
        FROM sp_phone_contacts
        WHERE owner_identifier = ?
        ORDER BY display_name ASC
    ]], { identifier })

    local messages = MySQL.query.await([[
        SELECT id, sender_number, receiver_number, body, created_at, read_at
        FROM sp_phone_messages
        WHERE sender_number = ? OR receiver_number = ?
        ORDER BY id DESC
        LIMIT ?
    ]], { number, number, Config.HistoryLimit })

    local calls = MySQL.query.await([[
        SELECT id, caller_number, receiver_number, status, duration_seconds, created_at
        FROM sp_phone_calls
        WHERE caller_number = ? OR receiver_number = ?
        ORDER BY id DESC
        LIMIT 30
    ]], { number, number })

    MySQL.update.await(
        'UPDATE sp_phone_messages SET read_at = CURRENT_TIMESTAMP WHERE receiver_number = ? AND read_at IS NULL',
        { number }
    )

    cb({
        ok = true,
        number = number,
        contacts = contacts,
        messages = messages,
        calls = calls,
        services = serviceSnapshot()
    })
end)

ESX.RegisterServerCallback('sp_phone:server:sendMessage', function(source, cb, targetNumber, body)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not hasPhone(xPlayer) then
        return callbackError(cb, 'Não tens um telemóvel.')
    end

    local now = GetGameTimer()
    if messageRate[source] and now - messageRate[source] < Config.MessageCooldownMs then
        return callbackError(cb, 'Estás a enviar mensagens demasiado depressa.')
    end
    messageRate[source] = now

    local senderNumber = ensurePhoneNumber(source, xPlayer)
    targetNumber = cleanNumber(targetNumber)
    body = cleanText(body)

    if targetNumber == '' or body == '' then
        return callbackError(cb, 'Número ou mensagem inválida.')
    end

    if targetNumber == senderNumber then
        return callbackError(cb, 'Não podes enviar mensagens para ti próprio.')
    end

    local targetExists = MySQL.scalar.await('SELECT 1 FROM sp_phone_numbers WHERE phone_number = ?', { targetNumber })
    if not targetExists then
        return callbackError(cb, 'Esse número não existe.')
    end

    local messageId = MySQL.insert.await([[
        INSERT INTO sp_phone_messages (sender_number, receiver_number, body)
        VALUES (?, ?, ?)
    ]], { senderNumber, targetNumber, body })

    local targetSource = sourceByNumber[targetNumber]
    if targetSource then
        TriggerClientEvent('sp_phone:client:message', targetSource, {
            id = messageId,
            sender_number = senderNumber,
            receiver_number = targetNumber,
            body = body
        })
    end

    cb({ ok = true, id = messageId })
end)

ESX.RegisterServerCallback('sp_phone:server:addContact', function(source, cb, displayName, phoneNumber)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not hasPhone(xPlayer) then
        return callbackError(cb, 'Não tens um telemóvel.')
    end

    displayName = cleanText(displayName):sub(1, 64)
    phoneNumber = cleanNumber(phoneNumber)
    if displayName == '' or phoneNumber == '' then
        return callbackError(cb, 'Contacto inválido.')
    end

    local identifier = getIdentifier(xPlayer)
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM sp_phone_contacts WHERE owner_identifier = ?', { identifier }) or 0
    if tonumber(count) >= Config.MaximumContacts then
        return callbackError(cb, 'A lista de contactos está cheia.')
    end

    MySQL.update.await([[
        INSERT INTO sp_phone_contacts (owner_identifier, display_name, phone_number)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE display_name = VALUES(display_name)
    ]], { identifier, displayName, phoneNumber })

    cb({ ok = true })
end)

ESX.RegisterServerCallback('sp_phone:server:deleteContact', function(source, cb, contactId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not hasPhone(xPlayer) then
        return callbackError(cb, 'Não tens um telemóvel.')
    end

    MySQL.update.await(
        'DELETE FROM sp_phone_contacts WHERE id = ? AND owner_identifier = ?',
        { tonumber(contactId) or 0, getIdentifier(xPlayer) }
    )
    cb({ ok = true })
end)

ESX.RegisterServerCallback('sp_phone:server:sendService', function(source, cb, serviceKey, body)
    local xPlayer = ESX.GetPlayerFromId(source)
    local service = Config.Services[tostring(serviceKey or '')]
    if not service then
        return callbackError(cb, 'Serviço inválido.')
    end
    if not xPlayer or not hasPhone(xPlayer) then
        return callbackError(cb, 'Não tens um telemóvel.')
    end

    body = cleanText(body)
    if body == '' then
        return callbackError(cb, 'Escreve uma descrição do pedido.')
    end

    local number = ensurePhoneNumber(source, xPlayer)
    local ped = GetPlayerPed(source)
    local coords = ped > 0 and GetEntityCoords(ped) or vector3(0.0, 0.0, 0.0)
    local encodedCoords = json.encode({ x = coords.x, y = coords.y, z = coords.z })

    local requestId = MySQL.insert.await([[
        INSERT INTO sp_phone_service_messages
            (service, sender_identifier, sender_number, message, coords)
        VALUES (?, ?, ?, ?, ?)
    ]], { serviceKey, getIdentifier(xPlayer), number, body, encodedCoords })

    local players = ESX.GetExtendedPlayers()
    for i = 1, #players do
        if players[i].job and players[i].job.name == service.job then
            TriggerClientEvent('sp_phone:client:serviceDispatch', players[i].source, {
                id = requestId,
                service = serviceKey,
                label = service.label,
                sender = number,
                message = body,
                coords = { x = coords.x, y = coords.y, z = coords.z }
            })
        end
    end

    cb({ ok = true, id = requestId })
end)

ESX.RegisterServerCallback('sp_phone:server:startCall', function(source, cb, targetNumber)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not hasPhone(xPlayer) then
        return callbackError(cb, 'Não tens um telemóvel.')
    end

    local callerNumber = ensurePhoneNumber(source, xPlayer)
    targetNumber = cleanNumber(targetNumber)
    local targetSource = sourceByNumber[targetNumber]
    local targetPlayer = targetSource and ESX.GetPlayerFromId(targetSource) or nil

    if not targetSource or not targetPlayer or not hasPhone(targetPlayer) or GetPlayerPing(targetSource) <= 0 then
        MySQL.insert.await([[
            INSERT INTO sp_phone_calls (caller_number, receiver_number, status)
            VALUES (?, ?, 'missed')
        ]], { callerNumber, targetNumber })
        return callbackError(cb, 'O destinatário está indisponível.')
    end

    if targetSource == source or callsBySource[source] or callsBySource[targetSource] then
        return callbackError(cb, 'A linha está ocupada.')
    end

    nextCallChannel = nextCallChannel + 1
    local call = {
        caller = source,
        receiver = targetSource,
        callerNumber = callerNumber,
        receiverNumber = targetNumber,
        channel = nextCallChannel,
        state = 'ringing',
        createdAt = os.time()
    }

    callsBySource[source] = call
    callsBySource[targetSource] = call

    TriggerClientEvent('sp_phone:client:outgoingCall', source, targetNumber)
    TriggerClientEvent('sp_phone:client:incomingCall', targetSource, callerNumber)

    CreateThread(function()
        Wait(Config.CallTimeoutSeconds * 1000)
        if not call.finished and call.state == 'ringing' then
            finishCall(call, 'missed')
        end
    end)

    cb({ ok = true })
end)

ESX.RegisterServerCallback('sp_phone:server:answerCall', function(source, cb)
    local call = callsBySource[source]
    if not call or call.receiver ~= source or call.state ~= 'ringing' then
        return callbackError(cb, 'Não existe uma chamada para atender.')
    end

    call.state = 'connected'
    call.connectedAt = os.time()
    local callerOk = setPlayerCall(call.caller, call.channel)
    local receiverOk = setPlayerCall(call.receiver, call.channel)

    if not callerOk or not receiverOk then
        finishCall(call, 'failed')
        return callbackError(cb, 'Falha ao ligar o canal de voz.')
    end

    TriggerClientEvent('sp_phone:client:callConnected', call.caller, call.receiverNumber)
    TriggerClientEvent('sp_phone:client:callConnected', call.receiver, call.callerNumber)
    cb({ ok = true })
end)

ESX.RegisterServerCallback('sp_phone:server:declineCall', function(source, cb)
    local call = callsBySource[source]
    if not call or call.receiver ~= source or call.state ~= 'ringing' then
        return callbackError(cb, 'Não existe uma chamada para rejeitar.')
    end

    finishCall(call, 'declined')
    cb({ ok = true })
end)

ESX.RegisterServerCallback('sp_phone:server:hangupCall', function(source, cb)
    local call = callsBySource[source]
    if not call then
        return callbackError(cb, 'Não existe uma chamada ativa.')
    end

    finishCall(call, call.state == 'connected' and 'completed' or 'declined')
    cb({ ok = true })
end)

ESX.RegisterUsableItem(Config.ItemName, function(source)
    TriggerClientEvent('sp_phone:client:open', source)
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    CreateThread(function()
        Wait(1000)
        ensurePhoneNumber(playerId, xPlayer)
    end)
end)

AddEventHandler('playerDropped', function()
    local source = source
    local number = numberBySource[source]
    if number then
        sourceByNumber[number] = nil
        numberBySource[source] = nil
    end

    local call = callsBySource[source]
    if call then
        finishCall(call, call.state == 'connected' and 'completed' or 'missed')
    end
    messageRate[source] = nil
end)

CreateThread(function()
    Wait(2000)
    local players = ESX.GetExtendedPlayers()
    for i = 1, #players do
        ensurePhoneNumber(players[i].source, players[i])
    end
end)

exports('GetPhoneNumber', function(source)
    return numberBySource[source] or ensurePhoneNumber(source)
end)

exports('GetSourceFromNumber', function(number)
    return sourceByNumber[cleanNumber(number)]
end)
