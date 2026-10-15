# AGENTS.md — fivem-resource-boilerplate

> **Ponto de entrada único para qualquer agente** (Claude Code, Codex, Cursor) e qualquer dev.
> `CLAUDE.md` importa este ficheiro + `docs/patterns.md`. Se você está lendo isto, está no lugar certo.

## O que é

Boilerplate de resource FiveM em **Lua 5.4**, **server-autoritativo**. A raiz do repo **é** o resource:
clona-se para `resources/[scripts]/<nome>` e dá-se `ensure`. Traz as libs (class, log, RPC, schema,
comandos, bridge da framework) e um módulo de exemplo completo — `reports` — que é a **referência
canônica**: na dúvida sobre formato, copie o que ele faz.

| Caminho | O que é |
|---------|---------|
| `shared/lib/` | `class()`, `Log.scope`, `RPC` (client ↔ server com retorno), `ResolveFramework()` |
| `shared/constants.lua` | `RESOURCE` e `EVENT` (nomes de evento, prefixados pelo resource) |
| `shared/config/<modulo>.lua` | Tunáveis, textos e enums partilhados de cada módulo |
| `server/lib/` | `Schema` (DDL declarativo), `CreateCommand`, `Util`, `Framework` (contrato do bridge) |
| `server/bridge/` | Um adapter por framework (`standalone` · `qbox` · `qbcore` · `esx` · `vrp`) — só o escolhido ativa |
| `server/modules/<modulo>/` | Domínio em camadas: `schema` · `repository` · `entity` · `service` · `events` · `commands` |
| `server/api/` | Superfície pública: `exports.lua` (server → server) e `rpc.lua` (client → server) |
| `server/bootstrap.lua` | Framework → schema → `App.ready` → bind de quem já está online → `EVENT.READY` |
| `client/lib/` | Helpers client (`Notify` — notify nativo da framework, fallback no chat) |
| `client/modules/<modulo>/` | `*.api.lua` (wrapper RPC) · `*.events.lua` · `*.commands.lua` |
| `docs/` | Padrão (`patterns.md`), contrato (`api.md`), receitas (`playbooks/`), `prompts.md`, `decisions.md` |

## Fluxo de trabalho obrigatório (qualquer tarefa)

1. **Leia `docs/patterns.md`** — é o padrão de código. Não comece grepando às cegas.
2. Feature/módulo novo → **`docs/playbooks/new-module.md`**, copiando o formato de `server/modules/reports/`.
3. Antes de usar export, RPC ou evento, confira **`docs/api.md`**. Se não está lá, não existe.
4. **Valide**: revisão de fluxo (quem chama, o que retorna, quem recebe o evento). A sintaxe Lua
   valida-se **arrancando o servidor** (consola sem erro de parse). Se não arrancou, diga-o em vez de
   afirmar que validou.
5. **Atualize os docs no MESMO turno**: mudou export/RPC/evento/comando → `docs/api.md`; decisão de
   arquitetura → `docs/decisions.md`. Documente o código final, nunca tentativas revertidas.

## Padrão de código — resumo (detalhe em `docs/patterns.md`)

- Domínio = **`class()`** com métodos `:` e instância global lowerCamel no fim do ficheiro:
  `ReportsService = class()` → `reportsService = ReportsService()`.
- Ficheiros com **ponto**: `reports.service.lua`, `player.registry.lua` — nunca underscore.
- Tudo que pode falhar retorna **`ok:boolean, code:string, data?`** — códigos snake_case
  (`'cooldown'`, `'not_found'`). Nunca `error()` para fluxo de negócio.
- Condições entre parênteses (`if (not player) then`), early return, 4 espaços, `('%s'):format()`.
- Entidades expõem **camelCase**; snake_case da DB só entra via `:applyRow` no repository.
- SQL só no `*.repository.lua` do módulo dono. Tabelas criadas no arranque via `Schema.table(...)`.
- API pública só em `server/api/exports.lua` e `server/api/rpc.lua` — services nunca exportam direto.
- Server → client **sempre unicast** (`TriggerClientEvent(evt, src, ...)`). **Broadcast `-1` é proibido.**
- Payload do client é **não confiável**: valide tipo, tamanho, range e permissão no server.
- Sem `dependency` no fxmanifest e sem poll/`Wait` esperando outro resource: a ordem do `server.cfg` é o contrato.
- Framework (standalone/QBox/QBCore/ESX/vRP) só é conhecida pelo bridge (`server/lib/framework.bridge.lua`
  + `server/bridge/<nome>.lua`), escolhida pela convar `<resource>_framework`. `identifier` é **por personagem**.
- Simplicidade primeiro: helper só se reusado em ≥2 lugares; classe só onde há estado ou regras.

## Proibições absolutas

- `TriggerClientEvent(..., -1, ...)` — unicast para a audiência certa.
- SQL fora do módulo dono, ou em tabelas de outra framework/resource.
- Inventar export/RPC/evento que não está em `docs/api.md`.
- `RPC.await` fora de thread (top-level do ficheiro) — use `CreateThread` ou NUI callback.
- Instância de outro módulo referenciada no **top-level** do ficheiro (load order é alfabético).
- Texto de jogador ou número mágico hardcoded no service — vai para `shared/config/<modulo>.lua`.

## Definition of Done

- [ ] Código segue `docs/patterns.md` (class, nomes, retornos, camadas).
- [ ] Schema novo via `Schema.table/column/seed` no módulo dono, tabela prefixada com o resource.
- [ ] API nova exposta em `server/api/` e documentada em `docs/api.md`.
- [ ] Nenhum broadcast `-1`; payloads do client validados no server; handlers checam `App.ready`.
- [ ] Sintaxe Lua: validada arrancando o servidor — quem não arrancou **declara isso**.
- [ ] Docs atualizados no mesmo turno.
- [ ] Na resposta final: **Docs consultados** e **Docs atualizados** (ou "sem mudança de doc").

## Commits

Formato **`tipo(escopo): resumo`** — tipos: feat · fix · docs · chore · refactor · perf · test · style · build.
Um assunto por commit. Corpo (3–6 linhas) só quando o resumo não basta: o **porquê**, não o diff.
