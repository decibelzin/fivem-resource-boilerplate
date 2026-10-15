--- Adapter ESX Legacy (es_extended). Identifier = xPlayer.identifier — POR PERSONAGEM com
--- esx_multicharacter (`char1:<hash>`); sem multichar é um por conta (hash da license).
--- O ESX regista `group.<grupo>` como principal ACE do jogador: `add_ace group.admin <perm> allow` já
--- vale pelo fallback do bridge. Grupos de FrameworkConfig.groups comparam com xPlayer.getGroup().
Framework.register('esx', function(lifecycle)
    local ESX = exports.es_extended:getSharedObject()
    local ACCOUNTS = {
        [MONEY_ACCOUNT.CASH] = 'money',
        [MONEY_ACCOUNT.BANK] = 'bank',
    }

    -- Eventos server documentados: esx:playerLoaded(playerId, xPlayer, isNew) · esx:playerLogout(playerId).
    AddEventHandler('esx:playerLoaded', function(playerId)
        lifecycle.loaded(playerId)
    end)

    AddEventHandler('esx:playerLogout', function(playerId)
        lifecycle.unloaded(playerId)
    end)

    local adapter = {}

    function adapter.identifier(src)
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.identifier
    end

    function adapter.displayName(src)
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.getName()
    end

    function adapter.hasGroup(src, groups)
        local xPlayer = ESX.GetPlayerFromId(src)
        if (not xPlayer) then
            return false
        end

        local group = xPlayer.getGroup()
        for _, allowed in ipairs(groups) do
            if (group == allowed) then
                return true
            end
        end
        return false
    end

    function adapter.getMoney(src, account)
        local xPlayer = ESX.GetPlayerFromId(src)
        if (not xPlayer) then
            return false, 'not_loaded'
        end

        local data = xPlayer.getAccount(ACCOUNTS[account])
        return true, 'ok', data and data.money or 0
    end

    -- add/removeAccountMoney: versões antigas não retornam nada — só `false` explícito é recusa.
    function adapter.addMoney(src, account, amount, reason)
        local xPlayer = ESX.GetPlayerFromId(src)
        if (not xPlayer) then
            return false, 'not_loaded'
        end

        if (xPlayer.addAccountMoney(ACCOUNTS[account], amount, reason) == false) then
            return false, 'failed'
        end
        return true, 'ok'
    end

    function adapter.removeMoney(src, account, amount, reason)
        local xPlayer = ESX.GetPlayerFromId(src)
        if (not xPlayer) then
            return false, 'not_loaded'
        end

        local name = ACCOUNTS[account]
        local data = xPlayer.getAccount(name)
        if (not data or data.money < amount) then
            return false, 'insufficient'
        end

        if (xPlayer.removeAccountMoney(name, amount, reason) == false) then
            return false, 'failed'
        end
        return true, 'ok'
    end

    return adapter
end)
