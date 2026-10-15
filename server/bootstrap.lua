--- Arranque: schema → App.ready → bind de quem já está online → EVENT.READY.
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

    -- Restart a quente: o evento de personagem carregado não dispara de novo para quem já está dentro.
    -- no_identifier = ainda na seleção de personagem; o bind vem no Framework.onPlayerLoaded.
    local players = GetPlayers()
    for _, src in ipairs(players) do
        local bindOk, bindCode = playerRegistry:bind(src)
        if (not bindOk and bindCode ~= 'no_identifier') then
            log:warn('bind src=%s falhou: %s', src, bindCode)
        end
    end

    TriggerEvent(EVENT.READY)
    log:info('pronto — %d jogador(es) online', #players)
end)
