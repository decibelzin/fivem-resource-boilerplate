--- Cooldown por chave (identifier, `src:ação`…) com expiração: chaves vencidas saem sozinhas, então o mapa
--- não cresce sem limite num servidor com dias de uptime e milhares de jogadores.
---   self.cooldowns = Cooldown()
---   local free, retryIn = self.cooldowns:take(player.identifier, Config.cooldownSeconds)
---   if (not free) then return false, 'cooldown', { retryIn = retryIn } end
---   -- ação falhou depois de marcar? self.cooldowns:release(player.identifier)
Cooldown = class()

local SWEEP_EVERY = 100 -- takes entre limpezas das chaves vencidas

function Cooldown:__init()
    self.readyAt = {}
    self.takes = 0
end

--- Marca `key` por `seconds` se estiver livre. Chame ANTES do primeiro await: pedidos do mesmo jogador
--- intercalam e passariam juntos pela checagem.
---@return boolean free, number|nil retryIn segundos que faltam quando ocupado
function Cooldown:take(key, seconds)
    local now = os.time()
    local readyAt = self.readyAt[key]
    if (readyAt and readyAt > now) then
        return false, readyAt - now
    end

    self.readyAt[key] = now + seconds
    self.takes = self.takes + 1
    if (self.takes % SWEEP_EVERY == 0) then
        for other, otherReadyAt in pairs(self.readyAt) do
            if (otherReadyAt <= now) then
                self.readyAt[other] = nil
            end
        end
    end
    return true
end

--- Desfaz o `take` (a ação falhou depois de marcar).
function Cooldown:release(key)
    self.readyAt[key] = nil
end
