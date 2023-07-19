fx_version 'cerulean'
game 'gta5'

author 'Malik'
description 'Created by Malik'
version '1.0'

-- Lib RageUI
client_scripts {
    "RageUI/RMenu.lua",
    "RageUI/menu/RageUI.lua",
    "RageUI/menu/Menu.lua",
    "RageUI/menu/MenuController.lua",
    "RageUI/components/*.lua",
    "RageUI/menu/elements/*.lua",
    "RageUI/menu/items/*.lua",
    "RageUI/menu/panels/*.lua",
    "RageUI/menu/windows/*.lua",
}


client_scripts {
    'client/cl_admin.lua',
}

server_scripts {
    "@mysql-async/lib/MySQL.lua",
    "server/sv_admin.lua",
}
