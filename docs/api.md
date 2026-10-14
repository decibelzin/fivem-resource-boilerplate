# api.md — superfície pública

> Fonte de verdade de exports, RPC, eventos e comandos. **Se não está aqui, não existe.**
> Mudou `server/api/*.lua`, `EVENT` ou um comando? Atualize este ficheiro no mesmo commit.

Retorno de tudo que pode falhar: **`ok:boolean, code:string, data?`**.

## Exports (server → server)

```lua
local ok, code, report = exports['<resource>']:CloseReport(12, 'resource:meu_script')
```

| Export | Args | Retorno |
|--------|------|---------|
| `IsReady()` | — | `boolean` |
| `GetOpenReports()` | — | `ReportPayload[]` (fila, mais antigos primeiro) |
| `CloseReport(id, actor?)` | `id: number`, `actor?: string` (default `resource:<invocador>`) | `ok, code, ReportPayload?` — `invalid_id` · `not_found` · `already_closed` |

## RPC (client → server)

```lua
CreateThread(function()
    local ok, code, report = RPC.await('reports.create', { message = 'texto' })
end)
```

| RPC | Args | Retorno | Códigos de erro |
|-----|------|---------|-----------------|
| `reports.create` | `{ message: string }` | `ok, code, ReportPayload?` | `message_too_short` · `message_too_long` · `cooldown` (`data.retryIn`) · `too_many_open` · `insert_failed` · `not_online` · `not_ready` |

Falhas de transporte chegam com `ok = nil`: `rpc_timeout` · `rpc_unknown_method` · `rpc_handler_error`.

## Eventos

| Evento | Direção | Audiência | Payload |
|--------|---------|-----------|---------|
| `EVENT.READY` (`<resource>:ready`) | server local | outros resources | — |
| `EVENT.REPORT_CREATED` (`<resource>:reports:created`) | server → client | unicast, quem tem `reports.manage` | `ReportPayload` |
| `EVENT.REPORT_CLOSED` (`<resource>:reports:closed`) | server → client | unicast, autor online | `ReportPayload` |

## Comandos

| Comando | Lado | Acesso |
|---------|------|--------|
| `/report <mensagem>` | client (→ RPC `reports.create`) | qualquer jogador |
| `/reports` | server | console + ACE `reports.manage` |
| `/closereport <id>` | server | console + ACE `reports.manage` |

Nomes configuráveis em `ReportsConfig.commands`.

## Tipos

```lua
---@class ReportPayload
---@field id number
---@field authorName string
---@field message string
---@field status 'open'|'closed'
---@field createdAt number unix
---@field closedAt number|nil unix
```
