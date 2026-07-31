Config = {}

Config.ItemRequired = true
Config.ItemName = 'radio'
Config.Command = 'radio'
Config.LeaveCommand = 'radiooff'
Config.VolumeCommand = 'radiovol'
Config.DefaultKey = 'F6'
Config.MinimumChannel = 1
Config.MaximumChannel = 999
Config.RevalidateSeconds = 10

Config.RestrictedRanges = {
    { min = 1, max = 49, jobs = { police = true }, label = 'Polícia' },
    { min = 50, max = 99, jobs = { ambulance = true }, label = 'Emergência Médica' },
    { min = 100, max = 149, jobs = { police = true, ambulance = true }, label = 'Emergência conjunta' },
    { min = 150, max = 199, jobs = { mechanic = true }, label = 'Mecânicos' },
    { min = 200, max = 249, jobs = { taxi = true }, label = 'Táxis' }
}

Config.Messages = {
    noItem = 'Precisas de um rádio para usar frequências.',
    invalid = 'A frequência indicada não é válida.',
    denied = 'Não tens autorização para essa frequência.',
    joined = 'Ligado à frequência %s.',
    left = 'Rádio desligado.',
    volume = 'Volume do rádio definido para %s%%.'
}
