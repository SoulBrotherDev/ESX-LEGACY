Config = {}

Config.Locale = GetConvar('sp:locale', 'pt-PT')
Config.Environment = GetConvar('sp:environment', 'development')
Config.SteamOnly = GetConvarInt('sp:steam_only', 1) == 1
Config.HealthCommand = 'sp_health'

Config.RequiredResources = {
    'oxmysql',
    'es_extended'
}

Config.SteamRequiredMessage = table.concat({
    'SOUL PROJECT',
    '',
    'É obrigatório ter a Steam aberta e associada ao FiveM.',
    'Fecha o FiveM, inicia sessão na Steam e tenta novamente.'
}, '\n')
