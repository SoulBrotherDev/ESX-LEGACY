fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Soul Project'
description 'Rádio ESX seguro sobre pma-voice'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_script 'client/main.lua'
server_script 'server/main.lua'

dependencies {
    'es_extended',
    'pma-voice'
}
