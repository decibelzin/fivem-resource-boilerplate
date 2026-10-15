--- Cache dos jogadores em uso (RAM), preenchido SOB DEMANDA: a primeira vez que o script precisa de um
--- source, a ponte é chamada uma vez; depois é só memória. Começa vazio no arranque e no restart a
--- quente — ninguém é varrido, porque o custo da ponte do comprador é desconhecido. Sai do cache no
--- `playerDropped` e quando a ponte avisa troca de personagem. Único dono dos índices source/identifier.
PlayerRegistry = class()

function PlayerRegistry:__init()
    self.bySource = {}
    self.byIdentifier = {}
    self.log = Log.scope('player')
end

--- OnlinePlayer do source, resolvido pela ponte no primeiro uso. nil = sem personagem carregado.
---@return table|nil OnlinePlayer
function PlayerRegistry:get(source)
    source = tonumber(source)
    if (not source or source < 1) then
        return nil
    end

    local cached = self.bySource[source]
    if (cached) then
        return cached
    end

    local identifier = Framework.identifier(source)
    if (not identifier) then
        return nil
    end

    local player = OnlinePlayer(source, identifier, Framework.displayName(source))
    self.bySource[source] = player
    self.byIdentifier[identifier] = source

    self.log:debug('cache src=%s id=%s', source, identifier)
    return player
end

--- Só acha quem já está no cache (usou o script desde o arranque). Audiência por permissão não passa
--- por aqui: percorra `GetPlayers()` com `Framework.hasPermission`.
function PlayerRegistry:getSourceByIdentifier(identifier)
    return self.byIdentifier[identifier]
end

function PlayerRegistry:forget(source)
    source = tonumber(source)
    local player = self.bySource[source]
    if (not player) then
        return
    end

    self.bySource[source] = nil
    -- mesmo identifier conectado 2× (dev/multi-client): só limpa o índice se ainda aponta para este source.
    if (self.byIdentifier[player.identifier] == source) then
        self.byIdentifier[player.identifier] = nil
    end
end

playerRegistry = PlayerRegistry()
