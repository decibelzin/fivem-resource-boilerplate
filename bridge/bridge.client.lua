--- FICHEIRO ABERTO — como o script mostra mensagens ao jogador.
--- Como vem: chat. Troque pelo notify do seu servidor; não mude o nome nem o argumento.
---@param message string
function Notify(message)
    TriggerEvent('chat:addMessage', {
        color = { 255, 255, 255 },
        args = { RESOURCE, message },
    })
end
