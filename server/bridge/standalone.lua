--- Adapter standalone (sem framework). Identifier = license — POR CONTA: não há personagem.
--- Nome do FiveM, permissão só por ACE (fallback do bridge), sem economia.
Framework.register('standalone', function(lifecycle)
    -- Sem seleção de personagem: o jogador fica pronto ao entrar.
    AddEventHandler('playerJoining', function()
        lifecycle.loaded(source)
    end)

    local adapter = {}

    function adapter.identifier(src)
        return GetPlayerIdentifierByType(src, 'license')
    end

    function adapter.displayName(src)
        return GetPlayerName(src)
    end

    function adapter.hasGroup()
        return false
    end

    function adapter.getMoney()
        return false, 'not_supported'
    end

    adapter.addMoney = adapter.getMoney
    adapter.removeMoney = adapter.getMoney

    return adapter
end)
