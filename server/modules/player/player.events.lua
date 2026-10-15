--- Entrada/saída do registry. A ponte avisa quando o PERSONAGEM fica pronto (por padrão ao entrar;
--- com seleção de personagem, depois dela) e quando é descarregado (logout / troca de personagem).
--- Antes do App.ready o bootstrap faz o bind de quem já está online.
Framework.onPlayerLoaded(function(src)
    if (not App.ready) then
        return
    end

    -- Troca de personagem sem aviso de unload pela ponte: o bind antigo seria do outro personagem.
    playerRegistry:unbind(src)

    local ok, code = playerRegistry:bind(src)
    if (not ok) then
        playerRegistry.log:warn('bind src=%s falhou: %s', src, code)
    end
end)

Framework.onPlayerUnloaded(function(src)
    playerRegistry:unbind(src)
end)

AddEventHandler('playerDropped', function()
    playerRegistry:unbind(source)
end)
