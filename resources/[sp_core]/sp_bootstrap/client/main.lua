CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(250)
    end

    TriggerServerEvent('sp_bootstrap:clientReady')
end)
