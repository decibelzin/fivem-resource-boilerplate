--- Ponte com a framework do servidor. ÚNICO ficheiro que muda ao portar para vRP/QBox/ESX:
--- o resto do resource só fala com `Framework.*` (ou `player:hasPermission`).
--- Default: standalone — identidade pela license, permissão por ACE.
Framework = {}

--- Chave estável do jogador (persistência, índices). nil = não dá para identificar → bind falha.
---@param src number
---@return string|nil
function Framework.identifier(src)
    return GetPlayerIdentifierByType(src, 'license')
end

---@param src number
---@return string
function Framework.displayName(src)
    return GetPlayerName(src) or ('#%s'):format(src)
end

--- server.cfg: `add_ace group.admin <permission> allow` + `add_principal identifier.license:xxx group.admin`
---@param src number
---@param permission string ex.: 'reports.manage'
---@return boolean
function Framework.hasPermission(src, permission)
    return IsPlayerAceAllowed(src, permission)
end
