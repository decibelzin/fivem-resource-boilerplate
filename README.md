# fivem-resource-boilerplate

Boilerplate de resource FiveM em **Lua 5.4** pensado para ser escrito **com IA**: o padrão de código
está documentado de um jeito que um agente (Claude Code, Codex, Cursor) segue à risca — e o módulo de
exemplo mostra cada camada funcionando.

- **Server autoritativo** — client só pede; o server valida tudo e decide.
- **Módulos em camadas** — `schema` · `repository` · `entity` · `service` · `commands`/`events` · `api`.
- **`ok, code, data`** em tudo que pode falhar — sem `error()` para regra de negócio.
- **RPC com retorno** client ↔ server (`RPC.await`), sem callback hell.
- **Schema declarativo** — as tabelas nascem sozinhas no arranque (oxmysql).
- **Multi-framework** — standalone, QBox, QBCore, ESX e vRP (creative) com auto-detecção; só o
  bridge conhece a framework.

## Começar

```bash
gh repo create meu-script --template decibelzin/fivem-resource-boilerplate --private --clone
```

1. Coloque a pasta em `resources/[scripts]/meu-script`.
2. `server.cfg`:
   ```cfg
   ensure oxmysql
   # ensure da sua framework (qbx_core, qb-core, es_extended ou vrp) — sempre ANTES do script
   ensure meu-script

   setr meu-script_framework auto
   add_ace group.admin reports.manage allow
   ```
3. Abra o agente na pasta do resource e use um pedido de [`docs/prompts.md`](docs/prompts.md).

O módulo de exemplo `reports` já funciona: `/report <mensagem>` (jogador), `/reports` e
`/closereport <id>` (staff/console). Ele fica como referência até o primeiro módulo real existir.

## Estrutura

```text
fxmanifest.lua
shared/
  lib/class.lua · log.lua · rpc.lua · framework.lua (escolha da framework)
  constants.lua                 RESOURCE, EVENT
  config/framework.lua          convar, ordem do auto, grupos, MONEY_ACCOUNT
  config/reports.lua            tunáveis, textos e enums do módulo
server/
  lib/command.lua · db.lua · util.lua · framework.bridge.lua (contrato Framework.*)
  bridge/                       standalone · qbox · qbcore · esx · vrp (só a escolhida ativa)
  modules/player/               registry de jogadores online
  modules/reports/              schema · entity · repository · service · commands
  api/exports.lua · rpc.lua     superfície pública (fina)
  bootstrap.lua                 framework → schema → ready → bind dos online → EVENT.READY
client/
  lib/notify.lua                notify nativo da framework, fallback no chat
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

Não precisa editar código: a convar `<resource>_framework` escolhe o adapter (`auto` | `standalone` |
`qbox` | `qbcore` | `esx` | `vrp`). Em `auto`, ganha o primeiro resource started na ordem `qbx_core` >
`qb-core` > `es_extended` > `vrp`; nenhum → standalone. Use `setr` para o client (notify) seguir a mesma
escolha. A framework tem de subir **antes** do script no `server.cfg`; escolhida e parada, o script loga
o erro e não fica pronto.

- **Identifier por personagem** — citizenid (QBox/QBCore), identifier do ESX (`char1:…` com
  multichar), Passport (vRP); standalone segue com a license. Dados ficam por personagem, não por conta:
  dois personagens da mesma conta não partilham reports, cooldown, inventário. Trocar de framework (ou
  ligar/desligar multichar no ESX) muda as chaves — o dado antigo fica órfão.
- **Permissão** — ACE vale sempre; os grupos nativos que somam a ele ficam em
  [`shared/config/framework.lua`](shared/config/framework.lua) (`FrameworkConfig.groups`).
- **Dinheiro** — `Framework.getMoney/addMoney/removeMoney(src, MONEY_ACCOUNT.CASH|BANK, …)`, com
  `ok, code` (`insufficient`, `not_loaded`, `not_supported` no standalone…).
- **vRP** — os forks são incompatíveis entre si. [`server/bridge/vrp.lua`](server/bridge/vrp.lua)
  segue o creative v5+ e é ponto de partida: confira as chamadas `[confirmar]` no seu `vrp`.

Precisa de mais (item, job)? Acrescente no contrato de
[`server/lib/framework.bridge.lua`](server/lib/framework.bridge.lua) e nos 5 adapters de
[`server/bridge/`](server/bridge/). Nada fora deles chama a framework.

## Convars

| Convar | Valores | Default |
|--------|---------|---------|
| `<resource>_framework` (`setr`) | `auto` · `standalone` · `qbox` · `qbcore` · `esx` · `vrp` | `auto` |
| `<resource>_log_level` | `debug` · `info` · `warn` · `error` | `info` |
