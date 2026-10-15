--- Recebe `NotifyPlayer` do server: chave + parâmetros → texto da config local → `Notify` da ponte.
RegisterNetEvent(EVENT.NOTIFY, function(key, ...)
    if (type(key) ~= 'string') then
        return
    end

    -- Chave apagada da config: mostra a própria chave em vez de silêncio (o comprador acha o que falta).
    Notify(Text(key, ...) or key)
end)
