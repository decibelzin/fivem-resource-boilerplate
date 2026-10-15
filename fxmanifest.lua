fx_version 'bodacious'
game 'gta5'
lua54 'yes'
-- Faster native calls. Pass coordinates to natives as x, y, z: vectors are not unpacked with OAL.
use_experimental_fxv2_oal 'yes'

name 'fivem-resource-boilerplate'
description 'Boilerplate de resource FiveM — server autoritativo, módulos em camadas, RPC com retorno'
version '0.1.0'
author 'decibelsz'

-- Order only matters for the libs. Modules are order-independent: they register schema/handlers on
-- load and resolve other modules' instances at runtime (inside functions).
shared_scripts {
    'shared/lib/class.lua',
    'shared/lib/log.lua',
    'shared/lib/rpc.lua',
    'shared/lib/text.lua',
    'shared/constants.lua',
    'shared/config/*.lua',
}

client_scripts {
    'bridge/bridge.client.lua',
    'client/lib/*.lua',
    'client/modules/**/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- no persistence? remove this line and the *.schema.lua files
    'server/config/*.lua', -- server-only settings: never sent to players (webhooks, API keys)
    'server/lib/*.lua',
    'bridge/bridge.server.lua',
    'server/modules/**/*.lua',
    'server/api/*.lua',
    'server/bootstrap.lua',
}

-- Escrow (Tebex): only these stay open to the buyer — the framework bridge and the config.
escrow_ignore {
    'bridge/*.lua',
    'shared/config/*.lua',
    'server/config/*.lua',
}
