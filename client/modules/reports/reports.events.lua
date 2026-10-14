--- Staff: report novo (o server só envia para quem tem a permissão).
RegisterNetEvent(EVENT.REPORT_CREATED, function(report)
    if (type(report) ~= 'table') then
        return
    end

    Notify(ReportsConfig.messages.staffNew:format(report.id, report.authorName, report.message))
end)

--- Autor: o report dele foi fechado.
RegisterNetEvent(EVENT.REPORT_CLOSED, function(report)
    if (type(report) ~= 'table') then
        return
    end

    Notify(ReportsConfig.messages.closed:format(report.id))
end)
