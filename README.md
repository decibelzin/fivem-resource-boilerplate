# fivem-resource-boilerplate

Boilerplate de resource FiveM em **Lua 5.4** pensado para ser escrito **com IA**: traz só a estrutura
pronta e o padrão de código documentado de um jeito que um agente (Claude Code, Codex, Cursor) segue à
risca. Nenhum módulo de feature — o primeiro módulo é o do seu script.

- **Server autoritativo** — client só pede; o server valida tudo e decide.
- **Módulos em camadas** — `schema` · `repository` · `entity` · `service` · `commands`/`events` · `api`.
- **`ok, code, data`** em tudo que pode falhar — sem `error()` para regra de negócio.
- **RPC com retorno** client ↔ server (`RPC.await`), sem callback hell.
- **Schema declarativo** — as tabelas nascem sozinhas no arranque (oxmysql).
- **Qualquer framework** — o núcleo não conhece nenhuma; quem compra liga a dele em `bridge/`.

## Começar

```bash
gh repo create meu-script --template decibelzin/fivem-resource-boilerplate --private --clone
```

1. Coloque a pasta em `resources/[scripts]/meu-script`.
2. `server.cfg`: `ensure oxmysql` e a framework do servidor **antes** de `ensure meu-script`.
3. Abra o agente na pasta do resource e use um pedido de [`docs/prompts.md`](docs/prompts.md).

## Estrutura

```text
fxmanifest.lua
bridge/                         ABERTO no escrow — liga o script à framework do servidor
  bridge.server.lua             identifier do personagem, nome, permissão, personagem carregou/saiu
  bridge.client.lua             Notify
shared/
  lib/class.lua · log.lua · rpc.lua
  constants.lua                 RESOURCE, EVENT
  config/                       ABERTO no escrow — tunáveis e textos de cada módulo
server/
  lib/command.lua · db.lua · util.lua · framework.lua (núcleo da ponte)
  modules/player/               registry de jogadores online
  api/exports.lua · rpc.lua     superfície pública (fina)
  bootstrap.lua                 schema → ready → bind dos online → EVENT.READY
client/
  modules/                      um diretório por módulo
docs/
  patterns.md · api.md · decisions.md · prompts.md · playbooks/new-module.md
AGENTS.md · CLAUDE.md           entrada para agentes
```

Padrão: [`docs/patterns.md`](docs/patterns.md) · contrato: [`docs/api.md`](docs/api.md) · módulo de
exemplo completo: [`docs/playbooks/new-module.md`](docs/playbooks/new-module.md).

## Venda com escrow (Tebex)

Só `bridge/` e `shared/config/` ficam abertos (`escrow_ignore` no `fxmanifest.lua`). O comprador troca
o corpo das funções de `bridge/` pelo equivalente da framework dele; como vêm, funcionam em standalone
(license, nome do FiveM, ACE, chat). O identifier é **por personagem**: dado de jogo não se mistura entre
personagens da mesma conta. Função de ponte publicada não muda entre versões; feature nova entra como
função nova, com default.

## Log

`set <resource>_log_level debug` no `server.cfg` (`debug | info | warn | error`, default `info`).
