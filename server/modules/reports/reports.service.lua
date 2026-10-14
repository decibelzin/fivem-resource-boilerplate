--- Reports de jogador → staff. Fluxo: validar → persistir → avisar a audiência (unicast).
--- Retorno padrão: ok, code ('ok'|'cooldown'|'not_found'|...), data?
ReportsService = class()

function ReportsService:__init()
    self.log = Log.scope('reports')
    --- identifier → unix do último report (anti-spam; zera no restart do resource).
    self.lastCreatedAt = {}
end

--- Unicast para cada staff online — broadcast -1 é proibido (vaza dado e pesa na rede).
function ReportsService:notifyStaff(payload)
    playerRegistry:each(function(player)
        if (player:hasPermission(ReportsConfig.permission)) then
            TriggerClientEvent(EVENT.REPORT_CREATED, player.source, payload)
        end
    end)
end

---@param player table OnlinePlayer
---@param message any texto vindo do client — não confiável
---@return boolean ok, string code, table|nil data ReportPayload | { retryIn }
function ReportsService:create(player, message)
    message = Util.trim(message)

    local length = utf8.len(message) or #message
    if (length < ReportsConfig.minLength) then
        return false, 'message_too_short'
    end
    if (length > ReportsConfig.maxLength) then
        return false, 'message_too_long'
    end

    local now = os.time()
    local lastAt = self.lastCreatedAt[player.identifier]
    if (lastAt and now - lastAt < ReportsConfig.cooldownSeconds) then
        return false, 'cooldown', { retryIn = ReportsConfig.cooldownSeconds - (now - lastAt) }
    end

    -- marca ANTES do primeiro await: o MySQL cede a vez e dois pedidos simultâneos do mesmo
    -- jogador passariam juntos pelo cooldown. Falhou adiante? devolve o valor anterior.
    self.lastCreatedAt[player.identifier] = now

    if (reportsRepository:countOpenByAuthor(player.identifier) >= ReportsConfig.maxOpenPerAuthor) then
        self.lastCreatedAt[player.identifier] = lastAt
        return false, 'too_many_open'
    end

    local report = reportsRepository:create(player.identifier, player.name, message)
    if (not report) then
        self.lastCreatedAt[player.identifier] = lastAt
        self.log:error('insert falhou autor=%s', player.identifier)
        return false, 'insert_failed'
    end

    local payload = report:toPayload()
    self:notifyStaff(payload)

    self.log:info('report #%s criado por %s', report.id, player.identifier)
    return true, 'ok', payload
end

---@return table[] ReportPayload[] (fila, mais antigos primeiro)
function ReportsService:listOpen()
    local payload = {}
    for i, report in ipairs(reportsRepository:listOpen(ReportsConfig.listLimit)) do
        payload[i] = report:toPayload()
    end
    return payload
end

---@param actor string quem fechou (identifier, 'console', 'resource:<nome>')
---@return boolean ok, string code, table|nil ReportPayload
function ReportsService:close(id, actor)
    id = math.floor(tonumber(id) or 0)
    if (id < 1) then
        return false, 'invalid_id'
    end

    local report = reportsRepository:findById(id)
    if (not report) then
        return false, 'not_found'
    end

    if (not report:isOpen() or not reportsRepository:close(id, actor)) then
        return false, 'already_closed'
    end

    report:markClosed(actor)
    local payload = report:toPayload()

    local authorSource = playerRegistry:getSourceByIdentifier(report.authorIdentifier)
    if (authorSource) then
        TriggerClientEvent(EVENT.REPORT_CLOSED, authorSource, payload)
    end

    self.log:info('report #%s fechado por %s', id, actor)
    return true, 'ok', payload
end

reportsService = ReportsService()
