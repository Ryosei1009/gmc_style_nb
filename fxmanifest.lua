fx_version 'cerulean'
game 'gta5'

author 'GMC'
description 'Style N&B - Photo Magazine App'
version '1.0.0'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page "ui/dist/index.html"

files {
    "ui/dist/**/*",
    "ui/icon.png"
}

dependency 'qb-core'
dependency 'oxmysql'
dependency 'okokBanking'
