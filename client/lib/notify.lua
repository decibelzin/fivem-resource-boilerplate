--- Feedback ao jogador pelo notify nativo da framework — mesma escolha do server (ResolveFramework).
--- Sem notify nativo (standalone, vRP) ou com o resource dele parado → chat.
local NATIVE = {
    qbox = {
        resource = 'qbx_core',
        show = function(message) exports.qbx_core:Notify(message) end,
    },
    qbcore = {
        resource = 'qb-core',
        show = function(message) TriggerEvent('QBCore:Notify', message) end,
    },
    esx = {
        -- ESX.ShowNotification só desenha com o esx_notify started.
        resource = 'esx_notify',
        show = function(message) TriggerEvent('esx:showNotification', message) end,
    },
    -- vRP: o core não tem notify; cada fork usa o seu (creative: evento 'Notify' com cor e args que
    -- mudam por versão — assinatura não confirmada, por isso fica no chat). Ligue aqui o do seu servidor.
}

local native = NATIVE[ResolveFramework()]

---@param message string
function Notify(message)
    if (native and GetResourceState(native.resource) == 'started') then
        native.show(message)
        return
    end

    TriggerEvent('chat:addMessage', {
        color = { 255, 255, 255 },
        args = { RESOURCE, message },
    })
end
