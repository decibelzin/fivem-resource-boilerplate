--- Adapter vRP — variante CREATIVE (v5+: Passport, funções PascalCase). PONTO DE PARTIDA, não
--- plug-and-play: o vRP tem forks incompatíveis entre si (vRP 1/2, vRPex, creative v3…v7, edições
--- pagas) que mudam nome, argumento e retorno das mesmas funções, e nenhum tem doc oficial. Toda
--- chamada marcada [confirmar] segue o creative v5+ e NÃO foi verificada numa versão específica:
--- confira no `vrp/modules/*.lua` do SEU servidor antes de usar.
--- Identifier = Passport — POR PERSONAGEM.
Framework.register('vrp', function(lifecycle)
    -- Equivale a `'@vrp/lib/utils.lua'` no fxmanifest (que não tem include condicional): define o
    -- `module` usado para chegar ao Proxy. Só corre com o vRP escolhido.
    local utils = LoadResourceFile('vrp', 'lib/utils.lua')
    if (not utils) then
        Log.scope('framework'):error('vrp/lib/utils.lua não encontrado — o resource não fica pronto')
        return nil
    end

    load(utils, '@vrp/lib/utils.lua')()
    local vRP = module('vrp', 'lib/Proxy').getInterface('vRP')

    --- Dinheiro em mão é item de inventário no creative. [confirmar] 'dollar' ou 'dollars'.
    local CASH_ITEM = 'dollar'

    -- [confirmar] o creative dispara Connect(Passport, source) quando o personagem é escolhido.
    -- Sem evento de unload: troca de personagem passa por desconectar (playerDropped).
    AddEventHandler('Connect', function(_, src)
        lifecycle.loaded(src)
    end)

    local adapter = {}

    function adapter.identifier(src)
        local passport = vRP.Passport(src)
        return passport and tostring(passport)
    end

    function adapter.displayName(src)
        local passport = vRP.Passport(src)
        -- [confirmar] versões antigas não têm FullName: vRP.Identity(passport) → name/name2.
        return passport and vRP.FullName(passport)
    end

    function adapter.hasGroup(src, groups)
        local passport = vRP.Passport(src)
        if (not passport) then
            return false
        end

        for _, group in ipairs(groups) do
            -- [confirmar] (Passport, Group, Level?) — vRPex usa vRP.hasPermission(user_id, perm).
            if (vRP.HasGroup(passport, group)) then
                return true
            end
        end
        return false
    end

    function adapter.getMoney(src, account)
        local passport = vRP.Passport(src)
        if (not passport) then
            return false, 'not_loaded'
        end

        if (account == MONEY_ACCOUNT.BANK) then
            -- [confirmar] umas versões recebem o source, outras o Passport.
            return true, 'ok', vRP.GetBank(src) or 0
        end
        -- [confirmar]
        return true, 'ok', vRP.ItemAmount(passport, CASH_ITEM) or 0
    end

    -- O creative não recebe `reason`: auditoria fica com quem chama.
    function adapter.addMoney(src, account, amount)
        local passport = vRP.Passport(src)
        if (not passport) then
            return false, 'not_loaded'
        end

        -- [confirmar] GiveBank(Passport, Amount) · GenerateItem(Passport, Item, Amount)
        if (account == MONEY_ACCOUNT.BANK) then
            vRP.GiveBank(passport, amount)
        else
            vRP.GenerateItem(passport, CASH_ITEM, amount)
        end
        return true, 'ok'
    end

    function adapter.removeMoney(src, account, amount)
        local passport = vRP.Passport(src)
        if (not passport) then
            return false, 'not_loaded'
        end

        -- [confirmar] PaymentBank/TakeItem checam o saldo e devolvem false quando não chega.
        local paid
        if (account == MONEY_ACCOUNT.BANK) then
            paid = vRP.PaymentBank(passport, amount)
        else
            paid = vRP.TakeItem(passport, CASH_ITEM, amount)
        end

        if (not paid) then
            return false, 'insufficient'
        end
        return true, 'ok'
    end

    return adapter
end)
