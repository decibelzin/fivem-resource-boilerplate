--- Superfície de exports server → server (outros resources). Nada de regra de negócio aqui.
--- Contrato documentado em docs/api.md — export novo entra lá no mesmo commit.

exports('IsReady', function()
    return App.ready == true
end)

-- Reports ------------------------------------------------------------------------------

exports('GetOpenReports', function()
    return reportsService:listOpen()
end)

exports('CloseReport', function(id, actor)
    return reportsService:close(id, actor or ('resource:%s'):format(GetInvokingResource() or '?'))
end)
