fx_version 'cerulean'
game 'gta5'

author 'Claude'
description 'Script de livraison de drogue (Gofast) avec UI moderne et système police'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'config/config.lua',
    'locales/*.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

-- UI désactivée, on utilise ox_lib menu natif
-- ui_page 'html/index.html'

-- files {
--     'html/index.html',
--     'html/style.css',
--     'html/script.js',
--     'html/assets/*.png',
--     'html/assets/*.jpg'
-- }

dependencies {
    'es_extended',
    'ox_lib'
}

lua54 'yes'
