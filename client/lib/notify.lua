--- Feedback ao jogador. Default: chat. Para usar o notify do seu servidor, só este ficheiro muda.
---@param message string
function Notify(message)
    TriggerEvent('chat:addMessage', {
        color = { 255, 255, 255 },
        args = { RESOURCE, message },
    })
end
