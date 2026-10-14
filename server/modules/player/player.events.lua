--- Entrada/saída do registry. Antes do App.ready o bootstrap faz o bind de quem já está online.
AddEventHandler('playerJoining', function()
    if (not App.ready) then
        return
    end

    local src = source
    local ok, code = playerRegistry:bind(src)
    if (not ok) then
        playerRegistry.log:warn('bind src=%s falhou: %s', src, code)
    end
end)

AddEventHandler('playerDropped', function()
    playerRegistry:unbind(source)
end)
