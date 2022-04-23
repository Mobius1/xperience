fx_version 'adamant'

game 'gta5'

description 'Xperience - XP Ranking System for FiveM'

author 'Mobius1'

version '0.1.0'

server_scripts {
    -- '@mysql-async/lib/MySQL.lua',
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'common/ranks.lua',
    'common/utils.lua',
    'server/main.lua'
}

client_scripts {
    'config.lua',
    'common/ranks.lua',
    'common/utils.lua',
    'client/main.lua',
}

ui_page 'ui/ui.html'

files {
    'ui/ui.html',
    'ui/fonts/ChaletComprimeCologneSixty.ttf',
    'ui/css/app.css',
    'ui/js/class.xperience.js',
    'ui/js/class.paginator.js',
    'ui/js/class.leaderboard.js',
    'ui/js/app.js'
}