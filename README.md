# fivem-resource-boilerplate

Boilerplate de resource FiveM em **Lua 5.4** pensado para ser escrito **com IA**: o padrão de código
está documentado de um jeito que um agente (Claude Code, Codex, Cursor) segue à risca — e o módulo de
exemplo mostra cada camada funcionando.

- **Server autoritativo** — client só pede; o server valida tudo e decide.
- **Módulos em camadas** — `schema` · `repository` · `entity` · `service` · `commands`/`events` · `api`.
- **`ok, code, data`** em tudo que pode falhar — sem `error()` para regra de negócio.
- **RPC com retorno** client ↔ server (`RPC.await`), sem callback hell.
- **Schema declarativo** — as tabelas nascem sozinhas no arranque (oxmysql).
- **Framework-agnóstico** — standalone por padrão; vRP/QBox/ESX = editar só o bridge.

## Começar

```bash
gh repo create meu-script --template decibelzin/fivem-resource-boilerplate --private --clone
```

1. Coloque a pasta em `resources/[scripts]/meu-script`.
2. `server.cfg`:
   ```cfg
   ensure oxmysql
   ensure meu-script

   add_ace group.admin reports.manage allow
   ```
3. Abra o agente na pasta do resource e use um pedido de [`docs/prompts.md`](docs/prompts.md).

O módulo de exemplo `reports` já funciona: `/report <mensagem>` (jogador), `/reports` e
`/closereport <id>` (staff/console). Ele fica como referência até o primeiro módulo real existir.

## Estrutura

```text
fxmanifest.lua
shared/
  lib/class.lua · log.lua · rpc.lua
  constants.lua                 RESOURCE, EVENT
  config/reports.lua            tunáveis, textos e enums do módulo
server/
  lib/command.lua · db.lua · util.lua · framework.bridge.lua
  modules/player/               registry de jogadores online
  modules/reports/              schema · entity · repository · service · commands
  api/exports.lua · rpc.lua     superfície pública (fina)
  bootstrap.lua                 schema → ready → bind dos online → EVENT.READY
client/
  lib/notify.lua
  modules/reports/              api (RPC) · commands · events
docs/
  patterns.md · api.md · decisions.md · prompts.md · playbooks/new-module.md
AGENTS.md · CLAUDE.md           entrada para agentes
```

## Exemplo do padrão

```lua
ReportsService = class()

function ReportsService:close(id, actor)
    local report = reportsRepository:findById(id)
    if (not report) then
        return false, 'not_found'
    end

    if (not report:isOpen() or not reportsRepository:close(id, actor)) then
        return false, 'already_closed'
    end

    report:markClosed(actor)
    return true, 'ok', report:toPayload()
end

reportsService = ReportsService()
```

Regras completas: [`docs/patterns.md`](docs/patterns.md) · contrato: [`docs/api.md`](docs/api.md).

## Portar para a sua framework

Edite só [`server/lib/framework.bridge.lua`](server/lib/framework.bridge.lua) (`identifier`,
`displayName`, `hasPermission`, e o que mais precisar — dinheiro, item, job). Nada fora dele chama a
framework.

## Log

`set <resource>_log_level debug` no `server.cfg` (`debug | info | warn | error`, default `info`).
