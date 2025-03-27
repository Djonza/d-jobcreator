fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Djonza'
description 'Job creator script'
version '1.0.0'

server_scripts {'server.lua', 'stashes-server.lua', '@oxmysql/lib/MySQL.lua'}
client_scripts {'client.lua', 'stashes-client.lua'}
shared_scripts { '@ox_lib/init.lua', '@es_extended/imports.lua', 'config.lua'}
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',   
    'locales/*.json'
}

