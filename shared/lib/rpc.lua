--- RPC client ↔ server com retorno, por nome explícito (sem proxy de string mágica).
---
--- Qualquer resource que carrega esta lib pode:
---   - registar handlers no seu próprio lado:  RPC.register('reports.create', fn)
---   - chamar handlers do outro lado:          RPC.await('reports.create', args)
---
--- Lados:
---   client → server:  RPC.await(name, ...)            -- target default: este resource
---                     RPC.awaitFrom(resource, name, ...)
---   server → client:  RPC.emitClient(src, name, ...)  -- fire and forget
---                     RPC.awaitClient(src, name, ...) -- com retorno
---
--- Handlers (server):  function(source, ...) return ... end
--- Handlers (client):  function(...) return ... end
--- Erro no handler é capturado; o caller recebe nil + 'rpc_handler_error'.
--- Método inexistente → nil + 'rpc_unknown_method'. Timeout default: 10s → nil + 'rpc_timeout'.
RPC = {}
RPC.TIMEOUT_MS = 10000

local isServer = IsDuplicityVersion()
local selfResource = GetCurrentResourceName()
local log = Log.scope('rpc')

RPC.DEFAULT_TARGET = selfResource

local handlers = {}
local pending = {}
local nextRequestId = 0
local requestListening = false
local responseListening = false

local function requestEvent(targetResource, side)
    return ('rpc:%s:%s'):format(side, targetResource)
end

local function responseEvent(callerResource, side)
    return ('rpc:%s:%s:res'):format(side, callerResource)
end

local function newRequestId()
    nextRequestId = nextRequestId + 1
    return ('%s:%d'):format(selfResource, nextRequestId)
end

local function resolve(requestId, payload)
    local entry = pending[requestId]
    if (not entry) then
        return
    end

    pending[requestId] = nil
    entry.payload = payload
    entry.promise:resolve(true)
end

local function runHandler(name, args, reply)
    local handler = handlers[name]
    if (not handler) then
        reply({ ok = false, err = 'rpc_unknown_method' })
        return
    end

    local results = { pcall(handler, table.unpack(args)) }
    if (not results[1]) then
        log:error('handler %s falhou: %s', name, tostring(results[2]))
        reply({ ok = false, err = 'rpc_handler_error' })
        return
    end

    table.remove(results, 1)
    reply({ ok = true, results = results })
end

--- Listener de pedidos no lado local (lazy: só regista quando há handlers).
local function ensureRequestListener()
    if (requestListening) then
        return
    end
    requestListening = true

    if (isServer) then
        RegisterNetEvent(requestEvent(selfResource, 's'), function(packet)
            local src = source

            -- pacote vem do client: formato inválido é descartado em silêncio.
            if (type(packet) ~= 'table' or type(packet.name) ~= 'string' or type(packet.caller) ~= 'string') then
                return
            end

            local args = type(packet.args) == 'table' and packet.args or {}
            table.insert(args, 1, src)

            runHandler(packet.name, args, function(response)
                response.id = packet.id
                TriggerClientEvent(responseEvent(packet.caller, 'c'), src, response)
            end)
        end)
        return
    end

    RegisterNetEvent(requestEvent(selfResource, 'c'), function(packet)
        runHandler(packet.name, packet.args or {}, function(response)
            -- emitClient não manda id: ninguém espera resposta.
            if (not packet.id) then
                return
            end
            response.id = packet.id
            TriggerServerEvent(responseEvent(packet.caller, 's'), response)
        end)
    end)
end

--- Listener de respostas no lado local (lazy: só regista quando há chamadas).
local function ensureResponseListener()
    if (responseListening) then
        return
    end
    responseListening = true

    RegisterNetEvent(responseEvent(selfResource, isServer and 's' or 'c'), function(response)
        if (type(response) ~= 'table') then
            return
        end

        local entry = pending[response.id]
        -- server: só o client que recebeu o pedido pode responder (anti-spoof entre jogadores).
        if (not entry or (isServer and entry.target ~= source)) then
            return
        end

        resolve(response.id, response)
    end)
end

local function awaitResponse(requestId)
    local entry = pending[requestId]

    SetTimeout(RPC.TIMEOUT_MS, function()
        resolve(requestId, { ok = false, err = 'rpc_timeout' })
    end)

    Citizen.Await(entry.promise)

    local payload = entry.payload
    if (not payload.ok) then
        return nil, payload.err
    end

    return table.unpack(payload.results or {})
end

---@param name string
---@param handler function server: fun(source, ...) | client: fun(...)
function RPC.register(name, handler)
    handlers[name] = handler
    ensureRequestListener()
end

--- (client) Chama um handler registado no server de `targetResource`. Yields — usar dentro de thread.
function RPC.awaitFrom(targetResource, name, ...)
    ensureResponseListener()

    local requestId = newRequestId()
    pending[requestId] = { promise = promise.new() }

    TriggerServerEvent(requestEvent(targetResource, 's'), {
        id = requestId,
        caller = selfResource,
        name = name,
        args = { ... },
    })

    return awaitResponse(requestId)
end

--- (client) Chama um handler do server deste resource. Yields — usar dentro de thread.
function RPC.await(name, ...)
    return RPC.awaitFrom(RPC.DEFAULT_TARGET, name, ...)
end

--- (server) Dispara um handler client sem esperar retorno.
---@param src number
---@param name string
function RPC.emitClient(src, name, ...)
    RPC.emitClientTo(selfResource, src, name, ...)
end

--- (server) Igual a emitClient, mas o handler vive no client de outro resource.
function RPC.emitClientTo(targetResource, src, name, ...)
    TriggerClientEvent(requestEvent(targetResource, 'c'), src, {
        caller = selfResource,
        name = name,
        args = { ... },
    })
end

--- (server) Chama um handler client e espera o retorno. Yields — usar dentro de thread.
--- O retorno vem do client: trate como input não confiável.
function RPC.awaitClient(src, name, ...)
    return RPC.awaitClientFrom(selfResource, src, name, ...)
end

--- (server) awaitClient com handler registado noutro resource.
function RPC.awaitClientFrom(targetResource, src, name, ...)
    ensureResponseListener()

    local requestId = newRequestId()
    pending[requestId] = { promise = promise.new(), target = tonumber(src) }

    TriggerClientEvent(requestEvent(targetResource, 'c'), src, {
        id = requestId,
        caller = selfResource,
        name = name,
        args = { ... },
    })

    return awaitResponse(requestId)
end
