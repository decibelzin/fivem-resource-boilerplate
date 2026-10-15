--- FICHEIRO ABERTO — liga o script à framework do seu servidor.
--- Como vem: standalone (license, nome do FiveM, permissão só por ACE). Troque o CORPO das funções
--- pelo equivalente da sua framework; não mude nomes nem argumentos. Devolva valores simples
--- (string, número, boolean). Erro aqui não derruba o script: vira log e valor padrão.
Bridge = {}

--- Id ESTÁVEL do PERSONAGEM — é a chave com que o script grava os dados. Com vários personagens por
--- conta, devolva o id do personagem, não o da conta. nil = personagem ainda não carregado.
---@param src number
---@return string|number|nil
function Bridge.identifier(src)
    return GetPlayerIdentifierByType(src, 'license')
end

--- Nome mostrado no script (ex.: nome do personagem). nil = nome do FiveM.
---@param src number
---@return string|nil
function Bridge.displayName(src)
    return GetPlayerName(src)
end

--- Permissão EXTRA além do ACE, que vale sempre (`add_ace group.admin <permissão> allow`).
--- Ex.: liberar a permissão para um grupo/cargo da sua framework.
---@param src number
---@param permission string
---@return boolean
function Bridge.hasPermission(src, permission)
    return false
end

--- Avise o script quando o personagem fica pronto. Como vem: ao conectar. Com seleção de
--- personagem, troque pelo evento de "personagem carregado" da sua framework.
AddEventHandler('playerJoining', function()
    Framework.playerLoaded(source)
end)

--- Se a sua framework tem logout/troca de personagem sem desconectar, avise também:
-- AddEventHandler('<evento de personagem descarregado>', function(src)
--     Framework.playerUnloaded(src)
-- end)
