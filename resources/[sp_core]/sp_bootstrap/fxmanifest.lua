fx_version 'cerulean'
game 'gta5'

name 'sp_bootstrap'
author 'Soul Project'
description 'Bootstrap, gate Steam-only e diagnóstico da base Soul Project ESX Legacy'
version '0.1.0'

shared_scripts {
    'config.lua',
    'shared/logger.lua'
}

client_script 'client/main.lua'
server_script 'server/main.lua'

dependencies {
    'oxmysql',
    'es_extended'
}
