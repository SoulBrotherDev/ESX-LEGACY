Config = {}

Config.Command = 'phone'
Config.DefaultKey = 'F1'
Config.ItemRequired = true
Config.ItemName = 'phone'
Config.NumberPrefix = '555'
Config.NumberDigits = 4
Config.MaximumMessageLength = 500
Config.MaximumContacts = 100
Config.MessageCooldownMs = 750
Config.CallChannelBase = 70000
Config.CallTimeoutSeconds = 30
Config.HistoryLimit = 100

Config.Services = {
    police = { label = 'Polícia', number = '112', job = 'police' },
    ambulance = { label = 'Emergência Médica', number = '115', job = 'ambulance' },
    mechanic = { label = 'Mecânico', number = '116', job = 'mechanic' },
    taxi = { label = 'Táxi', number = '117', job = 'taxi' }
}
