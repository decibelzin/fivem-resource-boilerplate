--- /reports — lista os reports abertos (fila, mais antigos primeiro).
CreateCommand(ReportsConfig.commands.list, function(ctx)
    local reports = reportsService:listOpen()
    if (#reports == 0) then
        commandManager:reply(ctx, 'Nenhum report aberto.')
        return
    end

    for _, report in ipairs(reports) do
        commandManager:reply(ctx, ('#%s %s: %s'):format(report.id, report.authorName, report.message))
    end
end, { console = true, permission = ReportsConfig.permission })

--- /closereport <id>
CreateCommand(ReportsConfig.commands.close, function(ctx, args)
    local ok, code, report = reportsService:close(args[1], ctx.actor)
    if (not ok) then
        commandManager:reply(ctx, ('Falhou: %s'):format(code))
        return
    end

    commandManager:reply(ctx, ('Report #%s fechado.'):format(report.id))
end, { console = true, permission = ReportsConfig.permission })
