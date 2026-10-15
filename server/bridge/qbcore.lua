--- Adapter QBCore (qb-core). Identifier = citizenid — POR PERSONAGEM.
--- Core via `exports['qb-core']:GetCoreObject()`; dinheiro pelos `Player.Functions.*` documentados.
--- Grupos de FrameworkConfig.groups = níveis de permissão do qb-core (god/admin/mod), ACE por baixo.
Framework.register('qbcore', function(lifecycle)
    local QBCore = exports['qb-core']:GetCoreObject()
    local ACCOUNTS = {
        [MONEY_ACCOUNT.CASH] = 'cash',
        [MONEY_ACCOUNT.BANK] = 'bank',
    }

    -- Disparados pelo próprio qb-core: PlayerLoaded recebe o Player, OnPlayerUnload o source.
    AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
        lifecycle.loaded(player.PlayerData.source)
    end)

    AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
        lifecycle.unloaded(src)
    end)

    local adapter = {}

    function adapter.identifier(src)
        local player = QBCore.Functions.GetPlayer(src)
        return player and player.PlayerData.citizenid
    end

    function adapter.displayName(src)
        local player = QBCore.Functions.GetPlayer(src)
        if (not player) then
            return nil
        end

        local charinfo = player.PlayerData.charinfo
        return ('%s %s'):format(charinfo.firstname, charinfo.lastname)
    end

    function adapter.hasGroup(src, groups)
        return QBCore.Functions.HasPermission(src, groups)
    end

    function adapter.getMoney(src, account)
        local player = QBCore.Functions.GetPlayer(src)
        if (not player) then
            return false, 'not_loaded'
        end
        return true, 'ok', player.PlayerData.money[ACCOUNTS[account]] or 0
    end

    function adapter.addMoney(src, account, amount, reason)
        local player = QBCore.Functions.GetPlayer(src)
        if (not player) then
            return false, 'not_loaded'
        end

        if (not player.Functions.AddMoney(ACCOUNTS[account], amount, reason)) then
            return false, 'failed'
        end
        return true, 'ok'
    end

    function adapter.removeMoney(src, account, amount, reason)
        local player = QBCore.Functions.GetPlayer(src)
        if (not player) then
            return false, 'not_loaded'
        end

        -- O qb-core aceita negativo fora de `DontAllowMinus` (até MinusLimit); o contrato do bridge não.
        local moneyType = ACCOUNTS[account]
        if ((player.PlayerData.money[moneyType] or 0) < amount) then
            return false, 'insufficient'
        end

        if (not player.Functions.RemoveMoney(moneyType, amount, reason)) then
            return false, 'failed'
        end
        return true, 'ok'
    end

    return adapter
end)
