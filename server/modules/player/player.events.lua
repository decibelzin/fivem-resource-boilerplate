--- Entrada/saída do registry. O bridge avisa quando o PERSONAGEM fica pronto (standalone: ao entrar;
--- frameworks: depois da seleção) e quando é descarregado (logout / troca de personagem).
--- Antes do App.ready o bootstrap faz o bind de quem já está online.
Framework.onPlayerLoaded(function(src)
    if (not App.ready) then
        return
    end

    -- Framework sem evento de unload (ex.: vRP) que troque de personagem: o bind antigo seria do outro.
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
