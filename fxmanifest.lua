fx_version 'cerulean'

game 'gta5'

description 'Xperience - XP Ranking System for FiveM'

author 'Mobius1'

version '0.2.0'

shared_scripts {
    'config.lua',
    'common/ranks.lua',
    'common/utils.lua',
}

server_scripts {
    -- '@mysql-async/lib/MySQL.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
}

ui_page 'ui/ui.html'

files {
    'ui/ui.html',
    'ui/fonts/*.ttf',
    'ui/css/*.css',
    'ui/js/*.js'
}