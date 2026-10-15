--- Arranque: schema → App.ready → EVENT.READY. Jogadores entram no cache sob demanda
--- (playerRegistry:get): restart a quente não varre quem já está online.
--- Pré-requisito: `ensure oxmysql` e a framework ANTES deste resource no server.cfg (sem poll, sem dependency).
App = { ready = false }

local log = Log.scope('bootstrap')

CreateThread(function()
    if (#Schema.tables > 0 and GetResourceState('oxmysql') ~= 'started') then
        log:error('oxmysql não está started — ensure oxmysql antes deste resource no server.cfg')
        return
    end

    local ok, code = databaseBootstrap:run()
    if (not ok) then
        log:error('schema falhou (%s) — verifica a mysql_connection_string', code)
        return
    end

    App.ready = true
    TriggerEvent(EVENT.READY)
    log:info('pronto')
end)
