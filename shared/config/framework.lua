--- Framework do servidor: bridge em server/lib/framework.bridge.lua, adapters em server/bridge/.
--- Tudo que um humano ajusta ao portar vive aqui — nome de resource ou de grupo nunca vai no código.
FrameworkConfig = {
    --- server.cfg: `setr <resource>_framework auto` — auto | standalone | qbox | qbcore | esx | vrp.
    --- `setr` replica para o client (Notify faz a mesma escolha); com `set` o client cai no auto.
    convar = function()
        return GetConvar(('%s_framework'):format(RESOURCE), 'auto')
    end,

    --- Resource que cada framework exige started — `ensure` dele ANTES deste resource no server.cfg.
    resources = {
        qbox = 'qbx_core',
        qbcore = 'qb-core',
        esx = 'es_extended',
        vrp = 'vrp',
    },

    --- Ordem do auto: a primeira com o resource started ganha; nenhuma → standalone.
    --- qbox antes de qbcore: o qbx_core faz `provide 'qb-core'` e passaria por qbcore.
    detectOrder = { 'qbox', 'qbcore', 'esx', 'vrp' },

    --- Permissão → grupos NATIVOS da framework que a concedem. O ACE vale sempre, em todas
    --- (`add_ace group.admin <permissão> allow`); isto é o que se soma a ele. Nomes exatos da SUA
    --- framework: QBox = job/gang · QBCore = god/admin/mod · ESX = grupo (admin, user…) ·
    --- vRP creative = grupo (ex.: 'Admin'). Standalone ignora. Módulo removido → remova a entrada.
    groups = {
        ['reports.manage'] = { 'admin' },
    },
}

--- Contas do contrato do bridge (`Framework.getMoney/addMoney/removeMoney`). Cada adapter mapeia
--- para o nome nativo (cash → 'money' no ESX). Conta nova = entrada aqui + no mapa de cada adapter.
MONEY_ACCOUNT = {
    CASH = 'cash',
    BANK = 'bank',
}
