--- Registo de comandos com contexto e permissão (via Framework.hasPermission).
---
---   CreateCommand('closereport', function(ctx, args) ... end, { console = true, permission = 'reports.manage' })
---
--- ctx: { isConsole, source?, player?, actor }  ·  ctx nunca usa source=0 como jogador.
--- access: { console?: boolean, permission?: string } — sem nenhum dos dois o comando fica bloqueado.
--- Comando livre para qualquer jogador = RegisterCommand no client + RPC (o server valida o resto).
CommandManager = class()

function CommandManager:__init()
    self.log = Log.scope('commands')
end

function CommandManager:buildContext(invokerSource)
    invokerSource = tonumber(invokerSource)

    if (invokerSource == 0) then
        return { isConsole = true, source = nil, player = nil, actor = 'console' }
    end

    local player = playerRegistry:get(invokerSource)
    return {
        isConsole = false,
        source = invokerSource,
        player = player,
        actor = player and player.identifier or ('source:%s'):format(invokerSource),
    }
end

function CommandManager:canExecute(ctx, access)
    if (ctx.isConsole) then
        return access.console == true
    end
    return access.permission ~= nil and Framework.hasPermission(ctx.source, access.permission)
end

--- Resposta ao invocador (print no console ou chat unicast).
function CommandManager:reply(ctx, message)
    if (ctx.isConsole) then
        print(('[%s] %s'):format(RESOURCE, message))
        return
    end

    TriggerClientEvent('chat:addMessage', ctx.source, {
        color = { 255, 255, 255 },
        args = { RESOURCE, message },
    })
end

function CommandManager:register(name, handler, access)
    if (type(access) ~= 'table' or (access.console ~= true and access.permission == nil)) then
        self.log:warn('comando %s sem access válido — bloqueado por defeito', name)
        access = { console = false }
    end

    RegisterCommand(name, function(invokerSource, args, rawCommand)
        local ctx = self:buildContext(invokerSource)

        if (not self:canExecute(ctx, access)) then
            self:reply(ctx, 'Sem permissão.')
            return
        end

        if (not App.ready) then
            self:reply(ctx, 'O resource ainda não terminou o arranque.')
            return
        end

        handler(ctx, args, rawCommand)
    end, false)
end

commandManager = CommandManager()

---@param name string
---@param handler fun(ctx: table, args: string[], rawCommand: string)
---@param access { console?: boolean, permission?: string }
function CreateCommand(name, handler, access)
    commandManager:register(name, handler, access)
end
