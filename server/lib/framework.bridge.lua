--- Ponte com a framework do servidor. O resto do resource só fala com `Framework.*` (ou
--- `player:hasPermission`) — nunca com vRP/QBox/QBCore/ESX direto.
---
--- A framework é escolhida UMA vez, no load (ResolveFramework: convar `<resource>_framework` ou auto).
--- Cada server/bridge/<nome>.lua chama `Framework.register`; só a factory da escolhida corre. Este
--- ficheiro valida a entrada e fecha o contrato (fallback ACE, nome, contas, valor) — adapter fica fino.
---
--- Adapter = o que a factory devolve, mesma interface em todos:
---   identifier(src)                           → string|nil   chave do PERSONAGEM; nil = nenhum carregado
---   displayName(src)                          → string|nil
---   hasGroup(src, groups)                     → boolean      tem algum dos grupos nativos da lista
---   getMoney(src, account)                    → ok, code, amount?
---   addMoney(src, account, amount, reason)    → ok, code
---   removeMoney(src, account, amount, reason) → ok, code      nunca deixa saldo negativo
--- `account` chega validado (MONEY_ACCOUNT) e `amount` inteiro > 0. A factory recebe `lifecycle`
--- e traduz o evento nativo de personagem carregado/descarregado em `lifecycle.loaded/unloaded(src)`.
Framework = {
    --- standalone | qbox | qbcore | esx | vrp
    name = ResolveFramework(),
}

local log = Log.scope('framework')
local adapter = nil
local loadedHandlers = {}
local unloadedHandlers = {}

local function emit(handlers, src)
    for _, handler in ipairs(handlers) do
        handler(src)
    end
end

local lifecycle = {
    loaded = function(src) emit(loadedHandlers, src) end,
    unloaded = function(src) emit(unloadedHandlers, src) end,
}

local function isAccount(value)
    for _, account in pairs(MONEY_ACCOUNT) do
        if (account == value) then
            return true
        end
    end
    return false
end

--- math.tointeger rejeita fração, NaN e inf.
local function checkTransfer(account, amount)
    if (not isAccount(account)) then
        return false, 'invalid_account'
    end

    amount = math.tointeger(amount)
    if (not amount or amount < 1) then
        return false, 'invalid_amount'
    end

    return true, 'ok', amount
end

--- Chamado no load por server/bridge/<nome>.lua.
---@param name string
---@param factory fun(lifecycle: table): table|nil adapter (nil = não ativou; a factory loga o motivo)
function Framework.register(name, factory)
    if (name ~= Framework.name) then
        return
    end

    local resource = FrameworkConfig.resources[name]
    if (resource and GetResourceState(resource) ~= 'started') then
        log:error('%s não está started — ensure %s antes deste resource; não fica pronto', resource, resource)
        return
    end

    adapter = factory(lifecycle)
end

--- false = o adapter escolhido não ativou (motivo já logado) → o bootstrap não marca App.ready.
---@return boolean
function Framework.isActive()
    return adapter ~= nil
end

--- Personagem pronto (identifier disponível): standalone ao entrar; frameworks depois da seleção.
---@param handler fun(src: number)
function Framework.onPlayerLoaded(handler)
    table.insert(loadedHandlers, handler)
end

--- Personagem descarregado sem sair do servidor (logout / troca). Saída do servidor = `playerDropped`.
---@param handler fun(src: number)
function Framework.onPlayerUnloaded(handler)
    table.insert(unloadedHandlers, handler)
end

--- Chave estável do PERSONAGEM (persistência, índices): citizenid (QBox/QBCore), identifier (ESX),
--- Passport (vRP). Standalone não tem personagem: license. nil = sem personagem → bind falha.
---@param src number
---@return string|nil
function Framework.identifier(src)
    return adapter.identifier(src)
end

---@param src number
---@return string nome do personagem (standalone: nome do FiveM)
function Framework.displayName(src)
    return adapter.displayName(src) or GetPlayerName(src) or ('#%s'):format(src)
end

--- ACE em todas as frameworks; além dele, os grupos nativos de FrameworkConfig.groups[permission].
--- server.cfg: `add_ace group.admin <permission> allow` + `add_principal identifier.license:xxx group.admin`
---@param src number
---@param permission string ex.: 'reports.manage'
---@return boolean
function Framework.hasPermission(src, permission)
    if (IsPlayerAceAllowed(src, permission)) then
        return true
    end

    local groups = FrameworkConfig.groups[permission]
    return groups ~= nil and adapter.hasGroup(src, groups)
end

--- Standalone não tem economia: 'not_supported'.
---@param src number
---@param account string MONEY_ACCOUNT.*
---@return boolean ok, string code, number|nil amount
function Framework.getMoney(src, account)
    if (not isAccount(account)) then
        return false, 'invalid_account'
    end
    return adapter.getMoney(src, account)
end

---@param src number
---@param account string MONEY_ACCOUNT.*
---@param amount number inteiro > 0 — calculado no server, nunca vindo do client
---@param reason string|nil auditoria da framework (default: nome do resource)
---@return boolean ok, string code
function Framework.addMoney(src, account, amount, reason)
    local ok, code, value = checkTransfer(account, amount)
    if (not ok) then
        return false, code
    end
    return adapter.addMoney(src, account, value, reason or RESOURCE)
end

--- Saldo menor que `amount` → 'insufficient' em todas (mesmo onde a framework aceita negativo).
---@param src number
---@param account string MONEY_ACCOUNT.*
---@param amount number inteiro > 0 — calculado no server, nunca vindo do client
---@param reason string|nil auditoria da framework (default: nome do resource)
---@return boolean ok, string code
function Framework.removeMoney(src, account, amount, reason)
    local ok, code, value = checkTransfer(account, amount)
    if (not ok) then
        return false, code
    end
    return adapter.removeMoney(src, account, value, reason or RESOURCE)
end
