--- Escolha da framework — a mesma conta no server (bridge) e no client (Notify), feita UMA vez no
--- load de cada lado. Convar e ordem do auto em shared/config/framework.lua.
--- Sem poll e sem `dependency`: o resource da framework sobe ANTES deste (ordem do server.cfg).
local log = Log.scope('framework')

---@return string name standalone | qbox | qbcore | esx | vrp
function ResolveFramework()
    local wanted = FrameworkConfig.convar()
    if (wanted == 'standalone' or FrameworkConfig.resources[wanted]) then
        log:info('framework: %s (convar)', wanted)
        return wanted
    end

    if (wanted ~= 'auto') then
        log:warn('convar framework "%s" inválida — usando auto', wanted)
    end

    for _, name in ipairs(FrameworkConfig.detectOrder) do
        if (GetResourceState(FrameworkConfig.resources[name]) == 'started') then
            log:info('framework: %s (auto)', name)
            return name
        end
    end

    log:info('framework: standalone (auto — nenhuma framework started)')
    return 'standalone'
end
