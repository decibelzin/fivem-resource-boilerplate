--- Ponte RPC client → server. Toda chamada yielda — usar dentro de thread.
--- Retornos seguem o padrão do server: ok, code, data? (transporte falhou → nil, 'rpc_timeout').
ReportsApi = class()

---@param message string
function ReportsApi:create(message)
    return RPC.await('reports.create', { message = message })
end

reportsApi = ReportsApi()
