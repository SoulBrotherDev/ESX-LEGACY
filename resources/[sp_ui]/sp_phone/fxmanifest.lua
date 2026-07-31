fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Soul Project'
description 'Telefone ESX com SMS, contactos, chamadas e serviços'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_script 'client/main.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'es_extended',
    'oxmysql',
    'pma-voice'
}
