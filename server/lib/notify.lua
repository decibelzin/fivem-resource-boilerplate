--- Mensagem para UM jogador, por chave de texto: vai só a chave + parâmetros dinâmicos; o client resolve o
--- texto na config dele (`Text`) e mostra pelo `Notify` da ponte.
---   NotifyPlayer(src, 'reports.closed', reportId)
---@param src number
---@param key string chave em `Messages` (ex.: 'reports.closed')
function NotifyPlayer(src, key, ...)
    TriggerClientEvent(EVENT.NOTIFY, src, key, ...)
end
