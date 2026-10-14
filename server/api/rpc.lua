--- Superfície RPC client → server. TODA ação do client que precisa de retorno passa aqui.
--- Handlers delegam para os services; nada de regra de negócio neste ficheiro.
--- Contrato documentado em docs/api.md — RPC novo entra lá no mesmo commit.
---
--- Convenção de retorno: ok:boolean, code:string, data?:table
--- Caller (client): RPC.await('reports.create', { message = '...' })

local function guard(handler)
    return function(src, ...)
        if (not App.ready) then
            return false, 'not_ready'
        end
        return handler(src, ...)
    end
end

local function withPlayer(handler)
    return guard(function(src, ...)
        local player = playerRegistry:get(src)
        if (not player) then
            return false, 'not_online'
        end
        return handler(player, ...)
    end)
end

-- Reports ------------------------------------------------------------------------------

RPC.register('reports.create', withPlayer(function(player, args)
    return reportsService:create(player, type(args) == 'table' and args.message or nil)
end))
