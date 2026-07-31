fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Soul Project'
description 'Kit inicial idempotente para ESX Legacy'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'es_extended',
    'oxmysql'
}
