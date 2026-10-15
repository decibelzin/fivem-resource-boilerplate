--- OPEN FILE — how the script shows messages to the player.
--- Out of the box: chat. Replace it with your server's notify; do not rename it or change the argument.
---@param message string
function Notify(message)
    TriggerEvent('chat:addMessage', {
        color = { 255, 255, 255 },
        args = { RESOURCE, message },
    })
end
