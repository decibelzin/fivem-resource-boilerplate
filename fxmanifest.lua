fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'fivem-resource-boilerplate'
description 'Boilerplate de resource FiveM — server autoritativo, módulos em camadas, RPC com retorno'
version '0.1.0'
author 'decibelsz'

-- Ordem importa só nas libs. Módulos são order-independent: registam schema/handlers no load
-- e resolvem instâncias de outros módulos em runtime (dentro de funções).
shared_scripts {
    'shared/lib/class.lua',
    'shared/lib/log.lua',
    'shared/lib/rpc.lua',
    'shared/constants.lua',
    'shared/config/*.lua',
}

client_scripts {
    'client/lib/*.lua',
    'client/modules/**/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- sem persistência? remova esta linha e os *.schema.lua
    'server/lib/*.lua',
    'server/modules/**/*.lua',
    'server/api/*.lua',
    'server/bootstrap.lua',
}
