--- Registry de jogadores online. Único dono dos índices source/identifier.
PlayerRegistry = class()

function PlayerRegistry:__init()
    self.bySource = {}
    self.byIdentifier = {}
    self.log = Log.scope('player')
end

function PlayerRegistry:get(source)
    return self.bySource[tonumber(source)]
end

function PlayerRegistry:getSourceByIdentifier(identifier)
    return self.byIdentifier[identifier]
end

function PlayerRegistry:count()
    local total = 0
    for _ in pairs(self.bySource) do
        total = total + 1
    end
    return total
end

---@param fn fun(player: table)
function PlayerRegistry:each(fn)
    for _, player in pairs(self.bySource) do
        fn(player)
    end
end

--- Idempotente: chamar duas vezes para o mesmo source devolve o mesmo OnlinePlayer.
---@return boolean ok, string code, table|nil player
function PlayerRegistry:bind(source)
    source = tonumber(source)
    if (not source or source < 1) then
        return false, 'invalid_source'
    end

    if (self.bySource[source]) then
        return true, 'ok', self.bySource[source]
    end

    local identifier = Framework.identifier(source)
    if (not identifier) then
        return false, 'no_identifier'
    end

    local player = OnlinePlayer(source, identifier, Framework.displayName(source))
    self.bySource[source] = player
    self.byIdentifier[identifier] = source

    self.log:debug('bind src=%s id=%s', source, identifier)
    return true, 'ok', player
end

function PlayerRegistry:unbind(source)
    source = tonumber(source)
    local player = self.bySource[source]
    if (not player) then
        return
    end

    self.bySource[source] = nil
    -- mesma license conectada 2× (dev/multi-client): só limpa o índice se ainda aponta para este source.
    if (self.byIdentifier[player.identifier] == source) then
        self.byIdentifier[player.identifier] = nil
    end
end

playerRegistry = PlayerRegistry()
