--- Adapter QBox (qbx_core). Identifier = citizenid — POR PERSONAGEM.
--- Só exports documentados do qbx_core: GetPlayer, HasGroup, GetMoney, AddMoney, RemoveMoney.
--- Staff no QBox é ACE (`group.admin`), coberto pelo fallback do bridge; aqui os grupos de
--- FrameworkConfig.groups são job/gang (HasGroup aceita string[]).
Framework.register('qbox', function(lifecycle)
    local ACCOUNTS = {
        [MONEY_ACCOUNT.CASH] = 'cash',
        [MONEY_ACCOUNT.BANK] = 'bank',
    }

    -- Disparados pelo próprio qbx_core: PlayerLoaded recebe o Player, OnPlayerUnload o source.
    AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
        lifecycle.loaded(player.PlayerData.source)
    end)

    AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
        lifecycle.unloaded(src)
    end)

    local adapter = {}

    function adapter.identifier(src)
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.PlayerData.citizenid
    end

    function adapter.displayName(src)
        local player = exports.qbx_core:GetPlayer(src)
        if (not player) then
            return nil
        end

        local charinfo = player.PlayerData.charinfo
        return ('%s %s'):format(charinfo.firstname, charinfo.lastname)
    end

    function adapter.hasGroup(src, groups)
        return exports.qbx_core:HasGroup(src, groups) == true
    end

    function adapter.getMoney(src, account)
        -- false = sem Player para este source.
        local amount = exports.qbx_core:GetMoney(src, ACCOUNTS[account])
        if (not amount) then
            return false, 'not_loaded'
        end
        return true, 'ok', amount
    end

    function adapter.addMoney(src, account, amount, reason)
        if (not exports.qbx_core:AddMoney(src, ACCOUNTS[account], amount, reason)) then
            return false, 'failed'
        end
        return true, 'ok'
    end

    function adapter.removeMoney(src, account, amount, reason)
        local ok, code, balance = adapter.getMoney(src, account)
        if (not ok) then
            return false, code
        end

        -- O qbx_core aceita negativo nas contas fora de `dontAllowMinus`; o contrato do bridge não.
        if (balance < amount) then
            return false, 'insufficient'
        end

        if (not exports.qbx_core:RemoveMoney(src, ACCOUNTS[account], amount, reason)) then
            return false, 'failed'
        end
        return true, 'ok'
    end

    return adapter
end)
