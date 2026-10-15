--- Núcleo da ponte. Os módulos só falam com `Framework.*` (ou `player:hasPermission`); quem liga a
--- framework do servidor é o ficheiro aberto bridge/bridge.server.lua (`Bridge.*`, valores simples).
--- Aqui fica o que o comprador não deve precisar de saber: proteção contra erro no código dele,
--- checagem do retorno e o fallback ACE. Função nova na ponte = `Bridge.x` com default + `Framework.x` aqui.
Framework = {}

local log = Log.scope('bridge')
local loadedHandlers = {}
local unloadedHandlers = {}

--- Código do comprador com erro vira log e `ok = false`, nunca derruba o fluxo do script.
local function call(name, ...)
    local ok, result = pcall(Bridge[name], ...)
    if (not ok) then
        log:error('Bridge.%s falhou: %s', name, result)
    end
    return ok, result
end

local function emit(handlers, src)
    for _, handler in ipairs(handlers) do
        handler(src)
    end
end

--- Chave estável do PERSONAGEM (persistência, índices). nil = nenhum carregado → bind falha.
---@param src number
---@return string|nil
function Framework.identifier(src)
    local ok, id = call('identifier', src)
    if (not ok or (type(id) ~= 'string' and type(id) ~= 'number')) then
        return nil
    end
    return tostring(id)
end

---@param src number
---@return string
function Framework.displayName(src)
    local ok, name = call('displayName', src)
    if (ok and type(name) == 'string' and name ~= '') then
        return name
    end
    return GetPlayerName(src) or ('#%s'):format(src)
end

--- ACE vale sempre (`add_ace group.admin <permission> allow`); o Bridge só pode somar a ele.
---@param src number
---@param permission string ex.: 'meumodulo.manage'
---@return boolean
function Framework.hasPermission(src, permission)
    if (IsPlayerAceAllowed(src, permission)) then
        return true
    end

    local ok, allowed = call('hasPermission', src, permission)
    return ok and allowed == true
end

--- Chamados pelo bridge aberto quando a framework avisa que o personagem carregou / descarregou.
function Framework.playerLoaded(src)
    emit(loadedHandlers, tonumber(src))
end

function Framework.playerUnloaded(src)
    emit(unloadedHandlers, tonumber(src))
end

--- Personagem pronto (identifier disponível). Carregue dado de jogador aqui, nunca no playerJoining.
---@param handler fun(src: number)
function Framework.onPlayerLoaded(handler)
    table.insert(loadedHandlers, handler)
end

--- Personagem descarregado sem sair do servidor (logout / troca). Saída do servidor = `playerDropped`.
---@param handler fun(src: number)
function Framework.onPlayerUnloaded(handler)
    table.insert(unloadedHandlers, handler)
end
