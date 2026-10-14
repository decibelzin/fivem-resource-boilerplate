--- /report <mensagem> — cria um report via RPC. O server valida tudo de novo.
RegisterCommand(ReportsConfig.commands.create, function(_, args)
    CreateThread(function()
        local ok, code, report = reportsApi:create(table.concat(args, ' '))
        local messages = ReportsConfig.messages

        if (not ok) then
            Notify(messages.errors[code] or messages.fallbackError:format(code))
            return
        end

        Notify(messages.sent:format(report.id))
    end)
end, false)
